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
    private func calculateNextGame() -> (bird: Bird, birdImage: BirdImage, gameType: GameType)? {
        // Count how many birds have been introduced (completion > 0)
        let introducedCount = topic.birds.filter { $0.completionPercentage > 0 }.count
        let canPlayMultipleChoice = introducedCount >= 2
        
        // Separate birds into categories
        let introducedBirdsList = topic.birds.filter { $0.completionPercentage > 0 }
        let newBirds = topic.birds.filter { $0.completionPercentage == 0 }
        
        // Decide whether to introduce new birds or practice existing ones
        // Prioritize introducing new birds if we have few introduced
        let shouldIntroduceNew: Bool
        if introducedCount == 0 {
            // First time: always introduce
            shouldIntroduceNew = !newBirds.isEmpty
        } else if introducedCount < 4 {
            // Early stage: introduce new birds more often (70% chance)
            shouldIntroduceNew = !newBirds.isEmpty && Double.random(in: 0...1) < 0.7
        } else {
            // Later stage: introduce new birds less often (30% chance)
            shouldIntroduceNew = !newBirds.isEmpty && Double.random(in: 0...1) < 0.3
        }
        
        // Try to introduce a new bird
        if shouldIntroduceNew && !newBirds.isEmpty {
            // Determine how many new birds we should introduce in this session
            let newBirdsToIntroduce: Int
            if introducedCount == 0 {
                // First time: introduce up to 2 birds
                newBirdsToIntroduce = min(2, newBirds.count)
            } else if introducedCount < 4 {
                // Early stage: introduce 1-2 new birds
                newBirdsToIntroduce = min(2, newBirds.count)
            } else {
                // Later stage: introduce 1 new bird at a time
                newBirdsToIntroduce = min(1, newBirds.count)
            }
            
            // Select a new bird to introduce (prioritize first ones)
            let birdsToChooseFrom = Array(newBirds.prefix(newBirdsToIntroduce))
            if let bird = birdsToChooseFrom.randomElement() {
                // Introduction always uses the perched image (primary)
                if let perchedImage = bird.perchedImage ?? bird.images.first {
                    return (bird: bird, birdImage: perchedImage, gameType: .introduction)
                }
            }
        }
        
        // Practice with introduced birds
        if canPlayMultipleChoice && !introducedBirdsList.isEmpty {
            // Select a bird for practice, weighted by mastery (favor less mastered birds)
            let sortedBirds = introducedBirdsList.sorted { $0.completionPercentage < $1.completionPercentage }
            
            // Use weighted random selection favoring less mastered birds
            let weights = sortedBirds.map { bird in
                // Higher weight for lower mastery (inverse relationship)
                max(0.1, 100.0 - bird.completionPercentage)
            }
            let totalWeight = weights.reduce(0.0, +)
            let random = Double.random(in: 0..<totalWeight)
            
            var selectedBird: Bird?
            var cumulativeWeight = 0.0
            for (index, bird) in sortedBirds.enumerated() {
                cumulativeWeight += weights[index]
                if random < cumulativeWeight {
                    selectedBird = bird
                    break
                }
            }
            
            if let bird = selectedBird ?? sortedBirds.first {
                // Use the bird's logic to select image and game type
                if let (image, gameType) = bird.selectImageAndGameType() {
                    // Skip introduction games for practice (they should already be introduced)
                    if gameType != .introduction {
                        return (bird: bird, birdImage: image, gameType: gameType)
                    }
                }
            }
        }
        
        // Fallback: try to introduce a new bird if we have any
        if !newBirds.isEmpty {
            if let bird = newBirds.first,
               let perchedImage = bird.perchedImage ?? bird.images.first {
                return (bird: bird, birdImage: perchedImage, gameType: .introduction)
            }
        }
        
        // No games available
        return nil
    }
}

