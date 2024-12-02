//
//  View.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import SwiftUI

extension View {
    func border(_ color: Color, width: CGFloat, edges: Edge.Set) -> some View {
        overlay(
            VStack {
                if edges.contains(.bottom) {
                    Spacer()
                    color.frame(height: width)
                }
            }
        )
    }
}
