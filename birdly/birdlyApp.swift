//
//  birdlyApp.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

@main
struct birdlyApp: App {
    @State private var dataModel: DataModel = {
        do {
            return try DataLoader.loadData()
        } catch {
            // Fallback to empty model if loading fails
            print("Failed to load data: \(error)")
            return DataModel()
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataModel)
        }
    }
}
