//
//  KeyValuePair.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import SwiftUI

struct FocusField: Hashable {
    let pairId: UUID
    let isKey: Bool
}

struct KeyValueEditor: View {
    let name: String
    @Binding var pairs: [KeyValuePair]
    let isMultiPart: Bool
    let onPairsChanged: (() -> Void)?
    let isHeadersEditor: Bool

    @FocusState private var focusedField: FocusField?
    @State private var showHiddenPairs = false
    @State private var showAutoComplete = false
    @State private var filteredHeaders: [String] = []
    @State private var selectedHeaderIndex = 0
    @State private var activeTextField: UUID?
    @State private var eventMonitor: Any?

    @Namespace private var namespace

    init(
        name: String,
        pairs: Binding<[KeyValuePair]>,
        isMultiPart: Bool,
        isHeadersEditor: Bool = false,
        onPairsChanged: (() -> Void)? = nil
    ) {
        self.name = name
        self._pairs = pairs
        self.isMultiPart = isMultiPart
        self.isHeadersEditor = isHeadersEditor
        self.onPairsChanged = onPairsChanged
    }

    private func updateFilteredHeaders(for text: String) {
        filteredHeaders = HTTPHeadersProvider.shared.filteredHeaders(searchText: text)
        selectedHeaderIndex = 0
    }

    private func selectHeaderAndDismiss(_ header: String, for pair: KeyValuePair) {
        if let index = pairs.firstIndex(where: { $0.id == pair.id }) {
            pairs[index].key = header
            dismissOverlay()
        }
    }

    private func dismissOverlay() {
        showAutoComplete = false
        selectedHeaderIndex = 0
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            switch event.keyCode {
            case 125:  // Down
                selectedHeaderIndex = (selectedHeaderIndex + 1) % filteredHeaders.count
                return nil
            case 126:  // Up
                selectedHeaderIndex =
                    (selectedHeaderIndex - 1 + filteredHeaders.count) % filteredHeaders.count
                return nil
            case 53:  // Escape
                dismissOverlay()
                return nil
            default:
                return event
            }
        }
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

    @ViewBuilder
    private func autoCompleteOverlay(for pair: KeyValuePair) -> some View {
        if showAutoComplete && isHeadersEditor {
            VStack(alignment: .leading, spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filteredHeaders.enumerated()), id: \.offset) {
                                index, header in
                                Button(action: { selectHeaderAndDismiss(header, for: pair) }) {
                                    HStack {
                                        Text(header)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    index == selectedHeaderIndex
                                        ? Color.accentColor.opacity(0.1) : Color.clear
                                )
                                .id(index)  // Add an id for scrolling
                            }
                        }
                    }
                    .frame(height: min(CGFloat(filteredHeaders.count) * 60, 300))
                    .onChange(of: selectedHeaderIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .shadow(radius: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    var body: some View {
        ZStack {
            if showAutoComplete {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissOverlay()
                    }
            }

            VStack(spacing: 0) {
                HStack {
                    if !name.isEmpty {
                        Text(name)
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.semibold)
                            .frame(height: 25)
                    }

                    if isHeadersEditor {
                        HStack {
                            Button(action: {
                                showHiddenPairs.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Image(
                                        systemName: showHiddenPairs ? "eye.slash.fill" : "eye.fill")
                                    Text(
                                        showHiddenPairs
                                            ? "Hide auto-generated headers" : "Show hidden"
                                    )
                                    .font(.callout)
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(HoverButtonStyle())
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.vertical, name.isEmpty ? 0 : 3)

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
                                        if showAutoComplete && !filteredHeaders.isEmpty {
                                            selectHeaderAndDismiss(
                                                filteredHeaders[selectedHeaderIndex], for: pair)
                                        } else {
                                            nextField(
                                                after: FocusField(pairId: pair.id, isKey: true))
                                        }
                                    }
                                    .onChange(of: pair.key) { _, newValue in
                                        if isHeadersEditor {
                                            updateFilteredHeaders(for: newValue)
                                            showAutoComplete = !newValue.isEmpty
                                            activeTextField = pair.id
                                            setupKeyboardMonitor()
                                        }
                                        onPairsChanged?()
                                    }
                                    .overlay(
                                        autoCompleteOverlay(for: pair)
                                            .offset(y: 30),
                                        alignment: .topLeading
                                    )

                                TextField("Value", text: $pair.value)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .focused(
                                        $focusedField,
                                        equals: FocusField(pairId: pair.id, isKey: false)
                                    )
                                    .onSubmit {
                                        nextField(after: FocusField(pairId: pair.id, isKey: false))
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
        }
        .background(.background)
    }
}
