//
//  CustomTabBar.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var tabs: [APIRequest]
    @Binding var selectedReqId: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(tabs, id: \.id) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: selectedReqId == tab.id,
                            onSelect: { selectedReqId = tab.id },
                            onClose: { closeTab(tab) }
                        )
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 8)
            .onChange(of: selectedReqId) { oldValue, newValue in
                if let id = newValue {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func closeTab(_ tab: APIRequest) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            if selectedReqId == tab.id {
                selectedReqId = tabs.last?.id
            }
        }
    }
}

struct TabItemView: View {
    let tab: APIRequest
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Spacer().frame(width: 14)
                Text(tab.name)
                Button(action: onClose) {
                    if isHovered {
                        Image(systemName: "xmark")
                            .frame(width: 14)
                    } else {
                        Spacer().frame(width: 14)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.accentColor.opacity(0.5) : Color.clear,
                                lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BorderlessButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
