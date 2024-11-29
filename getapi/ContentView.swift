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

struct ContentView: View {
    @State private var requests: [APIRequest] = []
    @State private var searchText = ""
    @State private var selectedRequest: APIRequest?

    var body: some View {
        HSplitView {
            // Sidebar
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
            .frame(minWidth: 200, maxWidth: 300)

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
    }
}

struct RequestResponseView: View {
    let request: APIRequest
    @State private var currentURL = ""
    @State private var selectedInputTab = 0
    @State private var selectedResponseTab = 0
    @State private var selectedMethod = "GET"  // Add state for method

    var body: some View {
        HSplitView {
            // Request Panel
            VStack(spacing: 16) {
                HStack {
                    Picker("Method", selection: $selectedMethod) {  // Bind to selectedMethod
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                        Text("DELETE").tag("DELETE")
                    }
                    .fixedSize()
                    .padding(.horizontal, 6)

                    TextField("Enter URL", text: $currentURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send") {}
                }

                TabView(selection: $selectedInputTab) {
                    Text("Body").tabItem { Text("Body") }.tag(0)
                    Text("Params").tabItem { Text("Params") }.tag(1)
                    Text("Headers").tabItem { Text("Headers") }.tag(2)
                }
            }
            .padding()
            .frame(minWidth: 400)

            // Response Panel remains the same
            TabView(selection: $selectedResponseTab) {
                Text("Pretty").tabItem { Text("Pretty") }.tag(0)
                Text("Raw").tabItem { Text("Raw") }.tag(1)
                Text("Headers").tabItem { Text("Headers") }.tag(2)
                Text("Info").tabItem { Text("Info") }.tag(3)
            }
            .frame(minWidth: 300)
            .padding()
        }
    }
}
