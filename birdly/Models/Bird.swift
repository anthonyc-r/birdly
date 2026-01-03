//
//  Bird.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

@Model
final class Bird {
    @Attribute(.unique) var id: UUID
    var name: String
    var scientificName: String
    var birdDescription: String
    
    // Multiple images per bird, each with their own mastery
    @Relationship(deleteRule: .cascade, inverse: \BirdImage.bird)
    var images: [BirdImage] = []
    
    // Legacy support: computed property for backward compatibility
    var imageSource: ImageSource {
        get {
            // Return the perched image's source (primary), or first image, or default
            return perchedImage?.imageSource ?? images.first?.imageSource ?? .asset(name: "bird")
        }
        set {
            // If no images exist, create one with the provided source
            if images.isEmpty {
                let image = BirdImage(
                    id: UUID(),
                    variant: "perched",
                    imageSource: newValue
                )
                images.append(image)
            } else {
                // Update the perched image, or first image if no perched exists
                if let perched = perchedImage {
                    perched.imageSource = newValue
                } else {
                    images[0].imageSource = newValue
                }
            }
        }
    }
    
    /// Returns the perched image (primary image)
    var perchedImage: BirdImage? {
        return images.first { $0.variant == "perched" }
    }
    
    /// Returns alt images (non-perched) sorted by difficulty
    var altImages: [BirdImage] {
        return images.filter { $0.variant != "perched" }
    }
    
    var isIntroduced: Bool {
        return completionPercentage > 0
    }
    
    var isIdentified: Bool = false
    // Legacy: average completion across all images (read-only computed property)
    var completionPercentage: Double {
        guard !images.isEmpty else { return 0.0 }
        let total = images.reduce(0.0) { $0 + $1.completionPercentage }
        return total / Double(images.count)
    }
    
    var topics: [Topic] = []
    
    // Backward compatibility: returns first topic (if any)
    var topic: Topic? {
        return topics.first
    }
    
    init(id: UUID, name: String, scientificName: String, description: String, images: [BirdImage] = [], isIdentified: Bool = false) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.birdDescription = description
        self.images = images
        self.isIdentified = isIdentified
    }
    
    // Legacy initializer for backward compatibility
    convenience init(id: UUID, name: String, scientificName: String, description: String, imageSource: ImageSource, isIdentified: Bool = false, completionPercentage: Double = 0.0) {
        let image = BirdImage(
            id: UUID(),
            variant: "default",
            imageSource: imageSource,
            completionPercentage: completionPercentage
        )
        self.init(id: id, name: name, scientificName: scientificName, description: description, images: [image], isIdentified: isIdentified)
    }
    
    /// Returns all valid game types for this bird based on its mastery level
    func validGameTypes() -> [GameType] {
        return GameType.allCases.filter { gameType in
            gameType.isValidForMastery(completionPercentage)
        }
    }
    
}

