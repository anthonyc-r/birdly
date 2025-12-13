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
                        label: "True",
                        isSelected: selectedAnswer == true,
                        isCorrect: showResult && wasCorrect && selectedAnswer == true,
                        isWrong: showResult && !wasCorrect && selectedAnswer == true,
                        isDisabled: showResult
                    ) {
                        selectAnswer(true)
                    }
                    
                    TrueFalseButton(
                        label: "False",
                        isSelected: selectedAnswer == false,
                        isCorrect: showResult && wasCorrect && selectedAnswer == false,
                        isWrong: showResult && !wasCorrect && selectedAnswer == false,
                        isDisabled: showResult
                    ) {
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
    let label: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Style.Font.h3.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background {
                    ZStack {
                        // Base glass background
                        RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.85)
                        
                        // State-based color gradient overlay
                        RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: stateGradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(stateGradientOpacity)
                        
                        // Shimmer effect for selected/correct/wrong states
                        if isSelected || isCorrect || isWrong {
                            RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.9),
                                    borderColor.opacity(0.5),
                                    borderColor.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected || isCorrect || isWrong ? 2.5 : 2
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
                .shadow(
                    color: borderColor.opacity(isSelected || isCorrect || isWrong ? 0.5 : 0.3),
                    radius: isSelected || isCorrect || isWrong ? 12 : 6,
                    x: 0,
                    y: isSelected || isCorrect || isWrong ? 4 : 2
                )
        }
        .disabled(isDisabled)
    }
    
    private var stateGradientColors: [Color] {
        if isCorrect {
            return [
                Color.green.opacity(0.4),
                Color.green.opacity(0.2),
                Color.green.opacity(0.1)
            ]
        } else if isWrong {
            return [
                Color.red.opacity(0.4),
                Color.red.opacity(0.2),
                Color.red.opacity(0.1)
            ]
        } else if isSelected {
            return [
                Color.accentColor.opacity(0.5),
                Color.accentColor.opacity(0.3),
                Color.accentColor.opacity(0.2)
            ]
        }
        return [
            Color.accentColor.opacity(0.15),
            Color.accentColor.opacity(0.08),
            Color.accentColor.opacity(0.05)
        ]
    }
    
    private var stateGradientOpacity: Double {
        if isCorrect || isWrong || isSelected {
            return 1.0
        }
        return 0.6
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return .accentColor
        }
        return Color.accentColor.opacity(0.5)
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
        onComplete: { _, _ in }
    )
}

