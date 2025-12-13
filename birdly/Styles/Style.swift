//
//  Style.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

enum Style {
    enum Dimensions {
        static let smallMargin: CGFloat = 8
        static let margin: CGFloat = 16
        static let largeMargin: CGFloat = 32
        static let cornerRadius: CGFloat = 16
    }
    enum Button {
        static let primary: some ButtonStyle = PrimaryButtonStyle()
    }
    enum Font {
        static let h1 = size(32)
        static let h2 = size(26)
        static let h3 = size(24)
        
        static let b1 = size(22)
        static let b2 = size(18)
        static let b3 = size(16)
        static let b4 = size(14)
        static let b5 = size(12)
        
        static func size(_ size: CGFloat) -> SwiftUI.Font {
            return SwiftUI.Font.system(size: size)
        }
    }
    
    enum Glass {
        static let blurRadius: CGFloat = 20
        static let saturation: CGFloat = 1.2
        static let opacity: Double = 0.7
        static let borderWidth: CGFloat = 1.5
        static let shadowRadius: CGFloat = 10
        static let shadowOpacity: Double = 0.2
    }
}

// Liquid glass card modifier
struct LiquidGlassCard: ViewModifier {
    let accentColor: Color
    
    init(accentColor: Color = .accentColor) {
        self.accentColor = accentColor
    }
    
    func body(content: Content) -> some View {
        content
            .glassEffect(Glass.regular.interactive(), in: RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius))
    }
}

extension View {
    func liquidGlassCard(accentColor: Color = .accentColor) -> some View {
        modifier(LiquidGlassCard(accentColor: accentColor))
    }
}
