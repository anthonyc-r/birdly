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
    let progress: Double
    let imageSource: ImageSource?
    let imageName: String? // For backward compatibility
    let birds: [BirdData]
}

private struct DataModelData: Codable {
    let topics: [TopicData]
}

enum DataLoader {
    static func seedData(into context: ModelContext) throws {
        guard let url = Bundle.main.url(forResource: "birdlyData", withExtension: "json") else {
            throw DataLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let dataModel = try decoder.decode(DataModelData.self, from: data)
        
        // Convert to SwiftData models
        for topicData in dataModel.topics {
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
                progress: topicData.progress,
                imageSource: imageSource,
                birds: birds
            )
            
            context.insert(topic)
        }
        
        try context.save()
    }
    
    enum DataLoaderError: Error {
        case fileNotFound
        case decodingFailed
    }
}

