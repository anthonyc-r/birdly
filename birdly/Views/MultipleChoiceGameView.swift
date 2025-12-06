//
//  MultipleChoiceGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct MultipleChoiceGameView: View {
    let correctBird: Bird
    let introducedBirds: Set<UUID>
    let allBirds: [Bird]
    let onComplete: (UUID, Bool) -> Void
    
    @State private var selectedAnswer: UUID?
    @State private var showResult = false
    @State private var wasCorrect = false
    
    private var wrongBird: Bird? {
        // Get a random wrong bird from introduced birds (excluding the correct one)
        let wrongOptions = allBirds.filter { 
            $0.id != correctBird.id && introducedBirds.contains($0.id)
        }
        return wrongOptions.randomElement()
    }
    
    private var shuffledOptions: [Bird] {
        // If we don't have enough introduced birds, just show the correct answer
        guard let wrong = wrongBird else {
            return [correctBird]
        }
        return [correctBird, wrong].shuffled()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Question
                Text("What bird is this?")
                    .font(Style.Font.h2.weight(.semibold))
                    .padding(.top, Style.Dimensions.largeMargin)
                
                // Bird image
                BirdImageView(imageSource: correctBird.imageSource, contentMode: .fit)
                    .frame(maxHeight: 300)
                    .padding(Style.Dimensions.margin)
                
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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    onComplete(correctBird.id, wasCorrect)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Style.Dimensions.margin)
                
                // Result message
                if showResult {
                    Text(wasCorrect ? "Correct! ✓" : "Not quite. This is a \(correctBird.name)")
                        .font(Style.Font.b2)
                        .foregroundColor(wasCorrect ? .green : .red)
                        .padding(.top, Style.Dimensions.margin)
                        .transition(.opacity)
                }
            }
            .padding(Style.Dimensions.margin)
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
                    .foregroundColor(buttonTextColor)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(Style.Dimensions.margin)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.2)
        } else if isWrong {
            return Color.red.opacity(0.2)
        } else if isSelected {
            return Color.accentColor.opacity(0.1)
        }
        return Color.gray.opacity(0.1)
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return .accentColor
        }
        return .gray.opacity(0.3)
    }
    
    private var buttonTextColor: Color {
        if isCorrect || isWrong {
            return .primary
        }
        return .primary
    }
}

#Preview {
    MultipleChoiceGameView(
        correctBird: Bird(
            id: UUID(),
            name: "Robin",
            scientificName: "Erithacus rubecula",
            description: "Distinctive orange-red breast",
            imageSource: .asset(name: "robin")
        ),
        introducedBirds: Set([UUID()]),
        allBirds: [
            Bird(
                id: UUID(),
                name: "Robin",
                scientificName: "Erithacus rubecula",
                description: "Distinctive orange-red breast",
                imageSource: .asset(name: "robin")
            ),
            Bird(
                id: UUID(),
                name: "Blackbird",
                scientificName: "Turdus merula",
                description: "All black with yellow bill",
                imageSource: .asset(name: "blackbird")
            )
        ],
        onComplete: { _, _ in }
    )
}

