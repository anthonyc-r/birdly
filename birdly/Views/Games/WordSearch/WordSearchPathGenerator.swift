//
//  WordSearchPathGenerator.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

struct GridPosition: nonisolated Hashable {
    let row: Int
    let col: Int
}

struct WordSearchPathGenerator {
    static nonisolated func generateRandomWalkPath(wordLength: Int, gridSize: Int, maxAttempts: Int = 100) -> [GridPosition] {
        // All 8 possible directions (including diagonals)
        let allDirections: [(Int, Int)] = [
            (-1, -1), (-1, 0), (-1, 1),  // Up-left, Up, Up-right
            (0, -1),           (0, 1),   // Left, Right
            (1, -1),  (1, 0),  (1, 1)    // Down-left, Down, Down-right
        ]
        
        var bestPath: [GridPosition] = []
        var attempts = 0
        
        // Try multiple starting positions to find a good path
        while attempts < maxAttempts {
            // Start at a random position, but prefer center area for longer words
            let startRow: Int
            let startCol: Int
            if wordLength > gridSize {
                // For longer words, start more towards center
                let centerRange = gridSize / 3
                startRow = Int.random(in: centerRange..<(gridSize - centerRange))
                startCol = Int.random(in: centerRange..<(gridSize - centerRange))
            } else {
                startRow = Int.random(in: 0..<gridSize)
                startCol = Int.random(in: 0..<gridSize)
            }
            
            let startPos = GridPosition(row: startRow, col: startCol)
            var path: [GridPosition] = [startPos]
            var visited: Set<GridPosition> = [startPos]
            var currentPos = startPos
            var lastDirection: (Int, Int)? = nil
            var stuckCount = 0
            let maxStuckCount = 15
            
            // Build path by random walk
            while path.count < wordLength && stuckCount < maxStuckCount {
                // Shuffle directions, but prefer changing direction for more interesting paths
                var candidateDirections = allDirections.shuffled()
                
                // If we have a last direction, prefer perpendicular directions for variety
                if let lastDir = lastDirection {
                    let perpendicular = candidateDirections.filter { dir in
                        dir.0 != lastDir.0 || dir.1 != lastDir.1
                    }
                    if !perpendicular.isEmpty {
                        candidateDirections = perpendicular.shuffled() + candidateDirections.filter { $0 == lastDir }
                    }
                }
                
                var foundNext = false
                
                // Try each direction, preferring unvisited cells
                for direction in candidateDirections {
                    let nextRow = currentPos.row + direction.0
                    let nextCol = currentPos.col + direction.1
                    let nextPos = GridPosition(row: nextRow, col: nextCol)
                    
                    // Check if valid
                    if nextRow >= 0 && nextRow < gridSize &&
                       nextCol >= 0 && nextCol < gridSize {
                        
                        // Strongly prefer unvisited cells
                        if !visited.contains(nextPos) {
                            path.append(nextPos)
                            visited.insert(nextPos)
                            currentPos = nextPos
                            lastDirection = direction
                            foundNext = true
                            stuckCount = 0
                            break
                        }
                    }
                }
                
                // If no unvisited cell found, allow revisiting (but only if we're close to target length)
                if !foundNext {
                    for direction in candidateDirections.shuffled() {
                        let nextRow = currentPos.row + direction.0
                        let nextCol = currentPos.col + direction.1
                        let nextPos = GridPosition(row: nextRow, col: nextCol)
                        
                        if nextRow >= 0 && nextRow < gridSize &&
                           nextCol >= 0 && nextCol < gridSize &&
                           path.count >= wordLength * 3 / 4 {
                            path.append(nextPos)
                            currentPos = nextPos
                            lastDirection = direction
                            foundNext = true
                            stuckCount = 0
                            break
                        }
                    }
                }
                
                if !foundNext {
                    stuckCount += 1
                    // If stuck, backtrack
                    if stuckCount >= maxStuckCount && path.count > 1 {
                        let removed = path.removeLast()
                        visited.remove(removed)
                        if let last = path.last {
                            currentPos = last
                            // Reset last direction to previous step's direction
                            if path.count > 1 {
                                let prev = path[path.count - 2]
                                lastDirection = (currentPos.row - prev.row, currentPos.col - prev.col)
                            } else {
                                lastDirection = nil
                            }
                            stuckCount = 0
                        } else {
                            break
                        }
                    }
                }
            }
            
            // If we found a good path, use it
            if path.count >= wordLength {
                return Array(path.prefix(wordLength))
            }
            
            // Keep track of best path so far
            if path.count > bestPath.count {
                bestPath = path
            }
            
            attempts += 1
        }
        
        // If we have a partial path, try to extend it
        if bestPath.count > 0 {
            if bestPath.count >= wordLength {
                return Array(bestPath.prefix(wordLength))
            } else {
                // Try to extend from the last position
                let extended = extendPath(from: bestPath, targetLength: wordLength, gridSize: gridSize)
                if extended.count >= wordLength {
                    return Array(extended.prefix(wordLength))
                }
            }
        }
        
        // Fallback: create a simple snaking path if random walk fails
        return generateFallbackPath(wordLength: wordLength, gridSize: gridSize)
    }
    
    static nonisolated func extendPath(from existingPath: [GridPosition], targetLength: Int, gridSize: Int) -> [GridPosition] {
        guard let lastPos = existingPath.last else { return existingPath }
        var path = existingPath
        var visited = Set(existingPath)
        var currentPos = lastPos
        let allDirections: [(Int, Int)] = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]
        
        while path.count < targetLength {
            let shuffled = allDirections.shuffled()
            var found = false
            
            for direction in shuffled {
                let nextRow = currentPos.row + direction.0
                let nextCol = currentPos.col + direction.1
                let nextPos = GridPosition(row: nextRow, col: nextCol)
                
                if nextRow >= 0 && nextRow < gridSize &&
                   nextCol >= 0 && nextCol < gridSize &&
                   !visited.contains(nextPos) {
                    path.append(nextPos)
                    visited.insert(nextPos)
                    currentPos = nextPos
                    found = true
                    break
                }
            }
            
            if !found {
                // Allow revisiting if necessary
                for direction in shuffled {
                    let nextRow = currentPos.row + direction.0
                    let nextCol = currentPos.col + direction.1
                    let nextPos = GridPosition(row: nextRow, col: nextCol)
                    
                    if nextRow >= 0 && nextRow < gridSize &&
                       nextCol >= 0 && nextCol < gridSize {
                        path.append(nextPos)
                        currentPos = nextPos
                        found = true
                        break
                    }
                }
                
                if !found {
                    break
                }
            }
        }
        
        return path
    }
    
    static nonisolated func generateFallbackPath(wordLength: Int, gridSize: Int) -> [GridPosition] {
        var path: [GridPosition] = []
        var row = gridSize / 2
        var col = max(0, (gridSize - wordLength) / 2)
        var direction = 1 // 1 for right, -1 for left
        
        for _ in 0..<wordLength {
            if col >= 0 && col < gridSize && row >= 0 && row < gridSize {
                path.append(GridPosition(row: row, col: col))
                
                // Snake pattern: move right/left, wrap to next row when hitting edge
                col += direction
                if col < 0 || col >= gridSize {
                    direction *= -1
                    col = max(0, min(gridSize - 1, col))
                    row += 1
                }
            } else {
                break
            }
        }
        
        return path
    }
}

