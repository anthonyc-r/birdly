//
//  BirdImage.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

@Model
final class BirdImage {
    @Attribute(.unique) var id: UUID
    var variant: String // e.g., "perched", "flight_side", "flight_underbelly"
    
    // Store ImageSource as JSON data for SwiftData compatibility
    private var imageSourceData: Data?
    
    var imageSource: ImageSource {
        get {
            guard let data = imageSourceData,
                  let decoded = try? JSONDecoder().decode(ImageSource.self, from: data) else {
                return .asset(name: "bird")
            }
            return decoded
        }
        set {
            imageSourceData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var completionPercentage: Double = 0.0 // 0.0 to 100.0
    
    var bird: Bird?
    
    init(id: UUID, variant: String, imageSource: ImageSource, completionPercentage: Double = 0.0) {
        self.id = id
        self.variant = variant
        self.imageSource = imageSource
        self.completionPercentage = completionPercentage
    }
    
    /// Returns all valid game types for this image based on its mastery level
    func validGameTypes(birdMastery: Double) -> [GameType] {
        var types: [GameType] = []
        
        // Introduction is only for birds that haven't been introduced (once per bird, not per image)
        // But we don't show introduction for individual images - that's handled at bird level
        
        // Multiple choice and word search require the bird to be introduced (mastery > 0)
        if birdMastery > 0 {
            types.append(.multipleChoice)
            types.append(.wordSearch)
        }
        
        return types
    }
    
    /// Selects a game type based on the image's mastery level using weighted probability
    /// Higher mastery (50-100%) favors word search
    /// Lower mastery (0-50%) favors multiple choice
    func selectGameTypeForMastery(birdMastery: Double) -> GameType? {
        let validTypes = validGameTypes(birdMastery: birdMastery)
        guard !validTypes.isEmpty else { return nil }
        
        // If only one type is valid, return it
        if validTypes.count == 1 {
            return validTypes.first
        }
        
        // For practice games, weight based on mastery
        // Clamp completion percentage to 0-100
        let mastery = max(0.0, min(100.0, completionPercentage))
        
        // Calculate weights based on mastery
        // At 0% mastery: 100% multiple choice, 0% word search
        // At 50% mastery: 50% multiple choice, 50% word search
        // At 100% mastery: 0% multiple choice, 100% word search
        let wordSearchWeight = mastery / 100.0
        
        // Generate random value between 0 and 1
        let random = Double.random(in: 0...1)
        
        // Select based on weighted probability
        if validTypes.contains(.wordSearch) && random < wordSearchWeight {
            return .wordSearch
        } else if validTypes.contains(.multipleChoice) {
            return .multipleChoice
        } else if validTypes.contains(.wordSearch) {
            return .wordSearch
        }
        
        return validTypes.first
    }
}

