//
//  Topic.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

@Model
final class Topic {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    
    // Computed property: average progress of all birds in this topic (0.0 to 1.0)
    var progress: Double {
        guard !birds.isEmpty else { return 0.0 }
        let totalProgress = birds.reduce(0.0) { $0 + $1.completionPercentage }
        return (totalProgress / Double(birds.count)) / 100.0 // Convert from 0-100 to 0.0-1.0
    }
    
    // Store ImageSource as JSON data for SwiftData compatibility
    private var imageSourceData: Data?
    
    var imageSource: ImageSource {
        get {
            guard let data = imageSourceData,
                  let decoded = try? JSONDecoder().decode(ImageSource.self, from: data) else {
                return .asset(name: "bird")
            }
            return decoded
        }
        set {
            imageSourceData = try? JSONEncoder().encode(newValue)
        }
    }
    
    @Relationship(deleteRule: .cascade) var birds: [Bird] = []
    
    init(id: UUID, title: String, subtitle: String, imageSource: ImageSource, birds: [Bird] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageSource = imageSource
        self.birds = birds
        // Set reverse relationship
        for bird in birds {
            bird.topic = self
        }
    }
}
