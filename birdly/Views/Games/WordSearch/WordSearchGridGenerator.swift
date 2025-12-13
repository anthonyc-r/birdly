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
    
    func generate(word: String) async -> (grid: [[Character]], gridSize: Int) {
        let wordLength = word.count
        let maxGridSize = self.maxGridSize
        let generationAttemptThreshold = self.generationAttemptThreshold
        
        // Run heavy computation on background thread
        return await Task.detached(priority: .userInitiated) {
            var currentGridSize = 4
            
            var success = false
            var attempts = 0
            let maxTotalAttempts = 3 // Maximum times to increase grid size
            var generatedGrid: [[Character]] = []
            var finalGridSize = 4
            
            while !success && attempts < maxTotalAttempts && currentGridSize <= maxGridSize {
                // Ensure word fits in current grid
                if wordLength > currentGridSize * currentGridSize {
                    // Word is too long for this grid size, increase it
                    currentGridSize = min(maxGridSize, currentGridSize + 2)
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
                let wordPath = WordSearchPathGenerator.generateRandomWalkPath(
                    wordLength: wordLength,
                    gridSize: currentGridSize,
                    maxAttempts: generationAttemptThreshold
                )
                
                // Check if we got a complete path
                if wordPath.count >= wordLength {
                    // Place the word along the generated path
                    for (index, position) in wordPath.enumerated() {
                        if index < wordLength {
                            let char = word[word.index(word.startIndex, offsetBy: index)]
                            generatedGrid[position.row][position.col] = char
                        }
                    }
                    finalGridSize = currentGridSize
                    success = true
                } else {
                    // Path generation failed, try with larger grid
                    currentGridSize = min(maxGridSize, currentGridSize + 2)
                    attempts += 1
                }
            }
            
            // If still failed after all attempts, use fallback path
            if !success {
                let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                generatedGrid = (0..<finalGridSize).map { _ in
                    (0..<finalGridSize).map { _ in
                        alphabet.randomElement() ?? "A"
                    }
                }
                let fallbackPath = WordSearchPathGenerator.generateFallbackPath(
                    wordLength: wordLength,
                    gridSize: finalGridSize
                )
                for (index, position) in fallbackPath.enumerated() {
                    if index < wordLength {
                        let char = word[word.index(word.startIndex, offsetBy: index)]
                        generatedGrid[position.row][position.col] = char
                    }
                }
            }
            
            return (generatedGrid, finalGridSize)
        }.value
    }
}

