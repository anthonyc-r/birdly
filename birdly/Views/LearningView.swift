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
    
    @ObservedObject private var session: TopicSession
    
    init(topic: Topic) {
        self.topic = topic
        session = topic.createSession()
    }
    
    private var currentGameId: String {
        guard let game = session.currentGameInfo else {
            return "completed"
        }
        return "\(game.gameType)-\(game.bird.id)-\(game.birdImage.id)"
    }
    
    var body: some View {
        @Bindable var topic = topic
        ZStack {
            if let game = session.currentGameInfo {
                Group {
                    switch game.gameType {
                    case .introduction:
                        IntroductionGameView(
                            bird: game.bird,
                            birdImage: game.birdImage,
                            onComplete: handleCardComplete
                        )
                        .id("intro-\(game.bird.id)-\(game.birdImage.id)")
                    case .multipleChoice:
                        MultipleChoiceGameView(
                            correctBird: game.bird,
                            birdImage: game.birdImage,
                            introducedBirds: introducedBirds,
                            allBirds: topic.birds,
                            onComplete: handleCardComplete
                        )
                        .id("mc-\(game.bird.id)-\(game.birdImage.id)")
                    case .wordSearch:
                        WordSearchGameView(
                            bird: game.bird,
                            birdImage: game.birdImage,
                            onComplete: handleCardComplete
                        )
                        .id("ws-\(game.bird.id)-\(game.birdImage.id)")
                    case .letterSelection:
                        LetterSelectionGameView(
                            bird: game.bird,
                            birdImage: game.birdImage,
                            onComplete: handleCardComplete
                        )
                        .id("ls-\(game.bird.id)-\(game.birdImage.id)")
                    case .trueFalse:
                        TrueFalseGameView(
                            correctBird: game.bird,
                            birdImage: game.birdImage,
                            introducedBirds: introducedBirds,
                            allBirds: topic.birds,
                            onComplete: handleCardComplete
                        )
                        .id("tf-\(game.bird.id)-\(game.birdImage.id)")
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
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
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentGameId)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 4) {
                    // Progress percentage
                    Text("\(Int(topic.progress * 100))%")
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
                                .frame(width: geometry.size.width * topic.progress, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: topic.progress)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 200)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var introducedBirds: Set<UUID> {
        return Set(topic.birds.filter { $0.isIntroduced }.map { $0.id })
    }
    
    private func handleCardComplete(birdId: UUID, wasCorrect: Bool) {
        session.handleCardCompletion(birdId: birdId, wasCorrect: wasCorrect, modelContext: modelContext)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Topic.self, Bird.self, configurations: config)
    
    let topic = Topic(
        id: UUID(),
        title: "Common Garden Birds",
        subtitle: "Learn to identify the birds you see in your garden",
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

