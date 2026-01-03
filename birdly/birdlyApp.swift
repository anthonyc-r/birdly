//
//  birdlyApp.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import UIKit
import SwiftUI
import SwiftData

@main
struct birdlyApp: App {
    init() {
        // Preload audio files by initializing the FeedbackManager singleton
        _ = FeedbackManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        // Use a new database URL to avoid schema conflicts with the old one-to-many relationship
        // This creates a fresh database with the new many-to-many schema
        let schema = Schema([
            Topic.self,
            Bird.self,
            BirdImage.self,
            User.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: getDatabaseURL(),
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func getDatabaseURL() -> URL {
        // Use a new database name to avoid conflicts with the old schema
        // Version 2 database (many-to-many relationship)
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return url.appendingPathComponent("default_v2.store")
    }
}
