//
//  DiscoverView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Query(sort: \Topic.title) private var topics: [Topic]
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.flexible(), spacing: Style.Dimensions.margin),
        GridItem(.flexible(), spacing: Style.Dimensions.margin)
    ]
    
    private var filteredTopics: [Topic] {
        let validTopics = topics.filter { $0.id != Topic.dojoId }
        if searchText.isEmpty {
            return validTopics
        }
        return validTopics.filter { topic in
            topic.title.localizedCaseInsensitiveContains(searchText) ||
            topic.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var topicsInProgress: [Topic] {
        let inProgress = filteredTopics.filter { $0.progress > 0 && $0.progress < 1.0 }
        return inProgress
    }
    
    private var displayTopics: [Topic] {
        filteredTopics
    }
    
    var body: some View {
        @Bindable var nav = navigationModel
        NavigationStack(path: $nav.path) {
            ScrollView {
                VStack(spacing: Style.Dimensions.margin) {
                    // In Progress Section
                    if !topicsInProgress.isEmpty {
                        VStack(alignment: .leading, spacing: Style.Dimensions.margin) {
                            Text("In Progress")
                                .font(Style.Font.h3.weight(.semibold))
                                .padding(.horizontal, Style.Dimensions.margin)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Style.Dimensions.margin) {
                                    ForEach(topicsInProgress) { topic in
                                        InProgressTopicCard(topic: topic)
                                    }
                                }
                                .padding(.horizontal, Style.Dimensions.margin)
                            }.scrollClipDisabled()
                        }
                    }
                    
                    // All Topics Grid
                    if !displayTopics.isEmpty {
                        LazyVGrid(columns: columns, spacing: Style.Dimensions.margin) {
                            ForEach(displayTopics) { topic in
                                CategoryTileView(topic: topic)
                            }
                        }
                        .padding(Style.Dimensions.margin)
                    } else if !searchText.isEmpty {
                        // Empty state when searching
                        VStack(spacing: 16) {
                            Text("No topics found")
                                .font(Style.Font.b2)
                                .foregroundColor(.secondary)
                            Text("Try a different search term")
                                .font(Style.Font.b4)
                                .foregroundColor(.secondary)
                        }
                        .padding(Style.Dimensions.largeMargin)
                    }
                }
            }
            .navigationDestination(for: Topic.self) { topic in
                LearningView(topic: topic)
            }
            .navigationTitle("Bird Categories")
            .searchable(text: $searchText, prompt: "Search topics")
        }
    }
}

struct CategoryTileView: View {
    let topic: Topic
    
    var body: some View {
        NavigationLink(value: topic) {
            ZStack {
                BirdImageView(imageSource: topic.imageSource, contentMode: .fill)
                // Dark gradient from bottom
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.0)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Accent color glow at bottom
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
            .overlay {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: Style.Dimensions.smallMargin) {
                        Spacer(minLength: 0)
                        Text(topic.title)
                            .font(Style.Font.b2.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(topic.subtitle)
                            .font(Style.Font.b4)
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, Style.Dimensions.smallMargin)
                    .padding(.vertical, Style.Dimensions.margin)
                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
                .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
            }
        }
    }
}

struct InProgressTopicCard: View {
    let topic: Topic
    
    private var progressPercentage: Int {
        Int(topic.progress * 100)
    }
    
    var body: some View {
        NavigationLink(value: topic) {
            VStack(alignment: .leading, spacing: 0) {
                // Topic name and percentage
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(Style.Font.b2.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Text("\(progressPercentage)% complete")
                        .font(Style.Font.b4)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Style.Dimensions.margin)
                
                // Progress bar at the bottom
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar with glass effect
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.15))
                        
                        // Progress bar with accent gradient
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor,
                                        Color.accentColor.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(topic.progress))
                            .shadow(color: Color.accentColor.opacity(0.5), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, Style.Dimensions.margin)
                .padding(.bottom, Style.Dimensions.margin)
            }
            .liquidGlassCard()
            .frame(width: 200)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Topic.self, Bird.self, configurations: config)
    
    let topic1 = Topic(
        id: UUID(),
        title: "Common Garden Birds",
        subtitle: "Learn to identify the birds you see in your garden",
        imageSource: .asset(name: "bird")
    )
    let topic2 = Topic(
        id: UUID(),
        title: "Woodland Birds",
        subtitle: "Discover birds found in forests and woodlands",
        imageSource: .asset(name: "bird")
    )
    container.mainContext.insert(topic1)
    container.mainContext.insert(topic2)
    
    return DiscoverView()
        .environment(NavigationModel.shared)
        .modelContainer(container)
}
