//
//  LoadingView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import Lottie

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.splashBackground)
                .ignoresSafeArea()
            
            VStack(spacing: Style.Dimensions.largeMargin) {
                Spacer()
                
                // Lottie animation
                LottieView(animation: .named("Happy Bird"))
                    .playing(loopMode: .loop)
                    .animationSpeed(1.0)
                    .frame(width: 200, height: 200)
                
                // Loading text
                Text("Loading...")
                    .font(Style.Font.b2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

#Preview {
    LoadingView()
}

