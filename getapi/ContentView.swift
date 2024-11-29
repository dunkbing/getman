//
//  ContentView.swift
//  getapi
//
//  Created by Bùi Đặng Bình on 29/11/24.
//

import SwiftUI

struct APIRequest: Identifiable, Hashable {
    let id = UUID()
    var method: String
    var url: String
    var name: String
}

struct ContentView: View {
    @State private var requests: [APIRequest] = []
    @State private var searchText = ""
    @State private var selectedRequest: APIRequest?
    @State private var currentURL = ""
    @State private var selectedInputTab = 0
    @State private var selectedResponseTab = 0
    @State private var responseBody = ""
    @State private var requestBody = ""
    @State private var headers: [String: String] = [:]
    @State private var params: [String: String] = [:]

    var filteredRequests: [APIRequest] {
        if searchText.isEmpty { return requests }
        return requests.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        HSplitView {
            // Sidebar
            VStack {
                List(filteredRequests, selection: $selectedRequest) { request in
                    Text(request.name)
                }

                // Search at bottom
                TextField("Search requests...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            .frame(minWidth: 200, maxWidth: 300)

            // Request Panel (Middle)
            VStack(spacing: 16) {
                // URL Input
                HStack {
                    Picker("Method", selection: .constant("POST")) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                        Text("DELETE").tag("DELETE")
                    }
                    .frame(width: 100)

                    TextField("Enter URL", text: $currentURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send") {
                        // Implement API call
                    }
                }

                // Request Input Tabs
                TabView(selection: $selectedInputTab) {
                    RequestBodyView(requestBody: $requestBody)
                        .tabItem { Text("Body") }
                        .tag(0)

                    ParamsView(params: $params)
                        .tabItem { Text("Params") }
                        .tag(1)

                    HeadersView(headers: $headers)
                        .tabItem { Text("Headers") }
                        .tag(2)
                }
            }
            .padding()
            .frame(minWidth: 400)

            // Response Panel (Right)
            TabView(selection: $selectedResponseTab) {
                ResponseView(responseBody: responseBody, mode: .pretty)
                    .tabItem { Text("Pretty") }
                    .tag(0)

                ResponseView(responseBody: responseBody, mode: .raw)
                    .tabItem { Text("Raw") }
                    .tag(1)

                ResponseHeadersView()
                    .tabItem { Text("Headers") }
                    .tag(2)

                ResponseInfoView()
                    .tabItem { Text("Info") }
                    .tag(3)
            }
            .frame(minWidth: 300)
            .padding()
        }
    }
}

struct RequestBodyView: View {
    @Binding var requestBody: String

    var body: some View {
        TextEditor(text: $requestBody)
            .font(.system(.body, design: .monospaced))
    }
}

struct ParamsView: View {
    @Binding var params: [String: String]

    var body: some View {
        List {
            ForEach(Array(params.keys), id: \.self) { key in
                HStack {
                    TextField("Key", text: .constant(key))
                    TextField(
                        "Value",
                        text: Binding(
                            get: { params[key] ?? "" },
                            set: { params[key] = $0 }
                        ))
                }
            }

            Button("Add Parameter") {
                params["New Key"] = ""
            }
        }
    }
}

struct HeadersView: View {
    @Binding var headers: [String: String]

    var body: some View {
        List {
            ForEach(Array(headers.keys), id: \.self) { key in
                HStack {
                    TextField("Key", text: .constant(key))
                    TextField(
                        "Value",
                        text: Binding(
                            get: { headers[key] ?? "" },
                            set: { headers[key] = $0 }
                        ))
                }
            }

            Button("Add Header") {
                headers["New Header"] = ""
            }
        }
    }
}

enum ResponseMode {
    case pretty, raw
}

struct ResponseView: View {
    let responseBody: String
    let mode: ResponseMode

    var body: some View {
        TextEditor(text: .constant(responseBody))
            .font(.system(.body, design: .monospaced))
    }
}

struct ResponseHeadersView: View {
    var body: some View {
        List {
            Text("Status: 200 OK")
            Text("Content-Type: application/json")
            Text("Content-Length: 87 B")
        }
    }
}

struct ResponseInfoView: View {
    var body: some View {
        List {
            Text("Time: 2s")
            Text("Size: 87 B")
        }
    }
}
