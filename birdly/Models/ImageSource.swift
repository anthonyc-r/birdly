//
//  ImageSource.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

enum ImageSource: Codable, Hashable {
    case asset(name: String)
    case url(String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        
        switch type {
        case "asset":
            self = .asset(name: value)
        case "url":
            self = .url(value)
        default:
            // For backward compatibility, treat unknown types as asset names
            self = .asset(name: value)
        }
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .asset(let name):
            try container.encode("asset", forKey: .type)
            try container.encode(name, forKey: .value)
        case .url(let urlString):
            try container.encode("url", forKey: .type)
            try container.encode(urlString, forKey: .value)
        }
    }
    
    // Convenience initializer for asset names (backward compatibility)
    init(assetName: String) {
        self = .asset(name: assetName)
    }
    
    // Convenience initializer for URLs
    init(url: String) {
        self = .url(url)
    }
}

