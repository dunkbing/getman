//
//  RequestResponseView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import CodeEditLanguages
import CodeEditSourceEditor
import SwiftUI

struct CodeEditorView: View {
    @Binding var text: String
    let editable: Bool
    let lang: CodeLanguage

    @Environment(\.colorScheme) var colorScheme

    var theme: EditorTheme {
        if colorScheme == .dark {
            return EditorTheme(
                text: CatppuccinPalette.Mocha.text,
                insertionPoint: CatppuccinPalette.Mocha.rosewater,
                invisibles: CatppuccinPalette.Mocha.surface2,
                background: CatppuccinPalette.Mocha.base,
                lineHighlight: CatppuccinPalette.Mocha.surface2.withAlphaComponent(0.15),
                selection: CatppuccinPalette.Mocha.surface2.withAlphaComponent(0.3),
                keywords: CatppuccinPalette.Mocha.mauve,
                commands: CatppuccinPalette.Mocha.red,
                types: CatppuccinPalette.Mocha.blue,
                attributes: CatppuccinPalette.Mocha.teal,
                variables: CatppuccinPalette.Mocha.lavender,
                values: CatppuccinPalette.Mocha.peach,
                numbers: CatppuccinPalette.Mocha.peach,
                strings: CatppuccinPalette.Mocha.green,
                characters: CatppuccinPalette.Mocha.teal,
                comments: CatppuccinPalette.Mocha.surface2
            )
        } else {
            return EditorTheme(
                text: CatppuccinPalette.Latte.text,
                insertionPoint: CatppuccinPalette.Latte.rosewater,
                invisibles: CatppuccinPalette.Latte.surface2,
                background: CatppuccinPalette.Latte.base,
                lineHighlight: CatppuccinPalette.Latte.surface2.withAlphaComponent(0.15),
                selection: CatppuccinPalette.Latte.surface2.withAlphaComponent(0.3),
                keywords: CatppuccinPalette.Latte.mauve,
                commands: CatppuccinPalette.Latte.red,
                types: CatppuccinPalette.Latte.blue,
                attributes: CatppuccinPalette.Latte.teal,
                variables: CatppuccinPalette.Latte.lavender,
                values: CatppuccinPalette.Latte.peach,
                numbers: CatppuccinPalette.Latte.peach,
                strings: CatppuccinPalette.Latte.green,
                characters: CatppuccinPalette.Latte.teal,
                comments: CatppuccinPalette.Latte.surface2
            )
        }
    }
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var tabWidth = 4
    @State var lineHeight = 1.2
    @State var editorOverscroll = 0.3
    @State var cursorPositions = [CursorPosition(line: 0, column: 0)]

    var body: some View {
        CodeEditSourceEditor(
            $text,
            language: lang,
            theme: theme,
            font: font,
            tabWidth: tabWidth,
            lineHeight: lineHeight,
            wrapLines: false,
            editorOverscroll: editorOverscroll,
            cursorPositions: $cursorPositions,
            isEditable: editable
        )
        .scrollDisabled(false)
        .padding(.horizontal)
        .padding(.bottom)
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

enum BodyType: String, CaseIterable, Codable {
    case urlEncoded = "Url Encoded"
    case multiPart = "Multi-Part"
    case json = "JSON"
    case graphQL = "GraphQL"
    case xml = "XML"
    case other = "Other"
    case binaryFile = "Binary File"
    case noBody = "No Body"
}

struct RequestResponseView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.colorScheme) var colorScheme

    @Binding var request: APIRequest

    @State private var currentURL = ""
    @State private var selectedInputTab = 0
    @State private var selectedResponseTab = 0
    @State private var selectedMethod: HTTPMethod
    @State private var response: APIResponse?
    @State private var statusText = ""
    @State private var statusCode: Int?
    @State private var requestTime = ""
    @State private var responseSize = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var task: URLSessionTask?
    @State private var selectedBodyType = BodyType.noBody
    @State private var bodyContent = ""
    @State private var paramsKvPairs: [KeyValuePair] = [
        KeyValuePair(key: "", value: "")
    ]
    @State private var headersKvPairs: [KeyValuePair] = [
        KeyValuePair(key: "Cache-Control", value: "no-cache", isHidden: true),
        KeyValuePair(key: "User-Agent", value: "Getman/1.0", isHidden: true),
        KeyValuePair(key: "Accept", value: "*/*", isHidden: true),
        KeyValuePair(key: "Accept-Encoding", value: "gzip, deflate, br", isHidden: true),
        KeyValuePair(key: "Connection", value: "keep-alive", isHidden: true),
        KeyValuePair(key: "", value: ""),
    ]
    @State private var formKvPairs: [KeyValuePair] = [
        KeyValuePair(key: "", value: "")
    ]
    @State private var showNetworkDetails = false
    @State private var networkDetails: NetworkDetails?
    @State private var showStatusCodeDesc = false

    @FocusState private var focused: Bool

    var prettyResponse: String {
        if let data = self.response?.data,
            let json = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: json, options: .prettyPrinted),
            let prettyString = String(data: prettyData, encoding: .utf8)
        {
            return prettyString
        }
        return ""
    }

    var rawReponse: String {
        if let data = response?.data,
            let rawString = String(data: data, encoding: .utf8)
        {
            return rawString
        }
        return ""
    }

    private var statusCodeShortDesc: String {
        if let code = statusCode {
            return getStatusCodeShortDescription(code)
        }
        return ""
    }

    let isHorizontalLayout: Bool

    init(request: Binding<APIRequest>, isHorizontalLayout: Bool = true) {
        self._request = request
        self._selectedMethod = State(initialValue: request.wrappedValue.method)
        self._currentURL = State(initialValue: request.wrappedValue.url)
        self.isHorizontalLayout = isHorizontalLayout
    }

    func sendRequest() async {
        saveRequest()
        guard let url = URL(string: currentURL) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = selectedMethod.rawValue

        // Add headers from headersKvPairs
        for header in headersKvPairs where header.isEnabled && !header.key.isEmpty {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if selectedMethod != .GET && selectedMethod != .HEAD {
            if selectedBodyType == .json || selectedBodyType == .graphQL || selectedBodyType == .xml
                || selectedBodyType == .other
            {
                urlRequest.httpBody = bodyContent.data(using: .utf8)
                // Only set Content-Type if it's not already set in headers
                if !headersKvPairs.contains(where: {
                    $0.isEnabled && $0.key.lowercased() == "content-type"
                }) {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            }
        }

        let startTime = Date()
        isLoading = true
        isSending = true

        let session = URLSession.shared
        task = session.dataTask(with: urlRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return }

            let endTime = Date()
            let responseSize = data?.count ?? 0

            let requestTimeInterval = endTime.timeIntervalSince(startTime)
            let formattedRequestTime: String
            if requestTimeInterval < 1.0 {
                let milliseconds = Int(requestTimeInterval * 1000)
                formattedRequestTime = "\(milliseconds) ms"
            } else {
                formattedRequestTime = "\(String(format: "%.2f", requestTimeInterval)) s"
            }

            DispatchQueue.main.async {
                self.response = APIResponse(
                    statusCode: httpResponse.statusCode,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                    data: data,
                    error: error
                )
                self.selectedResponseTab = 0
                self.isLoading = false
                self.isSending = false
                self.statusCode = httpResponse.statusCode
                self.requestTime = formattedRequestTime
                self.responseSize = "\(responseSize) B"

                // Set network details
                self.networkDetails = NetworkDetails(
                    localAddress: "127.0.0.1:${LOCAL_PORT}",
                    remoteAddress: httpResponse.url?.host ?? "unknown",
                    httpVersion: "HTTP/\(String(describing: HTTPURLResponse.version))"
                )
            }
        }
        task?.resume()
    }

    private func saveRequest() {
        request.url = currentURL
        request.method = selectedMethod
        request.headersKvPairs = headersKvPairs
        request.paramsKvPairs = paramsKvPairs
        request.formKvPairs = formKvPairs
        request.bodyType = selectedBodyType
        request.bodyContent = bodyContent
        request.lastModified = Date()

        appModel.save()
    }

    private func loadSavedData() {
        currentURL = request.url
        selectedMethod = request.method
        headersKvPairs = request.headersKvPairs
        paramsKvPairs = request.paramsKvPairs
        formKvPairs = request.formKvPairs
        selectedBodyType = request.bodyType
        bodyContent = request.bodyContent
    }

    func cancelRequest() {
        task?.cancel()
        isSending = false
        isLoading = false
        statusText = "Request cancelled"
    }

    private var isTextContentType: Bool {
        switch selectedBodyType {
        case .json, .graphQL, .xml, .other:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    func requestPanel() -> some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Picker("", selection: $selectedMethod) {
                        ForEach(HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue)
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(method.color)
                                .tag(method)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .onChange(of: selectedMethod) { _, newValue in
                        request.method = newValue
                        appModel.objectWillChange.send()
                    }
                }
                .background(
                    colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
                )
                .cornerRadius(5)

                TextField("Enter URL", text: $currentURL)
                    .focused($focused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: currentURL) { _, newValue in
                        if !focused {
                            return
                        }
                        if selectedBodyType == .urlEncoded {
                            updateParametersFromURL()
                        }
                    }
                    .onSubmit {
                        Task { await sendRequest() }
                    }

                Button(action: {
                    if isSending {
                        cancelRequest()
                    } else {
                        Task {
                            await sendRequest()
                        }
                    }
                }) {
                    if isSending {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                    } else {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }

            TabView(selection: $selectedInputTab) {
                VStack {
                    KeyValueEditor(
                        name: "Query Params",
                        pairs: $paramsKvPairs,
                        isMultiPart: false,
                        isHeadersEditor: false,
                        onPairsChanged: {
                            updateURLWithParameters()
                        }
                    )
                }
                .padding(.top, 8)
                .tabItem { Text("Params") }
                .tag(0)

                VStack {
                    KeyValueEditor(
                        name: "Headers",
                        pairs: $headersKvPairs,
                        isMultiPart: false,
                        isHeadersEditor: true,
                        onPairsChanged: {}
                    )
                }
                .padding(.top, 8)
                .tabItem { Text("Headers") }
                .tag(1)

                VStack {
                    Picker("Body Type", selection: $selectedBodyType) {
                        Section(header: Text("Form Data")) {
                            Text(BodyType.urlEncoded.rawValue)
                                .tag(BodyType.urlEncoded)
                            Text(BodyType.multiPart.rawValue)
                                .tag(BodyType.multiPart)
                        }
                        Section(header: Text("Text Content")) {
                            Text(BodyType.json.rawValue).tag(BodyType.json)
                            Text(BodyType.graphQL.rawValue).tag(BodyType.graphQL)
                            Text(BodyType.xml.rawValue).tag(BodyType.xml)
                            Text(BodyType.other.rawValue).tag(BodyType.other)
                        }
                        Section(header: Text("Other")) {
                            Text(BodyType.binaryFile.rawValue)
                                .tag(BodyType.binaryFile)
                            Text(BodyType.noBody.rawValue)
                                .tag(BodyType.noBody)
                        }
                    }
                    .fixedSize()
                    .onChange(of: selectedBodyType) { _, newValue in
                        if newValue == .urlEncoded {
                            updateParametersFromURL()
                        }
                    }
                    .padding(.bottom, 11)

                    ZStack {
                        // Main content
                        if selectedBodyType == .urlEncoded || selectedBodyType == .multiPart {
                            KeyValueEditor(
                                name: "",
                                pairs: $formKvPairs,
                                isMultiPart: selectedBodyType == .multiPart,
                                isHeadersEditor: false,
                                onPairsChanged: {}
                            )
                        } else if selectedBodyType == .noBody {
                            VStack {
                                Image(systemName: "nosign")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                Text("Empty Body")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if selectedBodyType == .json || selectedBodyType == .graphQL
                            || selectedBodyType == .xml || selectedBodyType == .other
                        {
                            CodeEditorView(text: $bodyContent, editable: true, lang: .json)
                        } else {
                            Text("Content for \(selectedBodyType.rawValue)")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .padding(.top, 8)
                .tabItem { Text("Body") }
                .tag(2)
            }
        }
        .padding()
        .frame(minWidth: 400)
        .onAppear {
            loadSavedData()
        }
    }

    @ViewBuilder
    func responsePanel() -> some View {
        VStack {
            HStack {
                ZStack(alignment: .leading) {
                    if isLoading {
                        HStack {
                            CircularLoadingIndicator()
                                .frame(width: 10, height: 10)
                            Spacer()
                                .frame(width: 5)
                            Text("Sending")
                        }
                        .transition(.opacity)
                    } else if let code = statusCode {
                        // stats section
                        HStack {
                            Text("\(code) \(statusCodeShortDesc)")
                                .font(.subheadline)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    statusCodeColor(for: code).opacity(0.2)
                                )
                                .cornerRadius(5)
                                .foregroundColor(statusCodeColor(for: code))
                                .onHover { inside in
                                    showStatusCodeDesc = inside
                                }
                                .popover(isPresented: $showStatusCodeDesc, arrowEdge: .bottom) {
                                    StatusCodeDescriptionOverlay(statusCode: code)
                                }

                            Text(requestTime)
                                .foregroundColor(.gray)
                                .font(.subheadline)

                            Text(responseSize)
                                .foregroundColor(.gray)
                                .font(.subheadline)

                            Image(systemName: "network")
                                .foregroundColor(.gray)
                                .onHover { inside in
                                    showNetworkDetails = inside
                                }
                                .popover(isPresented: $showNetworkDetails, arrowEdge: .bottom) {
                                    NetworkDetailsOverlay(details: networkDetails)
                                }
                        }
                    }
                }
            }
            .padding(.vertical, 5)

            if response == nil {
                VStack(spacing: 16) {
                    Text("Send Request")
                        .font(.title)
                        .padding(.bottom, 8)
                    Text("New Request")
                        .font(.title2)
                        .padding(.bottom, 8)
                    Text("Focus or Toggle Sidebar")
                        .font(.title3)
                        .padding(.bottom, 8)
                    Text("Focus URL")
                        .font(.title3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
            } else {
                TabView(selection: $selectedResponseTab) {
                    // JSON View
                    CodeEditorView(text: .constant(prettyResponse), editable: false, lang: .json)
                        .tabItem { Text("Pretty") }
                        .tag(0)

                    // Raw View
                    CodeEditorView(text: .constant(rawReponse), editable: false, lang: .default)
                        .tabItem { Text("Raw") }
                        .tag(1)

                    // Headers View
                    ScrollView {
                        if let headers = response?.headers {
                            ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) {
                                key, value in
                                VStack(alignment: .leading) {
                                    Text(key).bold()
                                    Text(value)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .tabItem { Text("Headers") }
                    .tag(2)

                    // Info View
                    VStack(alignment: .leading, spacing: 12) {
                        if let response = response {
                            Text("Status Code: \(response.statusCode)")
                            if let error = response.error {
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .tabItem { Text("Info") }
                    .tag(3)
                }
            }
        }
        .frame(minWidth: 300)
        .padding()
    }

    private func statusCodeColor(for statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300:
            return .green
        case 300..<400:
            return .blue
        case 400..<500:
            return .orange
        case 500..<600:
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        if isHorizontalLayout {
            HSplitView {
                requestPanel()
                responsePanel()
            }
        } else {
            VSplitView {
                requestPanel()
                responsePanel()
            }
        }

    }
}

extension RequestResponseView {
    private func updateURLWithParameters() {
        var urlComponents = URLComponents(string: currentURL) ?? URLComponents()
        let enabledPairs = paramsKvPairs.filter { $0.isEnabled && !$0.key.isEmpty }

        if enabledPairs.isEmpty {
            urlComponents.queryItems = nil
        } else {
            urlComponents.queryItems = enabledPairs.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        if let newURLString = urlComponents.string {
            currentURL = newURLString
        }
    }

    private func updateParametersFromURL() {
        guard let urlComponents = URLComponents(string: currentURL),
            let queryItems = urlComponents.queryItems
        else {
            paramsKvPairs = [KeyValuePair(key: "", value: "")]
            return
        }

        paramsKvPairs = queryItems.map {
            KeyValuePair(key: $0.name, value: $0.value ?? "")
        }

        if paramsKvPairs.isEmpty {
            paramsKvPairs.append(KeyValuePair(key: "", value: ""))
        }
    }
}
