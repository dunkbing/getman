//
//  Backport.swift
//  getman
//
//  Created by Bùi Đặng Bình on 31/12/24.
//

import SwiftUI

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

extension View {
    var backport: Backport<Self> { Backport(self) }
}

extension Backport where Content: View {
    @ViewBuilder
    func thinWindowBg() -> some View {
        if #available(macOS 15.0, *) {
            content.containerBackground(.thinMaterial, for: .window)
        } else {
            content
        }
    }

    @ViewBuilder
    func hiddenToolbar() -> some View {
        if #available(macOS 15.0, *) {
            content.toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            content
        }
    }
}
