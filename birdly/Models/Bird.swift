//
//  Bird.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct Bird: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var scientificName: String
    var description: String
    var imageSource: ImageSource
    var isIdentified: Bool = false
    var hasBeenIntroduced: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case scientificName
        case description
        case imageSource
        case imageName // For backward compatibility
        case isIdentified
        case hasBeenIntroduced
    }
    
    init(id: UUID, name: String, scientificName: String, description: String, imageSource: ImageSource, isIdentified: Bool = false, hasBeenIntroduced: Bool = false) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.description = description
        self.imageSource = imageSource
        self.isIdentified = isIdentified
        self.hasBeenIntroduced = hasBeenIntroduced
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        scientificName = try container.decode(String.self, forKey: .scientificName)
        description = try container.decode(String.self, forKey: .description)
        isIdentified = try container.decodeIfPresent(Bool.self, forKey: .isIdentified) ?? false
        hasBeenIntroduced = try container.decodeIfPresent(Bool.self, forKey: .hasBeenIntroduced) ?? false
        
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
        try container.encode(name, forKey: .name)
        try container.encode(scientificName, forKey: .scientificName)
        try container.encode(description, forKey: .description)
        try container.encode(imageSource, forKey: .imageSource)
        try container.encode(isIdentified, forKey: .isIdentified)
        try container.encode(hasBeenIntroduced, forKey: .hasBeenIntroduced)
    }
}

