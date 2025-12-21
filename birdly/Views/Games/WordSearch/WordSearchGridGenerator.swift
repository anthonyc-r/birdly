//
//  WordSearchGridGenerator.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

struct WordSearchGridGenerator {
    let maxGridSize: Int
    let generationAttemptThreshold: Int
    
    init(maxGridSize: Int = 10, generationAttemptThreshold: Int = 100) {
        self.maxGridSize = maxGridSize
        self.generationAttemptThreshold = generationAttemptThreshold
    }
    
    func generate(word: String) async -> WordSearchGrid? {
        let wordLength = word.count
        let maxGridSize = self.maxGridSize
        let generationAttemptThreshold = self.generationAttemptThreshold
        
        // Run heavy computation on background thread
        return await Task.detached(priority: .userInitiated) {
            var currentGridSize = 4
            
            var attempts = 0
            let maxTotalAttempts = 3 // Maximum times to increase grid size
            var generatedGrid: [[Character]] = []
            var finalGridSize = 4
            
            while attempts < maxTotalAttempts && currentGridSize <= maxGridSize {
                // Ensure word fits in current grid
                if wordLength > currentGridSize * currentGridSize {
                    // Word is too long for this grid size, increase it
                    currentGridSize = min(maxGridSize, currentGridSize + 1)
                    attempts += 1
                    continue
                }
                
                let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                
                // Initialize grid with random letters
                generatedGrid = (0..<currentGridSize).map { _ in
                    (0..<currentGridSize).map { _ in
                        alphabet.randomElement() ?? "A"
                    }
                }
                
                // Generate a random walk path through the grid
                guard let wordPath = WordSearchPathGenerator.generateRandomWalkPath(wordLength: wordLength,gridSize: currentGridSize,maxAttempts: generationAttemptThreshold) else {
                    currentGridSize = min(maxGridSize, currentGridSize + 1)
                    attempts += 1
                    continue
                }
                
                // Place the word along the generated path
                for (index, position) in wordPath.enumerated() {
                    if index < wordLength {
                        let char = word[word.index(word.startIndex, offsetBy: index)]
                        generatedGrid[position.row][position.col] = char
                    }
                }
                finalGridSize = currentGridSize
                return WordSearchGrid(grid: generatedGrid, gridSize: finalGridSize)
            }
            // Else we couldn't generate a grid in a reasonable time, don't show this game
            return nil
        }.value
    }
    
    struct WordSearchGrid {
        let grid: [[Character]]
        let gridSize: Int
    }
}

