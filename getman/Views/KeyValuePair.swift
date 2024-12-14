//
//  KeyValuePair.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import SwiftUI

struct KeyValuePair: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var isEnabled: Bool = true
    var isHidden: Bool = false
}

struct FocusField: Hashable {
    let pairId: UUID
    let isKey: Bool
}

struct KeyValueEditor: View {
    @Binding var pairs: [KeyValuePair]
    let isMultiPart: Bool
    let onPairsChanged: (() -> Void)?

    @FocusState private var focusedField: FocusField?
    @State private var showHiddenPairs = false

    init(pairs: Binding<[KeyValuePair]>, isMultiPart: Bool, onPairsChanged: (() -> Void)? = nil) {
        self._pairs = pairs
        self.isMultiPart = isMultiPart
        self.onPairsChanged = onPairsChanged
    }

    private func nextField(after current: FocusField, isTab: Bool = false) {
        guard let currentIndex = pairs.firstIndex(where: { $0.id == current.pairId }) else {
            return
        }

        if current.isKey {
            focusedField = FocusField(pairId: current.pairId, isKey: false)
        } else if currentIndex == pairs.count - 1 {
            if !isTab {
                let newPair = KeyValuePair(key: "", value: "")
                pairs.append(newPair)
                focusedField = FocusField(pairId: newPair.id, isKey: true)
            }
        } else {
            focusedField = FocusField(pairId: pairs[currentIndex + 1].id, isKey: true)
        }
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection, for field: FocusField) {
        if direction == .down || direction == .right {
            nextField(after: field, isTab: true)
        } else if direction == .up || direction == .left {
            previousField(before: field)
        }
    }

    private func previousField(before current: FocusField) {
        guard let currentIndex = pairs.firstIndex(where: { $0.id == current.pairId }) else {
            return
        }

        if !current.isKey {
            focusedField = FocusField(pairId: current.pairId, isKey: true)
        } else if currentIndex > 0 {
            focusedField = FocusField(pairId: pairs[currentIndex - 1].id, isKey: false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Show Hidden", isOn: $showHiddenPairs)
                    .toggleStyle(.switch)
                Spacer()
            }
            .padding(.horizontal)

            HStack(spacing: 0) {
                Spacer().frame(width: 40)

                Divider().frame(height: 28)

                Text("Key")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.medium)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                Divider().frame(height: 28)

                Text("Value")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.medium)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                Spacer().frame(width: 40)
            }
            .frame(height: 36)
            .overlay(
                VStack {
                    Divider()
                    Spacer()
                    Divider()
                }
            )

            ScrollView {
                ForEach($pairs) { $pair in
                    if !pair.isHidden || showHiddenPairs {
                        HStack(spacing: 0) {
                            Toggle("", isOn: $pair.isEnabled)
                                .labelsHidden()
                                .frame(width: 40)

                            TextField("Key", text: $pair.key)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused(
                                    $focusedField,
                                    equals: FocusField(pairId: pair.id, isKey: true)
                                )
                                .onSubmit {
                                    nextField(after: FocusField(pairId: pair.id, isKey: true))
                                }
                                .onMoveCommand { direction in
                                    handleMoveCommand(
                                        direction,
                                        for: FocusField(pairId: pair.id, isKey: true)
                                    )
                                }
                                .onChange(of: pair.key) { _, _ in
                                    onPairsChanged?()
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(.horizontal, 8)

                            TextField("Value", text: $pair.value)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused(
                                    $focusedField, equals: FocusField(pairId: pair.id, isKey: false)
                                )
                                .onSubmit {
                                    nextField(after: FocusField(pairId: pair.id, isKey: false))
                                }
                                .onMoveCommand { direction in
                                    handleMoveCommand(
                                        direction,
                                        for: FocusField(pairId: pair.id, isKey: false)
                                    )
                                }
                                .onChange(of: pair.value) { _, _ in
                                    onPairsChanged?()
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(.horizontal, 8)

                            Button(action: {
                                if let index = pairs.firstIndex(where: { $0.id == pair.id }) {
                                    pairs.remove(at: index)
                                    onPairsChanged?()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 40)
                        }
                        .frame(height: 36)
                    }
                }
            }

            Button(action: {
                let newPair = KeyValuePair(key: "", value: "")
                pairs.append(newPair)
                focusedField = FocusField(pairId: newPair.id, isKey: true)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Parameter")
                }
            }
            .padding(.vertical, 8)
        }
        .background(.background)
    }
}
