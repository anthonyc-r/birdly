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
    var progress: Double
    
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
    
    init(id: UUID, title: String, subtitle: String, progress: Double, imageSource: ImageSource, birds: [Bird] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.imageSource = imageSource
        self.birds = birds
        // Set reverse relationship
        for bird in birds {
            bird.topic = self
        }
    }
}
