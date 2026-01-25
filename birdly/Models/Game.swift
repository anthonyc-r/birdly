//
//  Game.swift
//  birdly
//
//  Created by tony on 25/01/2026.
//
import Foundation

struct Game: Identifiable, Equatable, Hashable {
    var id: UUID
    var bird: Bird
    var birdImage: BirdImage
    var gameType: GameType
    
    init(id: UUID = UUID(), bird: Bird, birdImage: BirdImage, gameType: GameType) {
        self.id = id
        self.bird = bird
        self.birdImage = birdImage
        self.gameType = gameType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(bird.id)
        hasher.combine(birdImage.id)
        hasher.combine(gameType)
    }
    
    static func == (_ lhs: Game, _ rhs: Game) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
