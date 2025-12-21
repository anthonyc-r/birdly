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
    let onAnswerRevealed: (Bool) -> Void
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
    
    private var birdNameWithoutSpaces: String {
        birdName.filter { $0 != " " }
    }
    
    private var nameLength: Int {
        birdNameWithoutSpaces.count
    }
    
    var body: some View {
        VStack(spacing: Style.Dimensions.largeMargin) {
            // Bird image
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                .featherEffect()
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Question
                Text("What bird is this?")
                    .font(Style.Font.h2.weight(.semibold))
                    .padding(.top, Style.Dimensions.largeMargin)
                
                // Word display with underscores (wrapping across multiple lines)
                let columns = [
                    GridItem(.adaptive(minimum: 48), spacing: 8)
                ]
                
                HStack {
                    Spacer()
                    LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                        ForEach(0..<nameLength, id: \.self) { index in
                            let char = filledLetters[safe: index]
                            let isCurrent = index == currentPosition && !gameWon && !gameLost
                            
                            LetterSlotView(
                                character: char ?? nil,
                                isCurrent: isCurrent
                            )
                        }
                    }
                    .padding(.horizontal, Style.Dimensions.margin)
                    Spacer()
                }
                
                Spacer()
                
                // Letter options
                HStack(spacing: Style.Dimensions.margin) {
                    ForEach(0..<4, id: \.self) { index in
                        if index < currentOptions.count {
                            LetterButton(
                                letter: currentOptions[index],
                                isCorrect: currentOptions[index] == getCorrectLetter(),
                                action: {
                                    FeedbackManager.shared.playSelectionFeedback()
                                    selectLetter(currentOptions[index])
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, Style.Dimensions.margin)
                .opacity(!gameWon && !gameLost ? 1.0 : 0.0)
                
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
        }
        .background {
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Material.thin)
        }
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
        filledLetters = Array(repeating: nil, count: nameLength)
        currentPosition = 0
        incorrectAttempts = 0
        gameWon = false
        gameLost = false
        showResult = false
        generateOptions()
    }
    
    private func getCorrectLetter() -> Character {
        guard currentPosition < birdNameWithoutSpaces.count else {
            return " "
        }
        let index = birdNameWithoutSpaces.index(birdNameWithoutSpaces.startIndex, offsetBy: currentPosition)
        return birdNameWithoutSpaces[index]
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
            
            // Check if word is complete
            if currentPosition >= nameLength {
                gameWon = true
                
                // Notify LearningView that answer is revealed
                onAnswerRevealed(true)
                
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
                
                // Notify LearningView that answer is revealed
                onAnswerRevealed(false)
                
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

struct LetterSlotView: View {
    let character: Character?
    let isCurrent: Bool
    
    var body: some View {
        let displayChar: Character = (character ?? "_")
        
        Text(String(displayChar))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(isCurrent ? .accentColor : .primary)
            .frame(width: 40, height: 50)
            .padding(Style.Dimensions.smallMargin * 0.5)
            .liquidGlassCard()
            .opacity(isCurrent || character != nil ? 1.0 : 0.5)
    }
}

struct LetterButton: View {
    let letter: Character
    let isCorrect: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(letter.description)
                .frame(width: 20, height: 20)
                .font(Style.Font.h3)
                .foregroundStyle(buttonColors.text)
                .padding(Style.Dimensions.margin * 1.5)
        }
        .glassEffect(.clear.interactive())
    }
    
    private var buttonColors: (text: Color, background: Color) {
        return (Color.primary, Color(.accent).opacity(0.25))
    }
}

#Preview {
    let bird = Bird(
        id: UUID(),
        name: "Robin Test",
        scientificName: "Erithacus rubecula",
        description: "Distinctive orange-red breast",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Robin Perched"))
        ]
    )
    return LetterSelectionGameView(
        bird: bird,
        birdImage: bird.images.first!,
        onAnswerRevealed: { _ in },
        onComplete: { _, _ in }
    )
}

