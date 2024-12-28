//
//  HeadersView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 23/12/24.
//

import SwiftUI

struct HeaderItem: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let value: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: HeaderItem, rhs: HeaderItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct HeaderRowView: View {
    let key: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 200, alignment: .leading)
                .padding(.leading, 8)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

struct HeadersView: View {
    let headers: [HeaderItem]

    init(responseHeaders: [String: String]?) {
        self.headers =
            responseHeaders?
            .sorted(by: { $0.key < $1.key })
            .enumerated()
            .map {
                HeaderItem(
                    key: $0.element.key,
                    value: $0.element.value
                )
            } ?? []
    }

    var body: some View {
        List(headers) { header in
            HeaderRowView(
                key: header.key,
                value: header.value
            )
        }
        .listStyle(.plain)
        .padding()
    }
}
