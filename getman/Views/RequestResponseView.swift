//
//  RequestResponseView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 2/12/24.
//

import SwiftUI
import SwiftyMonaco

struct MonacoEditorView: View {
    @Binding var text: String

    var body: some View {
        SwiftyMonaco(text: $text)
            .syntaxHighlight(.systemVerilog)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct RequestResponseView: View {
    @EnvironmentObject var appModel: AppModel

    @Binding var request: APIRequest

    @State private var currentURL = ""
    @State private var selectedInputTab = 0
    @State private var selectedResponseTab = 0
    @State private var selectedMethod: HTTPMethod
    @State private var response: APIResponse?
    @State private var statusText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var task: URLSessionTask?
    @State private var selectedBodyType = BodyType.urlEncoded
    @State private var bodyContent = ""
    @State private var keyValuePairs: [KeyValuePair] = [
        KeyValuePair(key: "", value: "")
    ]

    @FocusState private var focused: Bool

    init(request: Binding<APIRequest>) {
        self._request = request
        self._selectedMethod = State(initialValue: request.wrappedValue.method)
        self._currentURL = State(initialValue: request.wrappedValue.url)
    }

    enum BodyType: String, CaseIterable {
        case urlEncoded = "Url Encoded"
        case multiPart = "Multi-Part"
        case json = "JSON"
        case graphQL = "GraphQL"
        case xml = "XML"
        case other = "Other"
        case binaryFile = "Binary File"
        case noBody = "No Body"
    }

    func sendRequest() async {
        guard let url = URL(string: currentURL) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = selectedMethod.rawValue

        if selectedBodyType == .json || selectedBodyType == .graphQL || selectedBodyType == .xml
            || selectedBodyType == .other
        {
            urlRequest.httpBody = bodyContent.data(using: .utf8)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let startTime = Date()
        isLoading = true
        isSending = true
        statusText = "connecting - 0s - 0B"

        let session = URLSession.shared
        task = session.dataTask(with: urlRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return }

            let endTime = Date()
            let requestTime = endTime.timeIntervalSince(startTime)
            let responseSize = data?.count ?? 0

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
                self.statusText =
                    "\(httpResponse.statusCode) OK - \(String(format: "%.2f", requestTime))s - \(responseSize) B"
            }
        }
        task?.resume()
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

    var body: some View {
        HSplitView {
            // Request Panel
            VStack(spacing: 16) {
                HStack {
                    Picker("", selection: $selectedMethod) {
                        ForEach(HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .onChange(of: selectedMethod) { _, newValue in
                        request.method = newValue
                        appModel.objectWillChange.send()
                    }

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

                        ZStack {
                            // Main content
                            if selectedBodyType == .urlEncoded || selectedBodyType == .multiPart {
                                KeyValueEditor(
                                    pairs: $keyValuePairs,
                                    isMultiPart: selectedBodyType == .multiPart,
                                    onPairsChanged: {
                                        if selectedBodyType == .urlEncoded {
                                            updateURLWithParameters()
                                        }
                                    }
                                )
                            } else if selectedBodyType == .noBody {
                                VStack {
                                    Image(systemName: "nosign")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                    Text("No Body")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if selectedBodyType == .json || selectedBodyType == .graphQL
                                || selectedBodyType == .xml || selectedBodyType == .other
                            {
                                Color.clear  // Placeholder
                            } else {
                                Text("Content for \(selectedBodyType.rawValue)")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }

                            // Monaco editor is always present but only visible when needed
                            LazyView(MonacoEditorView(text: $bodyContent))
                                .opacity(isTextContentType ? 1 : 0)
                                .allowsHitTesting(isTextContentType)
                        }
                    }
                    .tabItem { Text("Body") }
                    .tag(0)

                    Text("Params").tabItem { Text("Params") }.tag(1)
                    Text("Headers").tabItem { Text("Headers") }.tag(2)
                }
            }
            .padding()
            .frame(minWidth: 400)

            // Response Panel
            VStack {
                HStack {
                    ZStack(alignment: .leading) {
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .opacity(isLoading ? 0 : 1)

                        if isLoading {
                            HStack {
                                CircularLoadingIndicator()
                                    .frame(width: 10, height: 10)
                                Spacer()
                                    .frame(width: 5)
                                Text("Sending")
                            }
                            .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 8)

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
                        ScrollView {
                            if let data = response?.data,
                                let json = try? JSONSerialization.jsonObject(with: data),
                                let prettyData = try? JSONSerialization.data(
                                    withJSONObject: json, options: .prettyPrinted),
                                let prettyString = String(data: prettyData, encoding: .utf8)
                            {
                                Text(prettyString)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                        }
                        .tabItem { Text("Pretty") }
                        .tag(0)

                        // Raw View
                        ScrollView {
                            if let data = response?.data,
                                let rawString = String(data: data, encoding: .utf8)
                            {
                                Text(rawString)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                        }
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
    }
}

extension RequestResponseView {
    private func updateURLWithParameters() {
        var urlComponents = URLComponents(string: currentURL) ?? URLComponents()
        let enabledPairs = keyValuePairs.filter { $0.isEnabled && !$0.key.isEmpty }

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
            keyValuePairs = [KeyValuePair(key: "", value: "")]
            return
        }

        keyValuePairs = queryItems.map {
            KeyValuePair(key: $0.name, value: $0.value ?? "")
        }

        if keyValuePairs.isEmpty {
            keyValuePairs.append(KeyValuePair(key: "", value: ""))
        }
    }
}
