//
//  PrimaryButtonStyle.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(Style.Font.h3.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white,
                            .white.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Spacer()
        }
        .padding(Style.Dimensions.margin)
        .background {
            ZStack {
                // Base glass with accent color
                RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
                
                // Accent color gradient overlay
                RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor.opacity(0.6),
                                Color.accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                
                // Shimmer effect
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
                
                // Accent border
                RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.9),
                                Color.accentColor.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        }
        .shadow(
            color: Color.accentColor.opacity(0.4),
            radius: configuration.isPressed ? 8 : 15,
            x: 0,
            y: configuration.isPressed ? 2 : 6
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .frame(idealWidth: .infinity)
    }
}

#Preview {
    VStack {
        Spacer()
        Button(action: { }, label: { Text("Click Me") })
        Spacer()
    }
    .padding(Style.Dimensions.margin)
    .buttonStyle(PrimaryButtonStyle())
}
