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
    @Query private var allUsers: [User]
    @State private var isInitializing = true
    
    private var user: User? {
        allUsers.first { $0.id == User.singletonId }
    }
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        
        Group {
            if isInitializing {
                LoadingView()
                    .transition(.opacity)
            } else if !navigationModel.hasSeenSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                MenuView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isInitializing)
        .animation(.easeInOut(duration: 0.3), value: navigationModel.hasSeenSplash)
        .environment(navigationModel)
        .task {
            // Initialize data before showing main content
            await initializeApp()
        }
        .onChange(of: navigationModel.hasSeenSplash) { oldValue, newValue in
            // Save user data when splash screen state changes
            saveUser(hasSeenSplash: newValue)
        }
    }
    
    private func initializeApp() async {
        let startTime = Date()
        
        // Small delay to ensure SwiftData queries are ready
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Load user data
        loadUser()
        
        // Seed initial data if database is empty
        if topics.isEmpty {
            do {
                try DataLoader.seedData(into: modelContext)
            } catch {
                print("Failed to seed data: \(error)")
            }
        }
        
        // Ensure loading screen shows for at least 2 seconds
        let elapsedTime = Date().timeIntervalSince(startTime)
        let minimumDisplayTime: TimeInterval = 2.0
        if elapsedTime < minimumDisplayTime {
            let remainingTime = minimumDisplayTime - elapsedTime
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        // Mark initialization as complete
        isInitializing = false
    }
    
    private func loadUser() {
        if let user = user {
            navigationModel.hasSeenSplash = user.hasSeenSplash
        } else {
            // Create default user if none exists
            let newUser = User(id: User.singletonId, hasSeenSplash: false)
            modelContext.insert(newUser)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save default user: \(error)")
            }
        }
    }
    
    private func saveUser(hasSeenSplash: Bool) {
        let currentUser: User
        if let existing = user {
            currentUser = existing
        } else {
            currentUser = User(id: User.singletonId, hasSeenSplash: hasSeenSplash)
            modelContext.insert(currentUser)
        }
        
        currentUser.hasSeenSplash = hasSeenSplash
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
