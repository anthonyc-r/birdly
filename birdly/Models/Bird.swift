//
//  Bird.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

@Model
final class Bird {
    @Attribute(.unique) var id: UUID
    var name: String
    var scientificName: String
    var birdDescription: String
    
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
    
    var isIdentified: Bool = false
    var hasBeenIntroduced: Bool = false
    var completionPercentage: Double = 0.0 // 0.0 to 100.0
    
    var topic: Topic?
    
    init(id: UUID, name: String, scientificName: String, description: String, imageSource: ImageSource, isIdentified: Bool = false, hasBeenIntroduced: Bool = false, completionPercentage: Double = 0.0) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.birdDescription = description
        self.imageSource = imageSource
        self.isIdentified = isIdentified
        self.hasBeenIntroduced = hasBeenIntroduced
        self.completionPercentage = completionPercentage
    }
}

