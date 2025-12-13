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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Topic.self, Bird.self, BirdImage.self, User.self])
    }
}
