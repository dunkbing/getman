//
//  CircularLoadingIndicator.swift
//  getapi
//
//  Created by Bùi Đặng Bình on 30/11/24.
//

import SwiftUI

struct CircularLoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.gray, lineWidth: 2.5)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1).repeatForever(autoreverses: false),
                    value: isAnimating)
        }
        .onAppear {
            self.isAnimating = true
        }
    }
}
