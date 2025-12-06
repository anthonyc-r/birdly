//
//  DiscoverView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct DiscoverView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DataModel.self) private var dataModel
    
    private let columns = [
        GridItem(.flexible(), spacing: Style.Dimensions.margin),
        GridItem(.flexible(), spacing: Style.Dimensions.margin)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Style.Dimensions.margin) {
                    ForEach(dataModel.topics, id: \.id) { topic in
                        CategoryTileView(topic: topic)
                    }
                }
                .padding(Style.Dimensions.margin)
            }
            .navigationTitle("Bird Categories")
        }
    }
}

struct CategoryTileView: View {
    let topic: Topic
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background image
                BirdImageView(imageSource: topic.imageSource, contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Black to transparent gradient overlay from bottom
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.0)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Text overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(Style.Font.b2.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(topic.subtitle)
                        .font(Style.Font.b4)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Style.Dimensions.margin)
            }
            .clipShape(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    let dataModel = DataModel()
    dataModel.topics = [
        Topic(
            id: UUID(),
            title: "Common Garden Birds",
            subtitle: "Learn to identify the birds you see in your garden",
            progress: 0.0,
            imageSource: .asset(name: "bird")
        ),
        Topic(
            id: UUID(),
            title: "Woodland Birds",
            subtitle: "Discover birds found in forests and woodlands",
            progress: 0.3,
            imageSource: .asset(name: "bird")
        )
    ]
    
    return DiscoverView()
        .environment(NavigationModel.shared)
        .environment(dataModel)
}
