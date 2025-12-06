//
//  Topic.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct Topic: Codable {
    var id: UUID
    var title: String
    var subtitle: String
    var progress: Double
    var imageSource: ImageSource
    var birds: [Bird] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case progress
        case imageSource
        case imageName // For backward compatibility
        case birds
    }
    
    init(id: UUID, title: String, subtitle: String, progress: Double, imageSource: ImageSource, birds: [Bird] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.imageSource = imageSource
        self.birds = birds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        progress = try container.decode(Double.self, forKey: .progress)
        birds = try container.decodeIfPresent([Bird].self, forKey: .birds) ?? []
        
        // Support both new format (imageSource) and old format (imageName) for backward compatibility
        if let imageSource = try? container.decode(ImageSource.self, forKey: .imageSource) {
            self.imageSource = imageSource
        } else if let imageName = try? container.decode(String.self, forKey: .imageName) {
            // Convert old imageName format to ImageSource
            self.imageSource = .asset(name: imageName)
        } else {
            // Default fallback
            self.imageSource = .asset(name: "bird")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(progress, forKey: .progress)
        try container.encode(imageSource, forKey: .imageSource)
        try container.encode(birds, forKey: .birds)
    }
}
