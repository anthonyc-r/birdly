//
//  ArraySafeAccess.swift
//  birdly
//
//  Created by tony on 07/12/2025.
//
import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
