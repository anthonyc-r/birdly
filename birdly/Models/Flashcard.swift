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
    let gameType: GameType
    
    init(bird: Bird, gameType: GameType) {
        self.id = bird.id
        self.bird = bird
        self.gameType = gameType
    }
}

