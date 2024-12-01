import Combine
import SwiftUI

struct TabItem: Identifiable, Equatable {
    let id: UUID
    let request: APIRequest
    var title: String

    static func new(request: APIRequest, title: String) -> TabItem {
        TabItem(id: request.id, request: request, title: title)
    }

    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var isSidebarVisible = true
    @State private var searchText = ""
    @State private var tabs: [TabItem] = []
    @State private var selectedReqId: UUID?

    @State private var selectionIds = AppModel.Selection()
    @State private var draggingIds = AppModel.Selection()

    private var detailItemsSelected: [Item] {
        appModel.itemsFind(ids: selectionIds)
    }

    var body: some View {
        HSplitView {
            if isSidebarVisible {
                if appModel.isEmpty {
                    EmptyStateView()
                } else {
                    List(selection: $selectionIds) {
                        Node(parent: appModel.bootstrapRoot) { req in
                            selectedReqId = req.id
                            openRequest(req)
                        }
                    }
                    .listStyle(.sidebar)
                }
            }

            if tabs.isEmpty {
                WelcomeView {
                    createNewRequest()
                }
            } else {
                ZStack(alignment: .topLeading) {
                    TabView(selection: $selectedReqId) {
                        ForEach(tabs) { tab in
                            RequestResponseView(request: tab.request)
                                .tag(tab.id)
                        }
                    }

                    CustomTabBar(tabs: $tabs, selectedReqId: $selectedReqId)
                        .frame(height: 30)
                        .background(Color(NSColor.windowBackgroundColor))
                        .border(Color.gray.opacity(0.3), width: 0.5, edges: [.bottom])
                }
            }
        }
        .onChange(of: selectedReqId) { _, newId in
            if let selectedReq = tabs.first(where: { $0.request.id == newId }) {
                let requestId = selectedReq.id
                appModel.selectedRequestId = requestId
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { isSidebarVisible.toggle() }) {
                    Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                }
                Button(action: createNewRequest) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func openRequest(_ request: APIRequest) {
        if let existingTab = tabs.first(where: { $0.request.id == request.id }) {
            selectedReqId = existingTab.id
        } else {
            let newTab = TabItem.new(request: request, title: request.name)
            tabs.append(newTab)
            selectedReqId = newTab.id
        }
    }

    private func createNewRequest() {
        let newRequest = APIRequest.new()
        let name = "New Request"
        let item = Item(name, request: newRequest)
        appModel.addChild(item: item)
        let newTab = TabItem.new(request: newRequest, title: name)
        tabs.append(newTab)
        selectedReqId = newRequest.id
    }

    private func closeTab(_ tab: TabItem) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            if selectedReqId == tab.request.id {
                selectedReqId = tabs.last?.request.id
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var tabs: [TabItem]
    @Binding var selectedReqId: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(tabs, id: \.id) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: selectedReqId == tab.request.id,
                            onSelect: { selectedReqId = tab.request.id },
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

    private func closeTab(_ tab: TabItem) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            if selectedReqId == tab.request.id {
                selectedReqId = tabs.last?.request.id
            }
        }
    }
}

extension View {
    func border(_ color: Color, width: CGFloat, edges: Edge.Set) -> some View {
        overlay(
            VStack {
                if edges.contains(.bottom) {
                    Spacer()
                    color.frame(height: width)
                }
            }
        )
    }
}

struct TabItemView: View {
    let tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Spacer().frame(width: 14)
                Text(tab.title)
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("No Requests")
                .font(.title2)
                .padding(.bottom, 2)
            Text("New Request (⌘ N)")
                .font(.subheadline)
            Text("New Folder (⌘ ⇧ N)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                TextField("Search requests", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.leading, 28)
            }
            .frame(height: 28)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(8)
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
    @State private var statusText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var task: URLSessionTask?
    @State private var selectedBodyType = BodyType.urlEncoded

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
        urlRequest.httpMethod = selectedMethod

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
                self.selectedResponseTab = 0  // Switch to Pretty view
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

    var body: some View {
        HSplitView {
            // Request Panel
            VStack(spacing: 16) {
                HStack {
                    Picker("", selection: $selectedMethod) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                        Text("PATCH").tag("PATCH")
                        Text("DELETE").tag("DELETE")
                        Text("OPTIONS").tag("OPTIONS")
                        Text("QUERY").tag("QUERY")
                        Text("HEAD").tag("HEAD")
                    }
                    .labelsHidden()
                    .fixedSize()

                    TextField(
                        "Enter URL", text: $currentURL,
                        onCommit: {
                            Task { await sendRequest() }
                        }
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())

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

                        if selectedBodyType == .noBody {
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
                        } else {
                            Text("Content for \(selectedBodyType.rawValue)")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        // Pretty JSON View
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
