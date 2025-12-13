//
//  SplashView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct SplashView: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    var body: some View {
        VStack(spacing: Style.Dimensions.largeMargin) {
            Spacer()
            
            // Text content with glass effect background
            VStack(alignment: .leading, spacing: 12) {
                Text("Discover the world of birds")
                    .font(Style.Font.h1.weight(.bold))
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
                    .multilineTextAlignment(.leading)
                
                Text("Your pocket guide to the birds around you.")
                    .font(Style.Font.h3.weight(.medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.leading)
            }
            .padding(Style.Dimensions.largeMargin)
            .liquidGlassCard()
            .padding(.horizontal, Style.Dimensions.margin)
            
            Button(action: {
                withAnimation {
                    navigationModel.hasSeenSplash.toggle()
                }
            }, label: {
                Text("Get Started")
            })
            .padding(.horizontal, Style.Dimensions.margin)
        }
        .padding(.top, Style.Dimensions.largeMargin)
        .padding(.bottom, Style.Dimensions.margin)
        .background(ZStack {
            VStack {
                Image(.splash)
                Spacer()
            }
            .ignoresSafeArea()
        })
        .buttonStyle(Style.Button.primary)
        .background(Color(.accent))
    }
}


#Preview {
    SplashView()
        .environment(NavigationModel.shared)
}
