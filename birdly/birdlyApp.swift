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
        .modelContainer(for: [Topic.self, Bird.self, BirdImage.self, User.self])
    }
}
