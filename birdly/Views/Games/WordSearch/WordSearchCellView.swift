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
            .font(.system(size: 35, weight: .semibold, design: .rounded))
            .frame(width: cellSize, height: cellSize)
            .background {
                ZStack {
                    // Base glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.7)
                    
                    // Color overlay based on state
                    Circle()
                        .fill(backgroundColor)
                    
                    // Accent glow for selected state
                    if isSelected && !isPartOfWord {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor.opacity(0.4),
                                        Color.accentColor.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .foregroundColor(textColor)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                borderColor.opacity(0.9),
                                borderColor.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            )
            .shadow(
                color: borderColor.opacity(0.4),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: 2
            )
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

