//
//  PrimaryButtonStyle.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

// Environment key for button tint color
private struct ButtonTintColorKey: EnvironmentKey {
    static let defaultValue: Color = .accentColor
}

extension EnvironmentValues {
    var buttonTintColor: Color {
        get { self[ButtonTintColorKey.self] }
        set { self[ButtonTintColorKey.self] = newValue }
    }
}

// View modifier to set button tint color
extension View {
    func buttonTintColor(_ color: Color) -> some View {
        environment(\.buttonTintColor, color)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.buttonTintColor) private var tintColor
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(Style.Font.h3.weight(.bold))
                .foregroundStyle(Color(.white))
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(Style.Dimensions.margin)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .frame(idealWidth: .infinity)
        .glassEffect(.regular.tint(tintColor).interactive())
    }
}

#Preview {
    VStack(spacing: 20) {
        Spacer()
        Button(action: { print("tapped") }, label: { Text("Default Tint") })
        Button(action: { print("tapped") }, label: { Text("Custom Tint") })
            .buttonTintColor(.blue)
        Button(action: { print("tapped") }, label: { Text("Red Tint") })
            .buttonTintColor(.red)
        Spacer()
    }
    .padding(Style.Dimensions.margin)
    .buttonStyle(PrimaryButtonStyle())
}
