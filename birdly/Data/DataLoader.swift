//
//  DataLoader.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation
import SwiftData

// Temporary structs for JSON decoding
private struct BirdData: Codable {
    let id: UUID
    let name: String
    let scientificName: String
    let description: String
    let imageSource: ImageSource?
    let imageName: String? // For backward compatibility
    let isIdentified: Bool?
    let hasBeenIntroduced: Bool?
    let completionPercentage: Double?
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
                let birdImageSource: ImageSource
                if let source = birdData.imageSource {
                    birdImageSource = source
                } else if let imageName = birdData.imageName {
                    birdImageSource = .asset(name: imageName)
                } else {
                    birdImageSource = .asset(name: "bird")
                }
                
                let bird = Bird(
                    id: birdData.id,
                    name: birdData.name,
                    scientificName: birdData.scientificName,
                    description: birdData.description,
                    imageSource: birdImageSource,
                    isIdentified: birdData.isIdentified ?? false,
                    hasBeenIntroduced: birdData.hasBeenIntroduced ?? false,
                    completionPercentage: birdData.completionPercentage ?? 0.0
                )
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

