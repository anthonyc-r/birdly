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
    
    var isIdentified: Bool = false
    var hasBeenIntroduced: Bool = false
    var completionPercentage: Double = 0.0 // 0.0 to 100.0
    
    var topic: Topic?
    
    init(id: UUID, name: String, scientificName: String, description: String, imageSource: ImageSource, isIdentified: Bool = false, hasBeenIntroduced: Bool = false, completionPercentage: Double = 0.0) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.birdDescription = description
        self.imageSource = imageSource
        self.isIdentified = isIdentified
        self.hasBeenIntroduced = hasBeenIntroduced
        self.completionPercentage = completionPercentage
    }
    
    /// Returns all valid game types for this bird based on its mastery level
    func validGameTypes() -> [GameType] {
        var types: [GameType] = []
        
        // Introduction is only for birds that haven't been introduced
        if !hasBeenIntroduced && completionPercentage == 0 {
            types.append(.introduction)
        }
        
        // Multiple choice and word search require the bird to be introduced
        if hasBeenIntroduced || completionPercentage > 0 {
            types.append(.multipleChoice)
            types.append(.wordSearch)
        }
        
        return types
    }
    
    /// Selects a game type based on the bird's mastery level using weighted probability
    /// Higher mastery (50-100%) favors word search
    /// Lower mastery (0-50%) favors multiple choice
    func selectGameTypeForMastery() -> GameType? {
        let validTypes = validGameTypes()
        guard !validTypes.isEmpty else { return nil }
        
        // If only one type is valid, return it
        if validTypes.count == 1 {
            return validTypes.first
        }
        
        // Introduction takes priority if available
        if validTypes.contains(.introduction) {
            return .introduction
        }
        
        // For practice games, weight based on mastery
        // Clamp completion percentage to 0-100
        let mastery = max(0.0, min(100.0, completionPercentage))
        
        // Calculate weights based on mastery
        // At 0% mastery: 100% multiple choice, 0% word search
        // At 50% mastery: 50% multiple choice, 50% word search
        // At 100% mastery: 0% multiple choice, 100% word search
        let wordSearchWeight = mastery / 100.0
        let multipleChoiceWeight = 1.0 - wordSearchWeight
        
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

