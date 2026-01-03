//
//  BirdLogView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

struct BirdLogView: View {
    @Query(sort: \Bird.name) private var allBirds: [Bird]
    @Query(sort: \Topic.title) private var allTopics: [Topic]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var expandedTopics: Set<UUID> = []
    
    // Filter birds that have been seen (completionPercentage > 0)
    private var seenBirds: [Bird] {
        allBirds.filter { $0.completionPercentage > 0 }
    }
    
    // Filter seen birds by search text
    private var filteredBirds: [Bird] {
        if searchText.isEmpty {
            return seenBirds
        }
        return seenBirds.filter { bird in
            bird.name.localizedCaseInsensitiveContains(searchText) ||
            bird.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Group filtered birds by topic
    private var birdsByTopic: [(Topic, [Bird])] {
        // Since birds can belong to multiple topics, we need to create pairs
        var result: [(Topic, [Bird])] = []
        
        for topic in allTopics.filter({ $0.id != Topic.dojoId }) {
            let birdsInTopic = filteredBirds.filter { bird in
                bird.topics.contains(where: { $0.id == topic.id })
            }
            if !birdsInTopic.isEmpty {
                let sortedBirds = birdsInTopic.sorted { $0.name < $1.name }
                result.append((topic, sortedBirds))
            }
        }
        
        // Sort by topic title
        return result.sorted { $0.0.title < $1.0.title }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                // Bird list
                if filteredBirds.isEmpty {
                    // Empty state
                    VStack(spacing: Style.Dimensions.margin) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty ? "No birds seen yet" : "No birds found")
                            .font(Style.Font.b2)
                            .foregroundColor(.gray)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(Style.Font.b4)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Style.Dimensions.margin) {
                            ForEach(birdsByTopic, id: \.0.id) { topic, birds in
                                Section {
                                    if expandedTopics.contains(topic.id) {
                                        ForEach(birds) { bird in
                                            BirdLogEntryView(bird: bird)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                } header: {
                                    TopicHeaderView(
                                        topic: topic,
                                        isExpanded: expandedTopics.contains(topic.id),
                                        onToggle: {
                                            toggleTopic(topic.id)
                                        },
                                        onResetMastery: {
                                            resetMasteryForTopic(topic)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(Style.Dimensions.margin)
                    }
                    .task {
                        // Initialize all topics as expanded by default on first load
                        if expandedTopics.isEmpty {
                            let topicIds = Set(birdsByTopic.map { $0.0.id })
                            expandedTopics = topicIds
                        }
                    }
                    .onChange(of: searchText) { oldValue, newValue in
                        // When searching, automatically expand topics that contain matching birds
                        if !newValue.isEmpty {
                            let matchingTopicIds = Set(birdsByTopic.map { $0.0.id })
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // Expand all topics that have matching birds
                                expandedTopics.formUnion(matchingTopicIds)
                            }
                        }
                    }
                }
            }
            .background(Color(.clear))
            .navigationTitle("Bird Log")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search birds...")
        }
    }
    
    private func toggleTopic(_ topicId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedTopics.contains(topicId) {
                expandedTopics.remove(topicId)
            } else {
                expandedTopics.insert(topicId)
            }
        }
    }
    
    private func resetMasteryForTopic(_ topic: Topic) {
        // Reset all bird images' completion percentage to 0 for all birds in this topic
        for bird in topic.birds {
            for image in bird.images {
                image.completionPercentage = 0.0
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reset mastery: \(error)")
        }
    }
}

struct BirdLogEntryView: View {
    let bird: Bird
    
    var body: some View {
        HStack(spacing: Style.Dimensions.margin) {
            // Bird image with glass border
            Group {
                if let perchedImage = bird.perchedImage {
                    BirdImageView(imageSource: perchedImage.imageSource, contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
                } else if let firstImage = bird.images.first {
                    BirdImageView(imageSource: firstImage.imageSource, contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
                } else {
                    // Fallback placeholder
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.5),
                                Color.accentColor.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Bird info and progress
            VStack(alignment: .leading, spacing: 8) {
                // Bird name
                Text(bird.name)
                    .font(Style.Font.b2.weight(.semibold))
                    .foregroundColor(.primary)
                
                // Scientific name
                Text(bird.scientificName)
                    .font(Style.Font.b4)
                    .foregroundColor(.secondary)
                    .italic()
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(Int(bird.completionPercentage))%")
                            .font(Style.Font.b4.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background with glass effect
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)
                            
                            // Progress fill with gradient
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            progressColor,
                                            progressColor.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (bird.completionPercentage / 100.0), height: 8)
                                .shadow(color: progressColor.opacity(0.5), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 8)
                }
            }
            
            Spacer()
        }
        .padding(Style.Dimensions.margin)
        .liquidGlassCard()
    }
    
    private var progressColor: Color {
        let percentage = bird.completionPercentage
        if percentage >= 80 {
            return .green
        } else if percentage >= 50 {
            return .blue
        } else if percentage >= 25 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TopicHeaderView: View {
    let topic: Topic
    let isExpanded: Bool
    let onToggle: () -> Void
    let onResetMastery: () -> Void
    @State private var showResetConfirmation = false
    
    var body: some View {
        HStack {
            // Chevron icon for expand/collapse
            Button(action: onToggle) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(topic.title)
                .font(Style.Font.b2.weight(.semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    Label("Reset Mastery", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .alert("Reset Mastery", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                onResetMastery()
            }
        } message: {
            Text("This will reset all mastery progress for birds in \"\(topic.title)\". This action cannot be undone.")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bird.self, BirdImage.self, Topic.self, configurations: config)
    
    // Create sample birds
    let bird1 = Bird(
        id: UUID(),
        name: "Robin",
        scientificName: "Erithacus rubecula",
        description: "A common garden bird",
        images: [
            BirdImage(
                id: UUID(),
                variant: "perched",
                imageSource: .asset(name: "Robin"),
                completionPercentage: 75.0
            )
        ],
        isIdentified: true
    )
    
    let bird2 = Bird(
        id: UUID(),
        name: "Blue Tit",
        scientificName: "Cyanistes caeruleus",
        description: "A small colorful bird",
        images: [
            BirdImage(
                id: UUID(),
                variant: "perched",
                imageSource: .asset(name: "Blue Tit"),
                completionPercentage: 45.0
            )
        ],
        isIdentified: true
    )
    
    container.mainContext.insert(bird1)
    container.mainContext.insert(bird2)
    
    return BirdLogView()
        .modelContainer(container)
}

