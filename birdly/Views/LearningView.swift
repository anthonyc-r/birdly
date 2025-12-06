//
//  LearningView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct LearningView: View {
    let topic: Topic
    @Environment(DataModel.self) private var dataModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var flashcards: [Flashcard] = []
    @State private var currentCardIndex: Int = 0
    @State private var introducedBirds: Set<UUID> = []
    
    var currentCard: Flashcard? {
        guard currentCardIndex < flashcards.count else { return nil }
        return flashcards[currentCardIndex]
    }
    
    var body: some View {
        ZStack {
            if let card = currentCard {
                Group {
                    switch card.gameType {
                    case .introduction:
                        IntroductionGameView(
                            bird: card.bird,
                            onComplete: handleCardComplete
                        )
                    case .multipleChoice:
                        MultipleChoiceGameView(
                            correctBird: card.bird,
                            introducedBirds: introducedBirds,
                            allBirds: topic.birds,
                            onComplete: handleCardComplete
                        )
                    }
                }
            } else {
                // All cards completed
                VStack(spacing: Style.Dimensions.largeMargin) {
                    Text("Great job!")
                        .font(Style.Font.h1.weight(.bold))
                    Text("You've completed this learning session")
                        .font(Style.Font.b2)
                        .foregroundColor(.secondary)
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(Style.Button.primary)
                }
                .padding(Style.Dimensions.margin)
            }
        }
        .onAppear {
            setupFlashcards()
        }
    }
    
    private func setupFlashcards() {
        var cards: [Flashcard] = []
        
        // Create flashcards based on mastery
        for bird in topic.birds {
            if !bird.hasBeenIntroduced {
                // New bird - introduction game
                cards.append(Flashcard(bird: bird, gameType: .introduction))
            } else {
                // Introduced bird - multiple choice quiz
                cards.append(Flashcard(bird: bird, gameType: .multipleChoice))
            }
        }
        
        // Shuffle the deck
        flashcards = cards.shuffled()
        currentCardIndex = 0
        
        // Track which birds have been introduced
        introducedBirds = Set(topic.birds.filter { $0.hasBeenIntroduced }.map { $0.id })
    }
    
    private func handleCardComplete(birdId: UUID, wasCorrect: Bool) {
        // Mark bird as introduced if it was an introduction game
        if let card = currentCard, card.gameType == .introduction {
            introducedBirds.insert(birdId)
            
            // Update the bird in the data model
            if let topicIndex = dataModel.topics.firstIndex(where: { $0.id == topic.id }),
               let birdIndex = dataModel.topics[topicIndex].birds.firstIndex(where: { $0.id == birdId }) {
                dataModel.topics[topicIndex].birds[birdIndex].hasBeenIntroduced = true
            }
        }
        
        // Move to next card
        withAnimation {
            if currentCardIndex < flashcards.count - 1 {
                currentCardIndex += 1
            } else {
                // All cards completed
                currentCardIndex = flashcards.count
            }
        }
    }
}

#Preview {
    let topic = Topic(
        id: UUID(),
        title: "Common Garden Birds",
        subtitle: "Learn to identify the birds you see in your garden",
        progress: 0.0,
        imageSource: .asset(name: "bird"),
        birds: [
            Bird(
                id: UUID(),
                name: "Robin",
                scientificName: "Erithacus rubecula",
                description: "Distinctive orange-red breast",
                imageSource: .asset(name: "robin"),
                hasBeenIntroduced: false
            )
        ]
    )
    
    return LearningView(topic: topic)
        .environment(DataModel())
}

