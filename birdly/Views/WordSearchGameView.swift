//
//  WordSearchGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct WordSearchGameView: View {
    let bird: Bird
    let birdImage: BirdImage
    let onComplete: (UUID, Bool) -> Void
    
    @State private var grid: [[Character]] = []
    @State private var selectedCells: Set<GridPosition> = []
    @State private var selectedPath: [GridPosition] = [] // Track the order of selection
    @State private var startPosition: GridPosition?
    @State private var foundWord = false
    @State private var showResult = false
    @State private var completionTask: Task<Void, Never>?
    @State private var hasStartedInteraction = false
    @State private var cellPositions: [GridPosition: CGPoint] = [:]
    @State private var incorrectAttempts = 0
    @State private var gridSize: Int = 5
    @State private var isGenerating = true
    
    private let cellSpacing: CGFloat = 8
    private let maxGridSize = 10 // Maximum grid size to prevent UI from getting too large
    private let generationAttemptThreshold = 100 // Threshold before increasing grid size
    
    // Dynamic cell size based on grid size - smaller cells for larger grids
    private var cellSize: CGFloat {
        // Scale down cell size as grid gets larger to keep UI reasonable
        if gridSize <= 5 {
            return 50
        } else if gridSize <= 7 {
            return 42
        } else {
            return 36
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Style.Dimensions.margin) {
                // Bird image at the top - fills available space
                BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Style.Dimensions.margin)
                
                // Word search grid
                ZStack {
                    if isGenerating {
                        // Loading indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.accentColor)
                    }
                    
                    // Draw lines connecting selected cells
                    if !selectedPath.isEmpty && !cellPositions.isEmpty && !isGenerating {
                        Path { path in
                            for (index, position) in selectedPath.enumerated() {
                                if let point = cellPositions[position] {
                                    if index == 0 {
                                        path.move(to: point)
                                    } else {
                                        path.addLine(to: point)
                                    }
                                }
                            }
                        }
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                    
                    // Grid of circular letters
                    if !isGenerating {
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<gridSize, id: \.self) { row in
                                HStack(spacing: cellSpacing) {
                                    ForEach(0..<gridSize, id: \.self) { col in
                                        let position = GridPosition(row: row, col: col)
                                        let isSelected = selectedCells.contains(position)
                                        let isPartOfWord = isCellPartOfWord(position)
                                        
                                        Text(String(grid[safe: row]?[safe: col] ?? " "))
                                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                                            .frame(width: cellSize, height: cellSize)
                                            .background {
                                                ZStack {
                                                    // Base glass background
                                                    Circle()
                                                        .fill(.ultraThinMaterial)
                                                        .opacity(0.7)
                                                    
                                                    // Color overlay based on state
                                                    Circle()
                                                        .fill(backgroundColor(for: position, isSelected: isSelected, isPartOfWord: isPartOfWord))
                                                    
                                                    // Accent glow for selected state
                                                    if isSelected && !isPartOfWord {
                                                        Circle()
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.accentColor.opacity(0.4),
                                                                        Color.accentColor.opacity(0.2)
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                    }
                                                }
                                            }
                                            .foregroundColor(textColor(for: position, isSelected: isSelected, isPartOfWord: isPartOfWord))
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                borderColor(for: position, isSelected: isSelected, isPartOfWord: isPartOfWord).opacity(0.9),
                                                                borderColor(for: position, isSelected: isSelected, isPartOfWord: isPartOfWord).opacity(0.5)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: isSelected ? 3 : 1.5
                                                    )
                                            )
                                            .shadow(
                                                color: borderColor(for: position, isSelected: isSelected, isPartOfWord: isPartOfWord).opacity(0.4),
                                                radius: isSelected ? 6 : 3,
                                                x: 0,
                                                y: 2
                                            )
                                            .background(
                                                GeometryReader { geometry in
                                                    Color.clear
                                                        .preference(
                                                            key: CellPositionKey.self,
                                                            value: [position: CGPoint(
                                                                x: geometry.frame(in: .named("grid")).midX,
                                                                y: geometry.frame(in: .named("grid")).midY
                                                            )]
                                                        )
                                                }
                                            )
                                    }
                                }
                            }
                        }
                        .coordinateSpace(name: "grid")
                    }
                }
                .frame(
                    width: CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * cellSpacing,
                    height: CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * cellSpacing
                )
                .contentShape(Rectangle())
                .onPreferenceChange(CellPositionKey.self) { positions in
                    cellPositions = positions
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
                        .onChanged { value in
                            guard incorrectAttempts < 3 else { return }
                            
                            if !hasStartedInteraction {
                                hasStartedInteraction = true
                            }
                            
                            // Find which cell the drag is over by checking distance to cell centers
                            let dragPoint = value.location
                            var closestPosition: GridPosition?
                            var minDistance: CGFloat = .infinity
                            
                            for (position, center) in cellPositions {
                                let distance = sqrt(
                                    pow(dragPoint.x - center.x, 2) + 
                                    pow(dragPoint.y - center.y, 2)
                                )
                                
                                // Check if within the circle (radius is cellSize/2)
                                if distance <= cellSize / 2 && distance < minDistance {
                                    minDistance = distance
                                    closestPosition = position
                                }
                            }
                            
                            if let position = closestPosition {
                                handleCellSelection(at: position)
                            }
                        }
                        .onEnded { value in
                            guard incorrectAttempts < 3 else { return }
                            
                            // Check if this was a tap (very small movement)
                            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            
                            if distance < 5 && selectedPath.count == 1 {
                                // Single tap - check word immediately
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    checkWord()
                                    startPosition = nil
                                }
                            } else {
                                // Drag ended - check word
                                checkWord()
                                startPosition = nil
                            }
                        }
                )
                .disabled(incorrectAttempts >= 3 || isGenerating)
                .padding(Style.Dimensions.margin)
                .shadow(
                    color: Color.accentColor.opacity(0.2),
                    radius: 10,
                    x: 0,
                    y: 4
                )
                .padding(.horizontal, Style.Dimensions.margin)
                
                // Result message or hint text at the bottom
                if showResult {
                    Text(foundWord ? "Correct! You found \(bird.name)! ✓" : (incorrectAttempts >= 3 ? "The answer is \(bird.name)" : "Not quite. Try again!"))
                        .font(Style.Font.b2)
                        .foregroundColor(foundWord ? .green : .orange)
                        .transition(.opacity)
                } else {
                    Text(incorrectAttempts > 0 ? "Attempts: \(incorrectAttempts)/3" : "Drag to select letters")
                        .font(Style.Font.b3)
                        .foregroundColor(incorrectAttempts > 0 ? .orange : .secondary)
                }
            }
            .padding(Style.Dimensions.margin)
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await generateWordSearch()
            }
        }
        .onDisappear {
            completionTask?.cancel()
            completionTask = nil
        }
    }
    
    private func generateWordSearch() async {
        let word = bird.name.uppercased().replacingOccurrences(of: " ", with: "")
        let wordLength = word.count
        let maxGridSize = self.maxGridSize
        let generationAttemptThreshold = self.generationAttemptThreshold
        
        // Run heavy computation on background thread
        let result = await Task.detached(priority: .userInitiated) {
            // Start with grid size 5
            var currentGridSize = 5
            
            var success = false
            var attempts = 0
            let maxTotalAttempts = 3 // Maximum times to increase grid size
            var generatedGrid: [[Character]] = []
            var finalGridSize = 5
            
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
                let wordPath = Self.generateRandomWalkPath(
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
                let fallbackPath = Self.generateFallbackPath(wordLength: wordLength, gridSize: finalGridSize)
                for (index, position) in fallbackPath.enumerated() {
                    if index < wordLength {
                        let char = word[word.index(word.startIndex, offsetBy: index)]
                        generatedGrid[position.row][position.col] = char
                    }
                }
            }
            
            return (generatedGrid, finalGridSize)
        }.value
        
        // Update UI on main thread
        await MainActor.run {
            grid = result.0
            gridSize = result.1
            isGenerating = false
        }
    }
    
    private nonisolated static func generateRandomWalkPath(wordLength: Int, gridSize: Int, maxAttempts: Int) -> [GridPosition] {
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
                    let extended = Self.extendPath(from: bestPath, targetLength: wordLength, gridSize: gridSize)
                    if extended.count >= wordLength {
                        return Array(extended.prefix(wordLength))
                    }
                }
            }
        
        // Fallback: create a simple snaking path if random walk fails
        return Self.generateFallbackPath(wordLength: wordLength, gridSize: gridSize)
    }
    
    private nonisolated static func extendPath(from existingPath: [GridPosition], targetLength: Int, gridSize: Int) -> [GridPosition] {
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
    
    private nonisolated static func generateFallbackPath(wordLength: Int, gridSize: Int) -> [GridPosition] {
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
    
    
    private func handleCellSelection(at position: GridPosition) {
        // Validate position is within bounds
        guard position.row >= 0 && position.row < gridSize && 
              position.col >= 0 && position.col < gridSize else {
            return
        }
        
        if startPosition == nil {
            // Start new selection
            startPosition = position
            selectedPath = [position]
            selectedCells = [position]
        } else {
            // Check if this position is adjacent to the last cell in the path
            if let lastCell = selectedPath.last {
                if isAdjacent(lastCell, position) {
                    // If it's already in the path, allow backtracking (remove everything after it)
                    if let index = selectedPath.firstIndex(of: position) {
                        selectedPath = Array(selectedPath.prefix(index + 1))
                        selectedCells = Set(selectedPath)
                    } else {
                        // Add new adjacent cell to path
                        selectedPath.append(position)
                        selectedCells.insert(position)
                    }
                } else if position == startPosition && selectedPath.count > 1 {
                    // Allow going back to start to clear and restart
                    // Don't reset attempts here - let them keep trying
                    selectedPath = [position]
                    selectedCells = [position]
                }
            }
        }
    }
    
    private func isAdjacent(_ pos1: GridPosition, _ pos2: GridPosition) -> Bool {
        let rowDiff = abs(pos1.row - pos2.row)
        let colDiff = abs(pos1.col - pos2.col)
        // Adjacent means row and col differ by at most 1, and at least one differs
        return (rowDiff <= 1 && colDiff <= 1) && (rowDiff > 0 || colDiff > 0)
    }
    
    private func checkWord() {
        guard !selectedPath.isEmpty else { return }
        // Don't check if we've already reached 3 attempts
        guard incorrectAttempts < 3 else { return }
        
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
        let targetWord = bird.name.uppercased().replacingOccurrences(of: " ", with: "")
        let reversedTarget = String(targetWord.reversed())
        
        foundWord = forwardWord == targetWord || forwardWord == reversedTarget || 
                   reverseWord == targetWord || reverseWord == reversedTarget
        
        if foundWord {
            // Reset incorrect attempts on correct answer
            incorrectAttempts = 0
            
            withAnimation {
                showResult = true
            }
            
            // Auto-advance after showing result
            completionTask?.cancel()
            completionTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if !Task.isCancelled {
                    onComplete(bird.id, true)
                }
            }
        } else {
            // Increment incorrect attempts
            incorrectAttempts += 1
            
            // If 3 incorrect attempts, mark as wrong and move on
            if incorrectAttempts >= 3 {
                withAnimation {
                    showResult = true
                }
                
                completionTask?.cancel()
                completionTask = Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    if !Task.isCancelled {
                        onComplete(bird.id, false)
                    }
                }
            } else {
                // Clear selection after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !foundWord {
                        withAnimation {
                            selectedCells = []
                            selectedPath = []
                            startPosition = nil
                        }
                    }
                }
            }
        }
    }
    
    private func isCellPartOfWord(_ position: GridPosition) -> Bool {
        guard foundWord else { return false }
        // This is a simplified check - in a full implementation, we'd track where the word was placed
        return selectedCells.contains(position)
    }
    
    private func backgroundColor(for position: GridPosition, isSelected: Bool, isPartOfWord: Bool) -> Color {
        if foundWord && isPartOfWord {
            return Color.green.opacity(0.3)
        } else if isSelected {
            return Color.accentColor.opacity(0.2)
        }
        return Color.clear
    }
    
    private func textColor(for position: GridPosition, isSelected: Bool, isPartOfWord: Bool) -> Color {
        if foundWord && isPartOfWord {
            return .green
        } else if isSelected {
            return .accentColor
        }
        return .primary
    }
    
    private func borderColor(for position: GridPosition, isSelected: Bool, isPartOfWord: Bool) -> Color {
        if foundWord && isPartOfWord {
            return .green
        } else if isSelected {
            return .accentColor
        }
        return .gray.opacity(0.2)
    }
}

fileprivate struct GridPosition: @nonisolated Hashable {
    let row: Int
    let col: Int
}

// PreferenceKey to track cell positions for drawing lines
fileprivate struct CellPositionKey: PreferenceKey {
    static var defaultValue: [GridPosition: CGPoint] = [:]
    
    static func reduce(value: inout [GridPosition: CGPoint], nextValue: () -> [GridPosition: CGPoint]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

#Preview {
    let bird = Bird(
        id: UUID(),
        name: "Robin",
        scientificName: "Erithacus rubecula",
        description: "Distinctive orange-red breast",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Robin Perched"))
        ]
    )
    return WordSearchGameView(
        bird: bird,
        birdImage: bird.images.first!,
        onComplete: { _, _ in }
    )
}

