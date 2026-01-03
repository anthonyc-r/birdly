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
    static let dojoId = UUID(uuidString: "B1119204-075D-4694-840F-11AB7B5A3C0C")!
    
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    @Relationship(deleteRule: .nullify, inverse: \Bird.topics) var birds: [Bird] = []
    
    @Transient var currentSession: TopicSession?

    
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
        
    init(id: UUID, title: String, subtitle: String, imageSource: ImageSource, birds: [Bird] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageSource = imageSource
        self.birds = birds
        // Set reverse relationship for many-to-many
        for bird in birds {
            if !bird.topics.contains(where: { $0.id == self.id }) {
                bird.topics.append(self)
            }
        }
    }
    
    /// Creates a new TopicSession for this topic
    @MainActor
    func createSession() -> TopicSession {
        let session = currentSession ?? TopicSession(topic: self)
        if currentSession == nil {
            currentSession = session
        }
        return session
    }
}
