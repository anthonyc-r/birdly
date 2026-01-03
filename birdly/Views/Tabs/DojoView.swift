//
//  DojoView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

struct DojoView: View {
    @State private var currentImageIndex = 0
    @State private var isVisible = false
    @State private var transitionTask: Task<Void, Never>?
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Topic.title) private var topics: [Topic]
    
    private var dojoTopic: Topic? {
        topics.first { $0.id == Topic.dojoId }
    }
    
    private var allBirds: Set<Bird> {
        // Get all unique birds from all topics
        return Set(topics.flatMap { $0.birds }.filter { $0.isIntroduced })
    }
    
    private var allBirdImages: [BirdImage] {
        return allBirds.compactMap { bird -> BirdImage? in
            // Prefer perched image, fallback to first image
            return bird.perchedImage ?? bird.images.first
        }
    }
    
    private var currentImage: BirdImage? {
        guard !allBirdImages.isEmpty else { return nil }
        return allBirdImages[currentImageIndex % allBirdImages.count]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Style.Dimensions.largeMargin) {
                Spacer()
                
                VStack(spacing: Style.Dimensions.margin) {
                    Text("Dojo")
                        .font(Style.Font.h1.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Practice and master your bird identification skills")
                        .font(Style.Font.b3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Style.Dimensions.largeMargin)
                }
                Spacer()
                
                if let dojoTopic = dojoTopic {
                    NavigationLink(value: dojoTopic) {
                        Text("Start")
                            .font(Style.Font.b2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Style.Button.primary)
                    .padding(.horizontal, Style.Dimensions.largeMargin)
                } else {
                    Button(action: {
                        FeedbackManager.shared.playSelectionFeedback()
                    }) {
                        Text("Start")
                            .font(Style.Font.b2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Style.Button.primary)
                    .padding(.horizontal, Style.Dimensions.largeMargin)
                    .disabled(true)
                }
                
                Spacer()
            }
            .navigationDestination(for: Topic.self) { topic in
                LearningView(topic: topic)
            }
            .padding(Style.Dimensions.margin)
            .background {
                // Animated background with transitioning bird images
                if !allBirdImages.isEmpty, let currentImage = currentImage {
                    BirdImageView(imageSource: currentImage.imageSource, contentMode: .fill)
                        .ignoresSafeArea()
                        .overlay(Material.thin)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 1.0), value: currentImageIndex)
                        .id(currentImage.id)
                } else {
                    // Fallback background if no images available
                    Color.accentColor.opacity(0.1)
                        .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            isVisible = true
            startImageTransition()
            updateDojoTopic()
        }
        .onDisappear {
            isVisible = false
            transitionTask?.cancel()
            transitionTask = nil
        }
    }
    
    private func updateDojoTopic() {
        let birds = allBirds
        guard !birds.isEmpty else {
            return
        }
        
        if let topic = (try? modelContext.fetch(FetchDescriptor<Topic>()))?.filter({ $0.id == Topic.dojoId }).first {
            topic.birds = Array(birds)
        } else {
            let topic = Topic(
                id: Topic.dojoId,
                title: "Dojo",
                subtitle: "Practice with all known birds",
                imageSource: .asset(name: "bird"),
                birds: Array(birds)
            )
            modelContext.insert(topic)
        }
        try? modelContext.save()
    }
    
    private func startImageTransition() {
        guard !allBirdImages.isEmpty, allBirdImages.count > 1 else { return }
        
        // Cancel any existing transition task
        transitionTask?.cancel()
        
        // Start a new transition task
        transitionTask = Task {
            while !Task.isCancelled && isVisible {
                try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
                
                guard !Task.isCancelled && isVisible else { break }
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        currentImageIndex = (currentImageIndex + 1) % allBirdImages.count
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Topic.self, Bird.self, BirdImage.self, configurations: config)
    
    let bird1 = Bird(
        id: UUID(),
        name: "Robin",
        scientificName: "Erithacus rubecula",
        description: "Distinctive orange-red breast",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Robin Perched"))
        ]
    )
    
    let bird2 = Bird(
        id: UUID(),
        name: "Blackbird",
        scientificName: "Turdus merula",
        description: "Males are all black with a bright yellow-orange bill",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Blackbird Perched"))
        ]
    )
    
    let topic = Topic(
        id: Topic.dojoId,
        title: "Common Garden Birds",
        subtitle: "Learn to identify the birds you see in your garden",
        imageSource: .asset(name: "bird"),
        birds: [bird1, bird2]
    )
    container.mainContext.insert(topic)
    
    return DojoView()
        .modelContainer(container)
}

