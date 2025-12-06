//
//  MenuView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct MenuView: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        TabView(selection: $navigationModel.activeTab) {
            Tab("Discover", systemImage: "house.fill", value: .discover) {
                DiscoverView()
            }
            Tab("Bird Log", systemImage: "book.fill", value: .birdLog) {
                Text("Bird Log")
            }
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                
            }
        }
    }
}

#Preview {
    MenuView()
        .environment(NavigationModel.shared)
}
