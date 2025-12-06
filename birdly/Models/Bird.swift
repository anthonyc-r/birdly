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
    
    var isIdentified: Bool = false
    // Legacy: average completion across all images (read-only computed property)
    var completionPercentage: Double {
        guard !images.isEmpty else { return 0.0 }
        let total = images.reduce(0.0) { $0 + $1.completionPercentage }
        return total / Double(images.count)
    }
    
    var topic: Topic?
    
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
        var types: [GameType] = []
        
        // Introduction is only for birds that haven't been introduced (mastery == 0)
        if completionPercentage == 0 {
            types.append(.introduction)
        }
        
        // Multiple choice and word search require the bird to be introduced (mastery > 0)
        if completionPercentage > 0 {
            types.append(.multipleChoice)
            types.append(.wordSearch)
        }
        
        return types
    }
    
    /// Selects an image variant and game type based on mastery levels
    /// 
    /// Image Selection Strategy:
    /// - Perched image is always primary and used first
    /// - Introduction always uses perched image
    /// - Practice games use perched until it reaches 80% mastery
    /// - Alt images (flight_side, flight_underbelly) are introduced as difficulty increases
    /// - Alt images only appear once perched has at least 20% mastery
    /// 
    /// Returns (image, gameType) tuple
    func selectImageAndGameType() -> (BirdImage, GameType)? {
        // Introduction always uses perched image (primary)
        if completionPercentage == 0 {
            if let perched = perchedImage {
                return (perched, .introduction)
            }
            // Fallback to first image if no perched exists
            if let firstImage = images.first {
                return (firstImage, .introduction)
            }
        }
        
        // For practice games, prioritize perched image until it's mastered
        // Then introduce alt images as difficulty increases
        let perched = perchedImage
        let alts = altImages
        
        // If perched exists and hasn't been mastered (or is at low mastery), use it
        if let perched = perched, perched.completionPercentage < 80.0 {
            // Use perched for easier games when mastery is low
            if let gameType = perched.selectGameTypeForMastery(birdMastery: completionPercentage) {
                return (perched, gameType)
            }
        }
        
        // Once perched is well-mastered (80%+), start introducing alt images
        // Select from available alt images based on their mastery
        let availableAlts = alts.filter { image in
            // Only include alt images if bird has been introduced
            // And if perched has some mastery (at least 20%)
            if completionPercentage == 0 {
                return false
            }
            if let perched = perched, perched.completionPercentage < 20.0 {
                return false
            }
            return true
        }
        
        // If we have alt images available, select one based on mastery
        if !availableAlts.isEmpty {
            // Sort alt images by mastery (ascending) to prioritize less mastered ones
            let sortedAlts = availableAlts.sorted { $0.completionPercentage < $1.completionPercentage }
            
            // Use weighted random selection favoring less mastered alt images
            let weights = sortedAlts.map { image in
                // Higher weight for lower mastery (inverse relationship)
                max(0.1, 100.0 - image.completionPercentage)
            }
            let totalWeight = weights.reduce(0.0, +)
            let random = Double.random(in: 0..<totalWeight)
            
            var selectedImage: BirdImage?
            var cumulativeWeight = 0.0
            for (index, image) in sortedAlts.enumerated() {
                cumulativeWeight += weights[index]
                if random < cumulativeWeight {
                    selectedImage = image
                    break
                }
            }
            
            if let altImage = selectedImage ?? sortedAlts.first {
                if let gameType = altImage.selectGameTypeForMastery(birdMastery: completionPercentage) {
                    return (altImage, gameType)
                }
            }
        }
        
        // Fallback to perched if available
        if let perched = perched {
            if let gameType = perched.selectGameTypeForMastery(birdMastery: completionPercentage) {
                return (perched, gameType)
            }
        }
        
        // Final fallback to first available image
        if let firstImage = images.first {
            if let gameType = firstImage.selectGameTypeForMastery(birdMastery: completionPercentage) {
                return (firstImage, gameType)
            }
        }
        
        return nil
    }
    
    /// Legacy method for backward compatibility
    /// Selects a game type based on the bird's average mastery level using weighted probability
    func selectGameTypeForMastery() -> GameType? {
        if let (_, gameType) = selectImageAndGameType() {
            return gameType
        }
        return nil
    }
}

