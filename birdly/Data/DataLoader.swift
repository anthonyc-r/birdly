//
//  DataLoader.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation
import SwiftData

// Temporary structs for JSON decoding
private struct BirdImageData: Codable {
    let id: UUID
    let variant: String
    let imageSource: ImageSource?
    let imageName: String? // For backward compatibility
    let completionPercentage: Double?
}

private struct BirdData: Codable {
    let id: UUID
    let name: String
    let scientificName: String
    let description: String
    let images: [BirdImageData]? // New: multiple images per bird
    let imageSource: ImageSource? // Legacy: backward compatibility
    let imageName: String? // Legacy: backward compatibility
    let isIdentified: Bool?
    let completionPercentage: Double? // Legacy: backward compatibility
}

private struct TopicData: Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let progress: Double? // Legacy field, no longer used (progress is now computed)
    let imageSource: ImageSource?
    let imageName: String? // For backward compatibility
    let birds: [BirdData]
}

private struct DataModelData: Codable {
    let topics: [TopicData]
}

enum DataLoader {
    /// Finds all topic JSON files in the bundle (files with .topic.json extension)
    private static func findTopicFiles() -> [URL] {
        guard let bundlePath = Bundle.main.resourcePath else { return [] }
        let dataPath = (bundlePath as NSString).appendingPathComponent("Data")
        
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dataPath) else { return [] }
        
        return files
            .filter { $0.hasSuffix(".topic.json") }
            .compactMap { fileName in
                let baseName = fileName.replacingOccurrences(of: ".topic.json", with: "")
                return Bundle.main.url(forResource: baseName, withExtension: "topic.json", subdirectory: "Data")
            }
    }
    
    /// Loads a single topic from a JSON file
    private static func loadTopic(from url: URL) throws -> TopicData {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(TopicData.self, from: data)
    }
    
    /// Seeds initial data if the database is empty
    static func seedData(into context: ModelContext) throws {
        // Try new format: load from individual topic files
        let topicFiles = findTopicFiles()
        
        if !topicFiles.isEmpty {
            // New format: load from separate topic files
            for topicFile in topicFiles {
                let topicData = try loadTopic(from: topicFile)
                try processTopic(topicData, into: context, isSeeding: true)
            }
        } else {
            // Fallback to old format: load from birdlyData.json
            guard let url = Bundle.main.url(forResource: "birdlyData", withExtension: "json") else {
                throw DataLoaderError.fileNotFound
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dataModel = try decoder.decode(DataModelData.self, from: data)
            
            // Convert to SwiftData models
            for topicData in dataModel.topics {
                try processTopic(topicData, into: context, isSeeding: true)
            }
        }
        
        try context.save()
    }
    
    /// Processes a single topic (used by both seedData and updateData)
    private static func processTopic(_ topicData: TopicData, into context: ModelContext, isSeeding: Bool) throws {
        let imageSource: ImageSource
        if let source = topicData.imageSource {
            imageSource = source
        } else if let imageName = topicData.imageName {
            imageSource = .asset(name: imageName)
        } else {
            imageSource = .asset(name: "bird")
        }
        
        let birds = topicData.birds.map { birdData -> Bird in
            // Create bird images from the images array, or fall back to legacy single image
            let birdImages: [BirdImage]
            if let imagesData = birdData.images, !imagesData.isEmpty {
                // New format: multiple images
                // Map and sort to ensure perched is always first
                let mappedImages = imagesData.map { imageData -> BirdImage in
                    let imageSource: ImageSource
                    if let source = imageData.imageSource {
                        imageSource = source
                    } else if let imageName = imageData.imageName {
                        imageSource = .asset(name: imageName)
                    } else {
                        imageSource = .asset(name: "bird")
                    }
                    
                    return BirdImage(
                        id: imageData.id,
                        variant: imageData.variant,
                        imageSource: imageSource,
                        completionPercentage: imageData.completionPercentage ?? 0.0
                    )
                }
                // Sort to ensure perched is always first (primary image)
                birdImages = mappedImages.sorted { image1, image2 in
                    if image1.variant == "perched" { return true }
                    if image2.variant == "perched" { return false }
                    return false // Keep original order for non-perched images
                }
            } else {
                // Legacy format: single image
                let birdImageSource: ImageSource
                if let source = birdData.imageSource {
                    birdImageSource = source
                } else if let imageName = birdData.imageName {
                    birdImageSource = .asset(name: imageName)
                } else {
                    birdImageSource = .asset(name: "bird")
                }
                
                let image = BirdImage(
                    id: UUID(),
                    variant: "default",
                    imageSource: birdImageSource,
                    completionPercentage: birdData.completionPercentage ?? 0.0
                )
                birdImages = [image]
            }
            
            let bird = Bird(
                id: birdData.id,
                name: birdData.name,
                scientificName: birdData.scientificName,
                description: birdData.description,
                images: birdImages,
                isIdentified: birdData.isIdentified ?? false
            )
            
            // Link images to bird
            for image in birdImages {
                image.bird = bird
            }
            
            return bird
        }
        
        let topic = Topic(
            id: topicData.id,
            title: topicData.title,
            subtitle: topicData.subtitle,
            imageSource: imageSource,
            birds: birds
        )
        
        context.insert(topic)
    }
    
    /// Updates the data store based on the latest JSON files, preserving user progress
    /// - Adds new topics and birds
    /// - Updates existing topics and birds metadata
    /// - Preserves completion percentages and user progress
    static func updateData(into context: ModelContext) throws {
        // Fetch existing data
        let descriptor = FetchDescriptor<Topic>()
        let existingTopics = try context.fetch(descriptor)
        let existingTopicsById = Dictionary(uniqueKeysWithValues: existingTopics.map { ($0.id, $0) })
        
        // Try new format: load from individual topic files
        let topicFiles = findTopicFiles()
        
        if !topicFiles.isEmpty {
            // New format: load from separate topic files
            for topicFile in topicFiles {
                let topicData = try loadTopic(from: topicFile)
                try updateTopic(topicData, existingTopicsById: existingTopicsById, into: context)
            }
        } else {
            // Fallback to old format: load from birdlyData.json
            guard let url = Bundle.main.url(forResource: "birdlyData", withExtension: "json") else {
                throw DataLoaderError.fileNotFound
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dataModel = try decoder.decode(DataModelData.self, from: data)
            
            // Process each topic from JSON
            for topicData in dataModel.topics {
                try updateTopic(topicData, existingTopicsById: existingTopicsById, into: context)
            }
        }
        
        try context.save()
    }
    
    /// Updates a single topic (used by updateData)
    private static func updateTopic(_ topicData: TopicData, existingTopicsById: [UUID: Topic], into context: ModelContext) throws {
        // Find or create topic
        let topic: Topic
        if let existingTopic = existingTopicsById[topicData.id] {
            topic = existingTopic
            // Update topic metadata
            topic.title = topicData.title
            topic.subtitle = topicData.subtitle
            
            // Update image source
            let imageSource: ImageSource
            if let source = topicData.imageSource {
                imageSource = source
            } else if let imageName = topicData.imageName {
                imageSource = .asset(name: imageName)
            } else {
                imageSource = .asset(name: "bird")
            }
            topic.imageSource = imageSource
        } else {
            // Create new topic
            let imageSource: ImageSource
            if let source = topicData.imageSource {
                imageSource = source
            } else if let imageName = topicData.imageName {
                imageSource = .asset(name: imageName)
            } else {
                imageSource = .asset(name: "bird")
            }
            
            topic = Topic(
                id: topicData.id,
                title: topicData.title,
                subtitle: topicData.subtitle,
                imageSource: imageSource,
                birds: []
            )
            context.insert(topic)
        }
        
        // Process birds for this topic
        // Fetch all birds to check if they exist elsewhere
        let birdDescriptor = FetchDescriptor<Bird>()
        let allBirds = try context.fetch(birdDescriptor)
        let allBirdsById = Dictionary(uniqueKeysWithValues: allBirds.map { ($0.id, $0) })
        let existingBirdsInTopicIds = Set(topic.birds.map { $0.id })
        
        for birdData in topicData.birds {
            // Find or create bird
            let bird: Bird
            if let existingBird = allBirdsById[birdData.id] {
                bird = existingBird
                // Update bird metadata but preserve progress
                bird.name = birdData.name
                bird.scientificName = birdData.scientificName
                bird.birdDescription = birdData.description
                // Preserve isIdentified state (don't overwrite user progress)
                
                // Ensure bird is linked to this topic (both directions)
                if !existingBirdsInTopicIds.contains(birdData.id) {
                    // Also explicitly add to topic's birds array to ensure relationship
                    if !topic.birds.contains(where: { $0.id == bird.id }) {
                        topic.birds.append(bird)
                    }
                }
            } else {
                // Create new bird
                bird = Bird(
                    id: birdData.id,
                    name: birdData.name,
                    scientificName: birdData.scientificName,
                    description: birdData.description,
                    images: [],
                    isIdentified: birdData.isIdentified ?? false
                )
                // Set relationship both ways
                bird.topic = topic
                topic.birds.append(bird)
                context.insert(bird)
            }
            
            // Process images for this bird
            let existingImagesById = Dictionary(uniqueKeysWithValues: bird.images.map { ($0.id, $0) })
            
            if let imagesData = birdData.images, !imagesData.isEmpty {
                // New format: multiple images
                for imageData in imagesData {
                    if let existingImage = existingImagesById[imageData.id] {
                        // Update image source but preserve completion percentage
                        let imageSource: ImageSource
                        if let source = imageData.imageSource {
                            imageSource = source
                        } else if let imageName = imageData.imageName {
                            imageSource = .asset(name: imageName)
                        } else {
                            imageSource = .asset(name: "bird")
                        }
                        existingImage.imageSource = imageSource
                        existingImage.variant = imageData.variant
                        // Preserve completionPercentage - don't overwrite user progress
                    } else {
                        // Create new image
                        let imageSource: ImageSource
                        if let source = imageData.imageSource {
                            imageSource = source
                        } else if let imageName = imageData.imageName {
                            imageSource = .asset(name: imageName)
                        } else {
                            imageSource = .asset(name: "bird")
                        }
                        
                        let newImage = BirdImage(
                            id: imageData.id,
                            variant: imageData.variant,
                            imageSource: imageSource,
                            completionPercentage: imageData.completionPercentage ?? 0.0
                        )
                        newImage.bird = bird
                        context.insert(newImage)
                    }
                }
            } else {
                // Legacy format: single image - only create if no images exist
                if bird.images.isEmpty {
                    let birdImageSource: ImageSource
                    if let source = birdData.imageSource {
                        birdImageSource = source
                    } else if let imageName = birdData.imageName {
                        birdImageSource = .asset(name: imageName)
                    } else {
                        birdImageSource = .asset(name: "bird")
                    }
                    
                    let image = BirdImage(
                        id: UUID(),
                        variant: "default",
                        imageSource: birdImageSource,
                        completionPercentage: birdData.completionPercentage ?? 0.0
                    )
                    image.bird = bird
                    context.insert(image)
                }
            }
        }
    }
    
    enum DataLoaderError: Error {
        case fileNotFound
        case decodingFailed
    }
}

