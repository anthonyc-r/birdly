//
//  Style.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

enum Style {
    enum Dimensions {
        static let margin: CGFloat = 16
        static let largeMargin: CGFloat = 32
        static let cornerRadius: CGFloat = 16
    }
    enum Button {
        static let primary: some ButtonStyle = PrimaryButtonStyle()
    }
    enum Font {
        static let h1 = size(32)
        static let h2 = size(28)
        static let h3 = size(26)
        
        static let b1 = size(24)
        static let b2 = size(18)
        static let b3 = size(16)
        static let b4 = size(14)
        static let b5 = size(12)
        
        static func size(_ size: CGFloat) -> SwiftUI.Font {
            return SwiftUI.Font.system(size: size)
        }
    }
}
