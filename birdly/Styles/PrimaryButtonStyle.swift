//
//  PrimaryButtonStyle.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(Style.Font.h3.weight(.bold))
                .foregroundStyle(Color(.white))
            Spacer()
        }
        .padding(Style.Dimensions.margin)
        .background(RoundedRectangle(cornerRadius: Style.Dimensions.cornerRadius)
            .foregroundStyle(Color(.accent)))
        .frame(idealWidth: .infinity)
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
