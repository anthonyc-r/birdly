//
//  TopicSession.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation
import Combine

/// Represents a learning session for a topic
/// Manages the sequence of games to be played
class TopicSession: ObservableObject {
    private let topic: Topic
    @Published var currentGameInfo: (bird: Bird, birdImage: BirdImage, gameType: GameType)?
    
    init(topic: Topic) {
        self.topic = topic
        advance()
    }
    
    /// Moves to the next game in the session
    func advance() {
        currentGameInfo = calculateNextGame()
    }
    
    /// Dynamically calculates the next game based on current topic state
    /// Handles bird selection, game type selection, and image variant selection
    private func calculateNextGame() -> (bird: Bird, birdImage: BirdImage, gameType: GameType)? {
        let topicProgress = topic.progress // 0.0 to 1.0
        
        // Separate birds into categories
        let introducedBirds = topic.birds.filter { $0.completionPercentage > 0 }
        let newBirds = topic.birds.filter { $0.completionPercentage == 0 }
        
        // Step 1: Determine if we should introduce a new bird
        let shouldIntroduceNew = shouldIntroduceNewBird(
            topicProgress: topicProgress,
            newBirds: newBirds,
            introducedBirds: introducedBirds
        )
        
        // Step 2: Select the bird
        guard let bird = selectBird(
            newBirds: newBirds,
            introducedBirds: introducedBirds,
            shouldIntroduceNew: shouldIntroduceNew
        ) else {
            return nil
        }
        
        // Step 3: Determine game type
        let birdMastery = bird.completionPercentage
        guard let gameType = selectGameType(birdMastery: birdMastery) else {
            return nil
        }
        
        // Step 4: Select bird image variant
        guard let image = selectBirdImage(bird: bird, gameType: gameType, birdMastery: birdMastery) else {
            return nil
        }
        
        return (bird: bird, birdImage: image, gameType: gameType)
    }
    
    /// Determines whether a new bird should be introduced
    /// New bird introductions happen gradually during mastery progression, all within first 50%
    private func shouldIntroduceNewBird(
        topicProgress: Double,
        newBirds: [Bird],
        introducedBirds: [Bird]
    ) -> Bool {
        guard !newBirds.isEmpty else {
            return false
        }
        
        guard topicProgress < 0.5 else {
            // Past 50%: no more new introductions
            return false
        }
        
        // Within first 50% of mastery: gradually introduce new birds
        // Calculate how many birds should be introduced by this progress point
        let totalBirds = topic.birds.count
        let targetIntroducedCount = Int(ceil(Double(totalBirds) * (topicProgress / 0.5)))
        let currentIntroducedCount = introducedBirds.count
        
        // If we haven't reached the target, introduce new birds
        if currentIntroducedCount < targetIntroducedCount {
            // Higher chance to introduce when we're further behind
            let progressRatio = topicProgress / 0.5 // 0.0 to 1.0 within first 50%
            let introduceProbability = 0.3 + (0.5 * (1.0 - progressRatio)) // 0.8 to 0.3
            return Double.random(in: 0...1) < introduceProbability
        } else {
            // We've reached the target, ensure all birds are introduced
            return currentIntroducedCount < totalBirds
        }
    }
    
    /// Selects which bird to show for the next game
    private func selectBird(
        newBirds: [Bird],
        introducedBirds: [Bird],
        shouldIntroduceNew: Bool
    ) -> Bird? {
        if shouldIntroduceNew && !newBirds.isEmpty {
            // Select from new birds (prioritize earlier ones in the list)
            return newBirds.sorted { $0.name < $1.name }.first
        } else if !introducedBirds.isEmpty {
            // Select from introduced birds, weighted by mastery (favor less mastered)
            return selectBirdByMastery(introducedBirds)
        } else if !newBirds.isEmpty {
            // Fallback: introduce a new bird
            return newBirds.first
        } else {
            return nil
        }
    }
    
    /// Selects a bird from introduced birds using weighted random selection
    /// Favors birds with lower mastery
    private func selectBirdByMastery(_ birds: [Bird]) -> Bird? {
        let sortedBirds = birds.sorted { $0.completionPercentage < $1.completionPercentage }
        let weights = sortedBirds.map { max(0.1, 100.0 - $0.completionPercentage) }
        let totalWeight = weights.reduce(0.0, +)
        let random = Double.random(in: 0..<totalWeight)
        
        var cumulativeWeight = 0.0
        return sortedBirds.first { bird in
            let index = sortedBirds.firstIndex(where: { $0.id == bird.id })!
            cumulativeWeight += weights[index]
            return random < cumulativeWeight
        } ?? sortedBirds.first
    }
    
    /// Selects a game type based on bird mastery
    /// Filters by mastery requirement and weights toward more difficult game types
    private func selectGameType(birdMastery: Double) -> GameType? {
        // Get all game types filtered by mastery requirement
        let validGameTypes = GameType.allCases.filter { gameType in
            gameType.isValidForMastery(birdMastery)
        }
        
        guard !validGameTypes.isEmpty else {
            return nil
        }
        
        // If only one type is valid, return it
        if validGameTypes.count == 1 {
            return validGameTypes.first!
        }
        
        // Exclude introduction if there are other valid game types (for practice games)
        let practiceTypes = validGameTypes.filter { $0 != .introduction }
        let typesToSelectFrom = practiceTypes.isEmpty ? validGameTypes : practiceTypes
        
        // Weight by masteryRequirement: higher requirement = significantly higher weight
        // Use squared relationship to make preference stronger for higher requirements
        let weights = typesToSelectFrom.map { gameType -> Double in
            let requirement = gameType.requiredMastery
            // Square the requirement ratio to strongly favor higher requirements
            // Introduction (0%) gets weight 1.0, 40% requirement gets weight ~1.16
            // This creates a stronger preference for difficult games
            return 1.0 + pow(requirement / 100.0, 2) * 2.0
        }
        
        return selectByWeightedRandom(typesToSelectFrom, weights: weights)
    }
    
    /// Selects a bird image variant based on game type and bird mastery
    private func selectBirdImage(bird: Bird, gameType: GameType, birdMastery: Double) -> BirdImage? {
        if gameType == .introduction {
            // Introduction always uses primary image
            return bird.perchedImage ?? bird.images.first
        }
        
        // For practice games, select based on bird mastery
        if birdMastery < 20.0 {
            // Below 20% mastery: only use primary image
            return bird.perchedImage ?? bird.images.first
        }
        
        // 20%+ mastery: can use variants with weighting
        // Higher mastery means different variants are more likely
        let availableImages = bird.images
        guard !availableImages.isEmpty else {
            return nil
        }
        
        if availableImages.count == 1 {
            return availableImages.first
        }
        
        // Weight images: primary gets base weight, variants get weight based on mastery
        let weights = availableImages.map { image -> Double in
            let isPrimary = image.variant == "perched"
            if isPrimary {
                // Primary image: base weight, decreases as mastery increases
                return max(0.5, 1.0 - (birdMastery / 200.0))
            } else {
                // Variant images: weight increases with mastery
                // At 20% mastery: weight = 0.2, at 100% mastery: weight = 1.0
                let masteryFactor = (birdMastery - 20.0) / 80.0 // 0.0 to 1.0
                return 0.2 + (0.8 * masteryFactor)
            }
        }
        
        return selectByWeightedRandom(availableImages, weights: weights)
    }
    
    /// Helper function to select an item using weighted random selection
    private func selectByWeightedRandom<T>(_ items: [T], weights: [Double]) -> T? {
        guard items.count == weights.count, !items.isEmpty else {
            return items.first
        }
        
        let totalWeight = weights.reduce(0.0, +)
        guard totalWeight > 0 else {
            return items.first
        }
        
        let random = Double.random(in: 0..<totalWeight)
        var cumulativeWeight = 0.0
        
        for (index, item) in items.enumerated() {
            cumulativeWeight += weights[index]
            if random < cumulativeWeight {
                return item
            }
        }
        
        return items.first
    }
}

