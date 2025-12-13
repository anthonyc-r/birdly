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
    private let gridGenerator = WordSearchGridGenerator(maxGridSize: 10, generationAttemptThreshold: 100)
    
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
    
    private var targetWord: String {
        bird.name.uppercased().replacingOccurrences(of: " ", with: "")
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Style.Dimensions.margin) {
                // Bird image at the top - fills available space
                BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                    .featherEffect()
                
                Spacer()
                
                VStack(spacing: Style.Dimensions.margin) {
                    // Word search grid
                    ZStack {
                        if isGenerating {
                            // Loading indicator
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.accentColor)
                        } else {
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<gridSize, id: \.self) { row in
                                    HStack(spacing: cellSpacing) {
                                        ForEach(0..<gridSize, id: \.self) { col in
                                            let position = GridPosition(row: row, col: col)
                                            let isSelected = selectedCells.contains(position)
                                            let isPartOfWord = isCellPartOfWord(position)
                                            let character = grid[safe: row]?[safe: col] ?? " "
                                            
                                            WordSearchCellView(
                                                character: character,
                                                position: position,
                                                cellSize: cellSize,
                                                isSelected: isSelected,
                                                isPartOfWord: isPartOfWord,
                                                foundWord: foundWord
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
                    Spacer()
                }
                .padding(Style.Dimensions.margin)
            }
        }
        .background {
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Material.thin)
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await loadWordSearch()
            }
        }
        .onDisappear {
            completionTask?.cancel()
            completionTask = nil
        }
    }
    
    private func loadWordSearch() async {
        let result = await gridGenerator.generate(word: targetWord)
        
        // Update UI on main thread
        await MainActor.run {
            grid = result.grid
            gridSize = result.gridSize
            isGenerating = false
        }
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
                if WordSearchGameLogic.isAdjacent(lastCell, position) {
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
    
    
    private func checkWord() {
        guard !selectedPath.isEmpty else { return }
        // Don't check if we've already reached 3 attempts
        guard incorrectAttempts < 3 else { return }
        
        foundWord = WordSearchGameLogic.checkWord(
            selectedPath: selectedPath,
            grid: grid,
            targetWord: targetWord
        )
        
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
        name: "Long Tailed Tit",
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

