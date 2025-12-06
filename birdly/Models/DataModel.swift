//
//  DataModel.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI
import Combine

@Observable
final class DataModel: Codable {
    var topics: [Topic] = []
    
    init() {
        // Empty initializer for creating new instances
    }
    
    init(from decoder: any Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        topics = try container.decode([Topic].self, forKey: .topics)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topics, forKey: .topics)
    }
    
    enum CodingKeys: String, CodingKey {
        case topics
    }
}
