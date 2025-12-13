//
//  WordSearchCellView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct WordSearchCellView: View {
    let character: Character
    let position: GridPosition
    let cellSize: CGFloat
    let isSelected: Bool
    let isPartOfWord: Bool
    let foundWord: Bool
    
    var body: some View {
        Text(String(character))
            .foregroundStyle(textColor)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .frame(width: cellSize, height: cellSize)
            .padding(Style.Dimensions.smallMargin)
            .overlay(Circle()
                    .stroke(borderColor, lineWidth: 1))
            .glassEffect(.regular.tint(backgroundColor))
    }
    
    private var backgroundColor: Color {
        if foundWord && isPartOfWord {
            return Color.green.opacity(0.3)
        } else if isSelected {
            return Color.accentColor.opacity(0.2)
        }
        return Color.clear
    }
    
    private var textColor: Color {
        if foundWord && isPartOfWord {
            return .green
        } else if isSelected {
            return .accentColor
        }
        return .primary
    }
    
    private var borderColor: Color {
        if foundWord && isPartOfWord {
            return .green
        } else if isSelected {
            return .accentColor
        }
        return .gray.opacity(0.2)
    }
}


#Preview {
    VStack {
        HStack {
            WordSearchCellView(character: "C", position: .init(row: 1, col: 1), cellSize: 50, isSelected: false, isPartOfWord: true, foundWord: false)
        }
    }
}
