//
//  NetworkDetailsOverlay.swift
//  getman
//
//  Created by Bùi Đặng Bình on 22/12/24.
//

import SwiftUI

struct NetworkDetails {
    let localAddress: String
    let remoteAddress: String
    let httpVersion: String
}

struct NetworkDetailsOverlay: View {
    let details: NetworkDetails?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let details = details {
                    Text("Local Address: \(details.localAddress)")
                    Text("Remote Address: \(details.remoteAddress)")
                    Text("HTTP Version: \(details.httpVersion)")
                } else {
                    Text("Network information unavailable")
                }
            }
            .font(.system(.subheadline, design: .monospaced))
        }
        .padding(15)
    }
}
