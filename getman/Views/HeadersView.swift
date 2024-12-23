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
    let isEvenRow: Bool

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
    let isEvenRow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 200, alignment: .leading)
                .textSelection(.enabled)
                .padding(.leading, 8)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
        .background(
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .opacity(isEvenRow ? 1 : 0)
        )
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(key): \(value)", forType: .string)
            }) {
                Label("Copy Header", systemImage: "doc.on.doc")
            }

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(key, forType: .string)
            }) {
                Label("Copy Key", systemImage: "key")
            }

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            }) {
                Label("Copy Value", systemImage: "text.quote")
            }
        }
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
                    value: $0.element.value,
                    isEvenRow: $0.offset % 2 == 0)
            } ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(headers) { header in
                    HeaderRowView(
                        key: header.key,
                        value: header.value,
                        isEvenRow: header.isEvenRow
                    )
                }
            }
        }
        .padding()
    }
}
