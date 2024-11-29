import SwiftUI

struct APIRequest: Identifiable, Hashable {
    let id = UUID()
    var method: String
    var url: String
    var name: String
    static func new() -> APIRequest {
        APIRequest(method: "GET", url: "", name: "New HTTP Request")
    }
}

struct APIResponse {
    var statusCode: Int
    var headers: [String: String]
    var data: Data?
    var error: Error?
}

struct ContentView: View {
    @State private var isSidebarVisible = true
    @State private var requests: [APIRequest] = []
    @State private var searchText = ""
    @State private var selectedRequest: APIRequest?

    var body: some View {
        HSplitView {
            if isSidebarVisible {
                SidebarView(
                    requests: $requests, searchText: $searchText, selectedRequest: $selectedRequest
                )
                .frame(minWidth: 200, maxWidth: 300)
                .transition(.move(edge: .leading))
                .animation(.default, value: isSidebarVisible)
            }

            if let selectedRequest = selectedRequest {
                RequestResponseView(request: selectedRequest)
            } else {
                WelcomeView {
                    let newRequest = APIRequest.new()
                    requests.append(newRequest)
                    selectedRequest = newRequest
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    isSidebarVisible.toggle()
                }) {
                    Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                }
                Button(action: createNewRequest) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func createNewRequest() {
        let newRequest = APIRequest.new()
        requests.append(newRequest)
        selectedRequest = newRequest
    }
}

struct SidebarView: View {
    @Binding var requests: [APIRequest]
    @Binding var searchText: String
    @Binding var selectedRequest: APIRequest?

    var body: some View {
        VStack {
            List(selection: $selectedRequest) {
                ForEach(requests) { request in
                    HStack {
                        Text(request.method)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(request.name)
                    }
                }
            }
            TextField("Search requests...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
    }
}

struct RequestResponseView: View {
    let request: APIRequest
    @State private var currentURL = ""
    @State private var selectedInputTab = 0
    @State private var selectedResponseTab = 0
    @State private var selectedMethod = "GET"
    @State private var response: APIResponse?

    func sendRequest() async {
        guard let url = URL(string: currentURL) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = selectedMethod

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            DispatchQueue.main.async {
                self.response = APIResponse(
                    statusCode: httpResponse.statusCode,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                    data: data
                )
                self.selectedResponseTab = 0 // Switch to Pretty view
            }
        } catch {
            DispatchQueue.main.async {
                self.response = APIResponse(
                    statusCode: 0,
                    headers: [:],
                    error: error
                )
            }
        }
    }

    var body: some View {
        HSplitView {
            // Request Panel
            VStack(spacing: 16) {
                HStack {
                    Picker("", selection: $selectedMethod) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                        Text("DELETE").tag("DELETE")
                    }
                    .labelsHidden()
                    .fixedSize()

                    TextField("Enter URL", text: $currentURL, onCommit: {
                        Task { await sendRequest() }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send") {
                        Task { await sendRequest() }
                    }
                }

                TabView(selection: $selectedInputTab) {
                    Text("Body").tabItem { Text("Body") }.tag(0)
                    Text("Params").tabItem { Text("Params") }.tag(1)
                    Text("Headers").tabItem { Text("Headers") }.tag(2)
                }
            }
            .padding()
            .frame(minWidth: 400)

            // Response Panel
            TabView(selection: $selectedResponseTab) {
                // Pretty JSON View
                ScrollView {
                    if let data = response?.data,
                       let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
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
                       let rawString = String(data: data, encoding: .utf8) {
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
                        ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
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
            .frame(minWidth: 300)
            .padding()
        }
    }
}
