//
//  LetterSelectionGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct LetterSelectionGameView: View {
    let bird: Bird
    let birdImage: BirdImage
    let onComplete: (UUID, Bool) -> Void
    
    @State private var currentPosition: Int = 0 // Current position in the word to fill
    @State private var filledLetters: [Character?] = [] // Array of filled letters (nil for unfilled)
    @State private var currentOptions: [Character] = [] // 4 letter options for current position
    @State private var incorrectAttempts: Int = 0
    @State private var gameWon: Bool = false
    @State private var gameLost: Bool = false
    @State private var showResult: Bool = false
    @State private var completionTask: Task<Void, Never>?
    
    private var birdName: String {
        bird.name.uppercased()
    }
    
    private var nameLength: Int {
        birdName.count
    }
    
    var body: some View {
        VStack(spacing: Style.Dimensions.largeMargin) {
            // Question
            Text("What bird is this?")
                .font(Style.Font.h2.weight(.semibold))
                .padding(.top, Style.Dimensions.largeMargin)
            
            // Bird image
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                .frame(maxHeight: 300)
                .padding(Style.Dimensions.margin)
            
            Spacer()
            
            // Word display with underscores (wrapping across multiple lines)
            let columns = [
                GridItem(.adaptive(minimum: 48), spacing: 8)
            ]
            
            LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                ForEach(0..<nameLength, id: \.self) { index in
                    let char = filledLetters[safe: index]
                    // How is this still an issue in swift after all these years?!
                    let displayChar: Character = (char ?? "_") ?? "_"
                    let isSpace = char == " "
                    let isCurrent = index == currentPosition && !gameWon && !gameLost
                    
                    Text(String(displayChar))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(isCurrent ? .accentColor : (isSpace ? .clear : .primary))
                        .frame(width: isSpace ? 20 : 40, height: 50)
                        .background {
                            if !isSpace {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
                            }
                        }
                        .overlay {
                            if !isSpace {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        isCurrent ? Color.accentColor : Color.gray.opacity(0.3),
                                        lineWidth: isCurrent ? 2 : 1
                                    )
                            }
                        }
                }
            }
            .padding(.horizontal, Style.Dimensions.margin)
            
            // Letter options
            if !gameWon && !gameLost {
                HStack(spacing: Style.Dimensions.margin) {
                    ForEach(0..<4, id: \.self) { index in
                        if index < currentOptions.count {
                            LetterButton(
                                letter: currentOptions[index],
                                isCorrect: currentOptions[index] == getCorrectLetter(),
                                action: {
                                    selectLetter(currentOptions[index])
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, Style.Dimensions.margin)
            }
            
            // Result message - always in hierarchy, use opacity to show/hide
            VStack(spacing: 0) {
                // Game result message
                Text(gameWon ? "Correct! ✓" : "Game Over. The answer is \(bird.name)")
                    .font(Style.Font.b2)
                    .foregroundColor(gameWon ? .green : .red)
                    .padding(.top, Style.Dimensions.margin)
                    .opacity(showResult ? 1.0 : 0.0)
                    .transition(.opacity)
                
                // Wrong attempts counter
                Text("Wrong attempts: \(incorrectAttempts)/3")
                    .font(Style.Font.b3)
                    .foregroundColor(.orange)
                    .padding(.top, Style.Dimensions.margin)
                    .opacity(!showResult && incorrectAttempts > 0 ? 1.0 : 0.0)
            }
            .frame(height: 50) // Reserve space to prevent layout shifts
        }
        .padding(Style.Dimensions.margin)
        .onAppear {
            setupGame()
        }
        .onDisappear {
            completionTask?.cancel()
            completionTask = nil
        }
    }
    
    private func setupGame() {
        // Initialize filled letters array with nils (showing as underscores)
        // Auto-fill spaces
        filledLetters = birdName.map { char in
            char == " " ? " " : nil
        }
        // Find first non-space position
        currentPosition = 0
        while currentPosition < nameLength && filledLetters[currentPosition] != nil {
            currentPosition += 1
        }
        incorrectAttempts = 0
        gameWon = false
        gameLost = false
        showResult = false
        generateOptions()
    }
    
    private func getCorrectLetter() -> Character {
        guard currentPosition < birdName.count else {
            return " "
        }
        let index = birdName.index(birdName.startIndex, offsetBy: currentPosition)
        return birdName[index]
    }
    
    private func generateOptions() {
        let correctLetter = getCorrectLetter()
        var options: [Character] = [correctLetter]
        
        // Generate 3 random incorrect letters
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var usedLetters: Set<Character> = [correctLetter]
        
        while options.count < 4 {
            if let randomLetter = alphabet.randomElement(), !usedLetters.contains(randomLetter) {
                options.append(randomLetter)
                usedLetters.insert(randomLetter)
            }
        }
        
        // Shuffle the options
        currentOptions = options.shuffled()
    }
    
    private func selectLetter(_ letter: Character) {
        guard !gameWon && !gameLost else { return }
        guard currentPosition < nameLength else { return }
        
        let correctLetter = getCorrectLetter()
        
        if letter == correctLetter {
            // Correct letter selected
            filledLetters[currentPosition] = letter
            currentPosition += 1
            
            // Skip spaces automatically
            while currentPosition < nameLength && filledLetters[currentPosition] != nil {
                currentPosition += 1
            }
            
            // Check if word is complete
            if currentPosition >= nameLength {
                gameWon = true
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
                // Generate new options for next position
                generateOptions()
            }
        } else {
            // Wrong letter selected
            incorrectAttempts += 1
            
            if incorrectAttempts >= 3 {
                // Game lost
                gameLost = true
                withAnimation {
                    showResult = true
                }
                
                // Auto-advance after showing result
                completionTask?.cancel()
                completionTask = Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    if !Task.isCancelled {
                        onComplete(bird.id, false)
                    }
                }
            }
            // Don't regenerate options - keep the same options to make it more forgiving
        }
    }
}

struct LetterButton: View {
    let letter: Character
    let isCorrect: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(String(letter))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 70, height: 70)
                .background {
                    ZStack {
                        // Base glass background
                        RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.85)
                        
                        // Accent gradient overlay
                        RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor.opacity(0.3),
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.9),
                                    Color.accentColor.opacity(0.5),
                                    Color.accentColor.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: Color.accentColor.opacity(0.3),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        }
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
    return LetterSelectionGameView(
        bird: bird,
        birdImage: bird.images.first!,
        onComplete: { _, _ in }
    )
}

