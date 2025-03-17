// DATEI: Views/Common/ButtonTileStyle.swift
import SwiftUI

struct SecureNotesButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : color)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? color : color.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
