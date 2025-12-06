//
//  User.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var hasSeenSplash: Bool = false
    
    init(id: UUID = UUID(), hasSeenSplash: Bool = false) {
        self.id = id
        self.hasSeenSplash = hasSeenSplash
    }
    
    // Singleton instance ID - we'll always use the same ID
    static let singletonId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
}

