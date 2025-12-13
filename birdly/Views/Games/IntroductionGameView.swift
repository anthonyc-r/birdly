//
//  IntroductionGameView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct IntroductionGameView: View {
    let bird: Bird
    let birdImage: BirdImage
    let onComplete: (UUID, Bool) -> Void
    
    @State private var showDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Style.Dimensions.largeMargin) {
                // Bird image
                BirdImageView(imageSource: birdImage.imageSource, contentMode: .fit)
                    .featherEffect()
                
                VStack(spacing: Style.Dimensions.margin) {
                    // Bird name
                    Text(bird.name)
                        .font(Style.Font.h1.weight(.bold))
                        .multilineTextAlignment(.center)
                    
                    // Scientific name
                    Text(bird.scientificName)
                        .font(Style.Font.b3)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    // Description
                    if showDetails {
                        Text(bird.birdDescription)
                            .font(Style.Font.b3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Style.Dimensions.margin)
                            .transition(.opacity)
                    }
                    
                    // Continue button
                    Button(action: {
                        if !showDetails {
                            withAnimation {
                                showDetails = true
                            }
                        } else {
                            onComplete(bird.id, true)
                        }
                    }) {
                        Text(showDetails ? "Continue" : "Learn More")
                    }
                    .buttonStyle(Style.Button.primary)
                    .padding(.top, Style.Dimensions.margin)
                }
                .padding(Style.Dimensions.margin)
            }
        }
        .background {
            BirdImageView(imageSource: birdImage.imageSource, contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Material.thin)
        }
    }
}

#Preview {
    let bird = Bird(
        id: UUID(),
        name: "Robin",
        scientificName: "Erithacus rubecula",
        description: "Distinctive orange-red breast and face, with brown upperparts. Often seen perched on garden fences and feeders.",
        images: [
            BirdImage(id: UUID(), variant: "perched", imageSource: .asset(name: "Robin Perched"))
        ]
    )
    return IntroductionGameView(
        bird: bird,
        birdImage: bird.images.first!,
        onComplete: { _, _ in }
    )
}

