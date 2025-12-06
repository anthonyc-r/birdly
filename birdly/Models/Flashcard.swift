//
//  Flashcard.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

struct Flashcard: Identifiable {
    let id: UUID
    let bird: Bird
    let birdImage: BirdImage
    let gameType: GameType
    
    init(bird: Bird, birdImage: BirdImage, gameType: GameType) {
        self.id = UUID() // Unique ID for each flashcard instance
        self.bird = bird
        self.birdImage = birdImage
        self.gameType = gameType
    }
    
    // Legacy initializer for backward compatibility
    init(bird: Bird, gameType: GameType) {
        self.id = UUID()
        self.bird = bird
        // Use first image or create a default one
        self.birdImage = bird.images.first ?? BirdImage(
            id: UUID(),
            variant: "default",
            imageSource: bird.imageSource
        )
        self.gameType = gameType
    }
}



