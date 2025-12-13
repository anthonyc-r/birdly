//
//  WordSearchGameLogic.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

struct WordSearchGameLogic {
    static func isAdjacent(_ pos1: GridPosition, _ pos2: GridPosition) -> Bool {
        let rowDiff = abs(pos1.row - pos2.row)
        let colDiff = abs(pos1.col - pos2.col)
        // Adjacent means row and col differ by at most 1, and at least one differs
        return (rowDiff <= 1 && colDiff <= 1) && (rowDiff > 0 || colDiff > 0)
    }
    
    static func checkWord(
        selectedPath: [GridPosition],
        grid: [[Character]],
        targetWord: String
    ) -> Bool {
        guard !selectedPath.isEmpty else { return false }
        
        // Use the path in the order it was selected
        let forwardWord = selectedPath.compactMap { pos -> Character? in
            guard pos.row < grid.count && pos.col < grid[pos.row].count else { return nil }
            return grid[pos.row][pos.col]
        }.map(String.init).joined()
        
        // Try reverse order as well
        let reverseWord = Array(selectedPath.reversed()).compactMap { pos -> Character? in
            guard pos.row < grid.count && pos.col < grid[pos.row].count else { return nil }
            return grid[pos.row][pos.col]
        }.map(String.init).joined()
        
        // Check both forward and reverse
        let reversedTarget = String(targetWord.reversed())
        
        return forwardWord == targetWord || forwardWord == reversedTarget ||
               reverseWord == targetWord || reverseWord == reversedTarget
    }
}

