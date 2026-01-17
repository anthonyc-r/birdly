//
//  Settings.swift
//  birdly
//
//  Created by tony on 17/01/2026.
//
import SwiftData
import Foundation

@Model
final class Settings {
    static let userSettingsId = UUID(uuidString: "FB7D3AA8-2DB4-4EFB-B8B9-D7DCA251C110")!
    
    @Attribute(.unique) var id: UUID
    var isSoundEnabled: Bool
    var isHapticsEnabled: Bool
    
    init(id: UUID, isSoundEnabled: Bool, isHapticsEnabled: Bool) {
        self.id = id
        self.isSoundEnabled = isSoundEnabled
        self.isHapticsEnabled = isHapticsEnabled
    }
    
    static func getDefaultSettings() -> Settings {
        return Settings(id: Settings.userSettingsId, isSoundEnabled: true, isHapticsEnabled: true)
    }
}
