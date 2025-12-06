//
//  LearningView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

struct LearningView: View {
    let topic: Topic
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var flashcards: [Flashcard] = []
    @State private var currentCardIndex: Int = 0
    @State private var introducedBirds: Set<UUID> = []
    
    var currentCard: Flashcard? {
        guard currentCardIndex < flashcards.count else { return nil }
        return flashcards[currentCardIndex]
    }
    
    private var overallProgress: Double {
        guard !topic.birds.isEmpty else { return 0.0 }
        let totalProgress = topic.birds.reduce(0.0) { $0 + $1.completionPercentage }
        return totalProgress / Double(topic.birds.count) / 100.0 // Convert to 0.0-1.0 range
    }
    
    var body: some View {
        @Bindable var topic = topic
        ZStack {
                if let card = currentCard {
                    Group {
                        switch card.gameType {
                        case .introduction:
                            IntroductionGameView(
                                bird: card.bird,
                                birdImage: card.birdImage,
                                onComplete: handleCardComplete
                            )
                            .id("intro-\(currentCardIndex)-\(card.bird.id)-\(card.birdImage.id)")
                        case .multipleChoice:
                            MultipleChoiceGameView(
                                correctBird: card.bird,
                                birdImage: card.birdImage,
                                introducedBirds: introducedBirds,
                                allBirds: topic.birds,
                                onComplete: handleCardComplete
                            )
                            .id("mc-\(currentCardIndex)-\(card.bird.id)-\(card.birdImage.id)")
                        case .wordSearch:
                            WordSearchGameView(
                                bird: card.bird,
                                birdImage: card.birdImage,
                                onComplete: handleCardComplete
                            )
                            .id("ws-\(currentCardIndex)-\(card.bird.id)-\(card.birdImage.id)")
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 4) {
                    // Progress percentage
                    Text("\(Int(overallProgress * 100))%")
                        .font(Style.Font.b3.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.accentColor)
                                .frame(width: geometry.size.width * overallProgress, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: overallProgress)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 200)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupFlashcards()
        }
    }
    
    private func setupFlashcards() {
        var cards: [Flashcard] = []
        
        // Use the topic directly (SwiftData will keep it updated)
        let currentTopic = topic
        
        // Count how many birds have been introduced (completion > 0)
        let introducedCount = currentTopic.birds.filter { $0.completionPercentage > 0 }.count
        let canPlayMultipleChoice = introducedCount >= 2
        
        // Track which birds have been introduced
        introducedBirds = Set(currentTopic.birds.filter { $0.completionPercentage > 0 }.map { $0.id })
        
        // Separate birds into categories
        let introducedBirdsList = currentTopic.birds.filter { $0.completionPercentage > 0 }
        let newBirds = currentTopic.birds.filter { $0.completionPercentage == 0 }
        
        // Add practice games for introduced birds, weighted by mastery level
        // Higher mastery = more word search, lower mastery = more multiple choice
        // Now selects both image variant and game type based on per-image mastery
        if canPlayMultipleChoice {
            for bird in introducedBirdsList {
                if let (image, gameType) = bird.selectImageAndGameType() {
                    cards.append(Flashcard(bird: bird, birdImage: image, gameType: gameType))
                }
            }
        }
        
        // Gradually introduce new birds
        // Introduce 1-2 new birds at a time, prioritizing based on progress
        // If we have few introduced birds, introduce more aggressively
        let newBirdsToIntroduce: Int
        if introducedCount == 0 {
            // First time: introduce 2 birds
            newBirdsToIntroduce = min(2, newBirds.count)
        } else if introducedCount < 4 {
            // Early stage: introduce 1-2 new birds
            newBirdsToIntroduce = min(2, newBirds.count)
        } else {
            // Later stage: introduce 1 new bird at a time
            newBirdsToIntroduce = min(1, newBirds.count)
        }
        
        // Add introduction games for new birds to introduce
        // Introduction always uses the perched image (primary) and only shows once per bird
        for (index, bird) in newBirds.prefix(newBirdsToIntroduce).enumerated() {
            if let perchedImage = bird.perchedImage ?? bird.images.first {
                cards.append(Flashcard(bird: bird, birdImage: perchedImage, gameType: .introduction))
            }
        }
        
        // Shuffle the deck, but prioritize new introductions first
        let introductionCards = cards.filter { $0.gameType == .introduction }
        let practiceCards = cards.filter { $0.gameType == .multipleChoice || $0.gameType == .wordSearch }
        flashcards = introductionCards + practiceCards.shuffled()
        currentCardIndex = 0
    }
    
    private func handleCardComplete(birdId: UUID, wasCorrect: Bool) {
        // Find the bird in the topic
        guard let bird = topic.birds.first(where: { $0.id == birdId }) else { return }
        
        if let card = currentCard {
            let image = card.birdImage
            
            switch card.gameType {
            case .introduction:
                // Introduction game: set initial completion for the image (marks as introduced)
                image.completionPercentage = 5.0
                introducedBirds.insert(birdId)
                
            case .multipleChoice:
                // Multiple choice: increase/decrease based on correctness (per-image mastery)
                if wasCorrect {
                    // Correct answer: increase by 10-15%, cap at 100%
                    let increase = Double.random(in: 10...15)
                    image.completionPercentage = min(100.0, image.completionPercentage + increase)
                } else {
                    // Wrong answer: decrease by 5%, but don't go below 1%
                    image.completionPercentage = max(1.0, image.completionPercentage - 5.0)
                }
            case .wordSearch:
                // Word search: increase/decrease based on correctness (per-image mastery)
                if wasCorrect {
                    // Correct answer: increase by 12-18%, cap at 100%
                    let increase = Double.random(in: 12...18)
                    image.completionPercentage = min(100.0, image.completionPercentage + increase)
                } else {
                    // Wrong answer: decrease by 3%, but don't go below 1%
                    image.completionPercentage = max(1.0, image.completionPercentage - 3.0)
                }
            }
        }
        
        // Force SwiftData to save and notify observers immediately
        // This ensures the progress bar updates in real-time
        do {
            try modelContext.save()
        } catch {
            print("Failed to save progress: \(error)")
        }
        
        // Move to next card
        withAnimation {
            if currentCardIndex < flashcards.count - 1 {
                currentCardIndex += 1
            } else {
                // All cards completed - refresh to potentially add more cards
                setupFlashcards()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Topic.self, Bird.self, configurations: config)
    
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
                imageSource: .asset(name: "robin")
            )
        ]
    )
    container.mainContext.insert(topic)
    
    return LearningView(topic: topic)
        .modelContainer(container)
}

