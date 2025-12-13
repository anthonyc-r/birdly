//
//  PrimaryButtonStyle.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(Style.Font.h3.weight(.bold))
            Spacer()
        }
        .padding(Style.Dimensions.margin)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .frame(idealWidth: .infinity)
        .glassEffect(.regular.tint(.accent).interactive())
    }
}

#Preview {
    VStack {
        Spacer()
        Button(action: { }, label: { Text("Click Me") })
        Spacer()
    }
    .padding(Style.Dimensions.margin)
    .buttonStyle(PrimaryButtonStyle())
}
