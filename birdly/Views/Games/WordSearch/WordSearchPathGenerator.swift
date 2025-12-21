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
    // All 8 possible directions (matching Go algorithm order)
    // up, down, left, right, up-left, up-right, down-left, down-right
    private static nonisolated let directions: [(dy: Int, dx: Int)] = [
        (0, -1),  // up
        (0, 1),   // down
        (-1, 0),  // left
        (1, 0),   // right
        (-1, -1), // up-left
        (1, -1),  // up-right
        (-1, 1),  // down-left
        (1, 1)    // down-right
    ]
    
    static nonisolated func generateRandomWalkPath(wordLength: Int, gridSize: Int, maxAttempts: Int = 100) -> [GridPosition]? {
        var attempts = 0
        
        while attempts < maxAttempts {
            // Create a board to track visited cells (false = empty, true = occupied)
            var board = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
            var path: [GridPosition] = []
            
            // Try random starting position
            let startRow = Int.random(in: 0..<gridSize)
            let startCol = Int.random(in: 0..<gridSize)
            
            // Try to place the path recursively
            if placePath(board: &board, path: &path, row: startRow, col: startCol, index: 0, wordLength: wordLength, gridSize: gridSize) {
                return path
            }
            
            attempts += 1
        }
        
        // Fallback: create a simple snaking path if recursive placement fails
        return nil
    }
    
    // Returns valid directions from a given position
    private static nonisolated func validDirections(row: Int, col: Int, board: [[Bool]], gridSize: Int) -> [(dy: Int, dx: Int)] {
        var valid: [(dy: Int, dx: Int)] = []
        
        for dir in directions {
            let newRow = row + dir.dy
            let newCol = col + dir.dx
            
            if newRow >= 0 && newRow < gridSize &&
               newCol >= 0 && newCol < gridSize &&
               !board[newRow][newCol] {
                valid.append(dir)
            }
        }
        
        return valid
    }
    
    // Recursive function to place the path (equivalent to Go's placeWord)
    private static nonisolated func placePath(
        board: inout [[Bool]],
        path: inout [GridPosition],
        row: Int,
        col: Int,
        index: Int,
        wordLength: Int,
        gridSize: Int
    ) -> Bool {
        // Base case: if we've placed all positions, we're done
        if index == wordLength {
            return true
        }
        
        // Mark current cell as occupied
        board[row][col] = true
        path.append(GridPosition(row: row, col: col))
        
        // Get valid directions and shuffle them
        var validDirs = validDirections(row: row, col: col, board: board, gridSize: gridSize)
        validDirs.shuffle()
        
        // Try each valid direction
        for dir in validDirs {
            let newRow = row + dir.dy
            let newCol = col + dir.dx
            
            if placePath(board: &board, path: &path, row: newRow, col: newCol, index: index + 1, wordLength: wordLength, gridSize: gridSize) {
                return true
            }
        }
        
        // Backtrack: unmark this cell and remove from path
        board[row][col] = false
        path.removeLast()
        return false
    }
}

