//
//  SettingsView.swift
//  birdly
//
//  Created by tony on 17/01/2026.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("Feedback")) {
                Toggle(isOn: $settings.isSoundEnabled, label: { Text("Sounds")})
                Toggle(isOn: $settings.isHapticsEnabled, label: { Text("Haptic feedback")})
            }
            Section(header: Text("About")) {
                Link("Open source license", destination: Urls.license)
                Link("Get the source code", destination: Urls.sourceCode)
            }
        }
        .navigationTitle("Settings")
    }
}


#Preview {
    SettingsView(settings: .init(id: UUID(), isSoundEnabled: false, isHapticsEnabled: true))
}
