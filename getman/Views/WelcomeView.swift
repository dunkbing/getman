//
//  WelcomeView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 30/11/24.
//

import SwiftUI

struct WelcomeView: View {
    let onNewRequest: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 12) {
                Text("New Request (⌘N)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Open Settings (⌘,)")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 20) {
                    Button("Import") {
                        // Handle import
                    }
                    .buttonStyle(.borderedProminent)

                    Button("New Request") {
                        onNewRequest()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
