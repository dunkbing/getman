//
//  StatusCodeDetailsOverlay.swift
//  getman
//
//  Created by Bùi Đặng Bình on 23/12/24.
//

import SwiftUI

struct StatusCodeDescriptionOverlay: View {
    let statusCode: Int
    private var description: String {
        return getStatusCodeDescription(statusCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(description)
                .font(.system(.subheadline, design: .monospaced))
        }
        .padding(15)
    }
}
