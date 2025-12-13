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
        VStack(spacing: Style.Dimensions.largeMargin) {
            // Bird image
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Question
                Text("What bird is this?")
                    .font(Style.Font.h2.weight(.semibold))
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
                Text(wasCorrect ? "Correct! ✓" : "Not quite. This is a \(correctBird.name)")
                    .font(Style.Font.b2)
                    .foregroundColor(wasCorrect ? .green : .red)
                    .padding(.top, Style.Dimensions.margin)
                    .transition(.opacity)
                    .opacity(showResult ? 1.0 : 0.0)
            }
            .padding(Style.Dimensions.margin)
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
            HStack {
                Text(bird.name)
                    .font(Style.Font.b2.weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                buttonTextColor,
                                buttonTextColor.opacity(0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .green,
                                    .green.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .red,
                                    .red.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(Style.Dimensions.margin)
            .background {
                ZStack {
                    // Base glass background with higher opacity
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
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.25)
        } else if isWrong {
            return Color.red.opacity(0.25)
        } else if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return Color.clear
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
    
    private var buttonTextColor: Color {
        if isCorrect || isWrong {
            return .primary
        }
        return .primary
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
        introducedBirds: Set([robin.id]),
        allBirds: [robin, blackbird],
        onComplete: { _, _ in }
    )
}

