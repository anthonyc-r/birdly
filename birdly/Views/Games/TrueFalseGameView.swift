//
//  TrueFalseGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct TrueFalseGameView: View {
    let correctBird: Bird
    let birdImage: BirdImage
    let introducedBirds: Set<UUID>
    let allBirds: [Bird]
    let onAnswerRevealed: (Bool) -> Void
    let onComplete: (UUID, Bool) -> Void
    
    @State private var displayedBirdName: String = ""
    @State private var isCorrectMatch: Bool = true // Whether the displayed name matches the image
    @State private var selectedAnswer: Bool?
    @State private var showResult = false
    @State private var wasCorrect = false
    @State private var completionTask: Task<Void, Never>?
    
    private func setupGame() {
        // Randomly decide whether to show correct or incorrect name
        // 50% chance of correct, 50% chance of incorrect
        isCorrectMatch = Bool.random()
        
        if isCorrectMatch {
            // Show the correct bird name
            displayedBirdName = correctBird.name
        } else {
            // Show a wrong bird name from introduced birds
            let wrongOptions = allBirds.filter {
                $0.id != correctBird.id && introducedBirds.contains($0.id)
            }
            
            if let wrongBird = wrongOptions.randomElement() {
                displayedBirdName = wrongBird.name
            } else {
                // Fallback: if no wrong options, show correct (but mark as incorrect match)
                // This shouldn't happen in practice, but handle gracefully
                displayedBirdName = correctBird.name
                isCorrectMatch = true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: Style.Dimensions.largeMargin) {
            // Bird image
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                .featherEffect()
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Question
                Text("Is this a \(displayedBirdName)?")
                    .font(Style.Font.h2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.top, Style.Dimensions.largeMargin)
                    .padding(.horizontal, Style.Dimensions.margin)
                
                Spacer()
                
                // True/False buttons
                HStack(spacing: Style.Dimensions.largeMargin) {
                    TrueFalseButton(
                        value: true,
                        isSelected: selectedAnswer == true,
                        isCorrect: showResult && wasCorrect && selectedAnswer == true,
                        isWrong: showResult && !wasCorrect && selectedAnswer == true,
                        isDisabled: showResult
                    ) {
                        FeedbackManager.shared.playSelectionFeedback()
                        selectAnswer(true)
                    }
                    Spacer()
                    TrueFalseButton(
                        value: false,
                        isSelected: selectedAnswer == false,
                        isCorrect: showResult && wasCorrect && selectedAnswer == false,
                        isWrong: showResult && !wasCorrect && selectedAnswer == false,
                        isDisabled: showResult
                    ) {
                        FeedbackManager.shared.playSelectionFeedback()
                        selectAnswer(false)
                    }
                }
                .padding(.horizontal, Style.Dimensions.margin)
                
                // Result message
                VStack(spacing: Style.Dimensions.smallMargin) {
                    Text(wasCorrect ? "Correct! ✓" : "Not quite.")
                        .font(Style.Font.b2)
                        .foregroundColor(wasCorrect ? .green : .red)
                    
                    // Show actual bird name when the statement is false (regardless of answer correctness)
                    if !isCorrectMatch {
                        Text("This is a \(correctBird.name)")
                            .font(Style.Font.b2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, Style.Dimensions.margin)
                .transition(.opacity)
                .opacity(showResult ? 1.0 : 0.0)
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
    
    private func selectAnswer(_ answer: Bool) {
        guard !showResult else { return }
        
        // Check if the answer is correct
        // If isCorrectMatch is true, then True is correct
        // If isCorrectMatch is false, then False is correct
        wasCorrect = (answer == isCorrectMatch)
        selectedAnswer = answer
        
        // Notify LearningView that answer is revealed
        onAnswerRevealed(wasCorrect)
        
        withAnimation {
            showResult = true
        }
        
        // Auto-advance after showing result
        completionTask?.cancel()
        completionTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            if !Task.isCancelled {
                onComplete(correctBird.id, wasCorrect)
            }
        }
    }
}

struct TrueFalseButton: View {
    let value: Bool
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: value ? "checkmark" : "xmark")
                .resizable()
                .fontWeight(.semibold)
                .frame(width: 20, height: 20)
                .foregroundColor(buttonColors.text)
                .padding(Style.Dimensions.largeMargin * 1.5)
        }
        .glassEffect(.regular.interactive().tint(buttonColors.background))
        .disabled(isDisabled)
    }
    
    private var buttonColors: (text: Color, background: Color) {
        if value {
            return (text: Color.green, background: Color(.green).opacity(0.25))
        } else {
            return (text: Color.red, background: Color(.red).opacity(0.25))
        }
    }
}

#Preview {
    let robin = Bird(
        id: UUID(),
        name: "Robin",
        scientificName: "Erithacus rubecula",
        description: "Distinctive orange-red breast",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Robin Perched"))
        ]
    )
    let blackbird = Bird(
        id: UUID(),
        name: "Blackbird",
        scientificName: "Turdus merula",
        description: "All black with yellow bill",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Blackbird Perched"))
        ]
    )
    return TrueFalseGameView(
        correctBird: robin,
        birdImage: robin.images.first!,
        introducedBirds: Set([robin.id, blackbird.id]),
        allBirds: [robin, blackbird],
        onAnswerRevealed: { _ in },
        onComplete: { _, _ in }
    )
}

