//
//  ContentView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct ContentView: View {
    private var navigationModel: NavigationModel = .shared
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        
        
        Group {
            if !navigationModel.hasSeenSplash {
                SplashView()
            } else {
                MenuView()
            }
        }
        .environment(navigationModel)
    }
}

#Preview {
    ContentView()
}
