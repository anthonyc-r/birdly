//
//  MultipleChoiceGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct MultipleChoiceGameView: View {
    let correctBird: Bird
    let birdImage: BirdImage
    let introducedBirds: Set<UUID>
    let allBirds: [Bird]
    let onAnswerRevealed: (Bool) -> Void
    let onComplete: (UUID, Bool) -> Void
    
    @State private var selectedAnswer: UUID?
    @State private var showResult = false
    @State private var wasCorrect = false
    @State private var shuffledOptions: [Bird] = []
    @State private var completionTask: Task<Void, Never>?
    
    private func setupOptions() {
        // Get a random wrong bird from introduced birds (excluding the correct one)
        let wrongOptions = allBirds.filter { 
            $0.id != correctBird.id && introducedBirds.contains($0.id)
        }
        
        // If we don't have enough introduced birds, just show the correct answer
        if let wrong = wrongOptions.randomElement() {
            shuffledOptions = [correctBird, wrong].shuffled()
        } else {
            shuffledOptions = [correctBird]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Bird image
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                .featherEffect()
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Question
                Text("What bird is this?")
                    .font(Style.Font.h1.weight(.semibold))
                    .padding(.top, Style.Dimensions.largeMargin)
                
                Spacer()
                
                // Answer options
                VStack(spacing: Style.Dimensions.margin) {
                    ForEach(shuffledOptions) { bird in
                        AnswerButton(
                            bird: bird,
                            isSelected: selectedAnswer == bird.id,
                            isCorrect: showResult && bird.id == correctBird.id,
                            isWrong: showResult && selectedAnswer == bird.id && bird.id != correctBird.id,
                            isDisabled: showResult
                        ) {
                            if !showResult {
                                selectedAnswer = bird.id
                                wasCorrect = bird.id == correctBird.id
                                
                                // Notify LearningView that answer is revealed
                                onAnswerRevealed(wasCorrect)
                                
                                withAnimation {
                                    showResult = true
                                }
                                
                                // Auto-advance after showing result
                                // Cancel any existing task first
                                completionTask?.cancel()
                                completionTask = Task {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                                    // Check if task was cancelled or view is still valid
                                    if !Task.isCancelled {
                                        onComplete(correctBird.id, wasCorrect)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Style.Dimensions.margin)
                // Result message
                Text(wasCorrect ? "Correct! ✓" : "Not quite. This is a \(correctBird.name).")
                    .font(Style.Font.b2.weight(.medium))
                    .foregroundColor(wasCorrect ? .green : .red)
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
            setupOptions()
        }
        .onDisappear {
            // Cancel any pending completion task when view disappears
            completionTask?.cancel()
            completionTask = nil
        }
    }
}

struct AnswerButton: View {
    let bird: Bird
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(bird.name)
                .font(Style.Font.h3)
                .foregroundStyle(buttonColors.text)
        }
        .buttonStyle(Style.Button.primary)
        .buttonTintColor(buttonColors.background)
        .disabled(isDisabled)
    }
    
    private var buttonColors: (text: Color, background: Color) {
        if isCorrect {
            return (Color.white, Color(.accent))
        } else if isWrong {
            return (Color.white, Color.red.opacity(0.25))
        } else if isSelected {
            return (Color.white, Color(.accent))
        }
        return (Color.primary, Color(.accent).opacity(0.25))
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
    return MultipleChoiceGameView(
        correctBird: robin,
        birdImage: robin.images.first!,
        introducedBirds: Set([robin.id, blackbird.id]),
        allBirds: [robin, blackbird],
        onAnswerRevealed: { _ in },
        onComplete: { _, _ in }
    )
}

