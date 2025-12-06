//
//  NavigationModel.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import Combine
import SwiftUI

@Observable
final class NavigationModel {
    static let shared: NavigationModel = .init()
    
    var hasSeenSplash = false
    var activeTab: Tab = .discover
    var navigationStack = [Tab : [Any]]()
    
    var path = NavigationPath()
    
    
    private init() {
        
    }
    
    enum Tab {
        case discover
        case birdLog
        case settings
    }
}
