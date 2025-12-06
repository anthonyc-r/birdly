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
            Text("Discover the world of birds")
                .font(Style.Font.h1.weight(.bold))
                .multilineTextAlignment(.leading)
            Text("Your pocket guide to the birds around you.")
                .font(Style.Font.b1.weight(.medium))
                .multilineTextAlignment(.leading)
            Button(action: {
                withAnimation {
                    navigationModel.hasSeenSplash.toggle()
                }
            }, label: {
                Text("Get Started")
            })
        }
        .padding(Style.Dimensions.margin)
        .padding(.top, Style.Dimensions.largeMargin)
        .background(ZStack {
            VStack {
                Image(.splash)
                Spacer()
            }
            .ignoresSafeArea()
        })
        .buttonStyle(Style.Button.primary)
        .background(Color(.splashBackground))
    }
}


#Preview {
    SplashView()
        .environment(NavigationModel.shared)
}
