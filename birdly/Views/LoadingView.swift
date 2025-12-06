//
//  LoadingView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var yOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            Color(.splashBackground)
                .ignoresSafeArea()
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                Spacer()
                
                // Animated bird icon
                ZStack {
                    // Pulsing circles for depth (ripple effect)
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.4 : 1.0)
                        .opacity(isAnimating ? 0.0 : pulseOpacity)
                    
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .opacity(isAnimating ? 0.0 : pulseOpacity)
                    
                    // Bird with gentle floating animation
                    Image("Robin")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .offset(y: yOffset)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // Loading text with fade animation
                Text("Loading...")
                    .font(Style.Font.b2)
                    .foregroundColor(.secondary)
                    .opacity(pulseOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Gentle floating animation (bird flying up and down)
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                yOffset = -15
                scale = 1.05
            }
            
            // Pulsing effect for circles and text
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
                pulseOpacity = 0.3
            }
        }
    }
}

#Preview {
    LoadingView()
}

