//
//  DataLoader.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import Foundation

enum DataLoader {
    static func loadData() throws -> DataModel {
        guard let url = Bundle.main.url(forResource: "birdlyData", withExtension: "json") else {
            throw DataLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let dataModel = try decoder.decode(DataModel.self, from: data)
        return dataModel
    }
    
    enum DataLoaderError: Error {
        case fileNotFound
        case decodingFailed
    }
}

