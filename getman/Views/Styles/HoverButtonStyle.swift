//
//  HoverButtonStyle.swift
//  getman
//
//  Created by Bùi Đặng Bình on 15/12/24.
//

import SwiftUI

struct HoverButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .cornerRadius(6)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
