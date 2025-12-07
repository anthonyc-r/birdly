//
//  GameType.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

enum GameType: CaseIterable {
    case introduction
    case multipleChoice
    case wordSearch
    case letterSelection
    case trueFalse
    
    /// Difficulty rating from 0.0 (easiest) to 1.0 (hardest)
    /// Used to determine mastery gain amounts
    nonisolated var difficulty: Double {
        switch self {
        case .introduction:
            return 0.2 // Easiest, lower rewards
        case .multipleChoice, .trueFalse:
            return 0.4 // Medium difficulty
        case .letterSelection:
            return 0.5 // Medium-high difficulty
        case .wordSearch:
            return 0.7 // Hardest, highest rewards
        }
    }
    
    /// Returns the mastery threshold for this game type (0-100 range)
    nonisolated var requiredMastery: Double {
        switch self {
        case .multipleChoice, .trueFalse:
            return 0.01 // Non-zero to ensure it's always available post-introduction
        case .letterSelection:
            return 40.0
        case .wordSearch:
            return 40.0
        default:
            return 0.0
        }
    }
    
    /// Checks if the given mastery level is valid for this game type
    /// Mastery should be in 0-100 range
    nonisolated func isValidForMastery(_ mastery: Double) -> Bool {
        return mastery >= requiredMastery
    }
    
    /// Selects a game type from valid types based on mastery level
    /// Higher mastery makes games with higher requirements more likely
    /// Introduction is excluded if there are other valid game types
    /// Mastery should be in 0-100 range
    static func selectFromValidTypes(_ validTypes: [GameType], mastery: Double) -> GameType? {
        guard !validTypes.isEmpty else { return nil }
        
        // If only one type is valid, return it
        if validTypes.count == 1 {
            return validTypes.first
        }
        
        // Exclude introduction if there are other valid game types
        let practiceTypes = validTypes.filter { $0 != .introduction }
        let typesToSelectFrom = practiceTypes.isEmpty ? validTypes : practiceTypes
        
        guard !typesToSelectFrom.isEmpty else { return validTypes.first }
        
        // Calculate weights: games with higher required mastery get more weight as mastery increases
        // Weight increases as mastery exceeds the requirement
        // At mastery = required, weight is minimal (but > 0)
        // As mastery approaches 100, games with higher requirements get proportionally more weight
        let weights = typesToSelectFrom.map { gameType -> Double in
            let required = gameType.requiredMastery
            if mastery < required {
                return 0.0 // Shouldn't happen since we filtered, but safety check
            }
            if required >= 100.0 {
                return 1.0 // If required is 100%, always weight as 1.0
            }
            // Calculate how far above the requirement we are
            // Normalize: (mastery - required) / (100.0 - required)
            // At mastery = required, weight = 0 (but we'll add a base weight)
            // At mastery = 100, weight = 1.0
            let excess = mastery - required
            let range = 100.0 - required
            let normalized = range > 0 ? excess / range : 0.0
            // Add a base weight so games just meeting requirements still have some chance
            // Square the normalized value to make preference stronger for higher mastery
            let baseWeight = 0.1 // Minimum weight
            let scaledWeight = normalized * normalized // Stronger preference as mastery increases
            return baseWeight + scaledWeight * 0.9 // Scale to 0.1-1.0 range
        }
        
        // If all weights are 0 (shouldn't happen), fall back to equal weights
        let totalWeight = weights.reduce(0.0, +)
        guard totalWeight > 0 else {
            return typesToSelectFrom.randomElement()
        }
        
        // Select based on weighted probability
        let random = Double.random(in: 0..<totalWeight)
        var cumulativeWeight = 0.0
        for (index, gameType) in typesToSelectFrom.enumerated() {
            cumulativeWeight += weights[index]
            if random < cumulativeWeight {
                return gameType
            }
        }
        
        // Fallback
        return typesToSelectFrom.first
    }
}


