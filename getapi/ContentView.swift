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

            // Response Panel
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
