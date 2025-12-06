//
//  ContentView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    private var navigationModel: NavigationModel = .shared
    @Environment(\.modelContext) private var modelContext
    @Query private var topics: [Topic]
    
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
        .task {
            // Seed initial data if database is empty
            if topics.isEmpty {
                do {
                    try DataLoader.seedData(into: modelContext)
                } catch {
                    print("Failed to seed data: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
