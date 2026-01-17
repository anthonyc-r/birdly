//
//  SingleValueQuery.swift
//  birdly
//
//  Created by tony on 17/01/2026.
//
import SwiftData
import SwiftUI

@propertyWrapper
struct SingleValueDefaultQuery<T: PersistentModel>: DynamicProperty {
    private let descriptor: FetchDescriptor<T>
    private let defaultValue: T
    @Environment(\.modelContext) private var modelContext

    init(_ descriptor: FetchDescriptor<T> = .init(), defaultValue: T) {
        self.descriptor = descriptor
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        if let value = (try? modelContext.fetch(descriptor))?.first {
            return value
        } else {
            modelContext.insert(defaultValue)
            return defaultValue
        }
    }
}
