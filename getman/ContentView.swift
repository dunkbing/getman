import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var searchText = ""
    @State private var tabs: [APIRequest] = []
    @State private var selectedReqId: UUID?

    @State private var selectionIds = AppModel.Selection()
    @State private var draggingIds = AppModel.Selection()

    private var detailItemsSelected: [Item] {
        appModel.itemsFind(ids: selectionIds)
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)

                Group {
                    if appModel.isEmpty {
                        EmptyStateView()
                    } else {
                        VStack {
                            List(selection: $selectionIds) {
                                Node(parent: appModel.bootstrapRoot) { req in
                                    selectedReqId = req.id
                                    openRequest(req)
                                }
                            }
                            .listStyle(.sidebar)
                            SearchBar(searchText: $searchText)
                        }
                    }
                }
            }
            .frame(minWidth: 200, maxWidth: 300)
        } detail: {
            if tabs.isEmpty {
                WelcomeView {
                    createNewRequest()
                }
            } else {
                ZStack(alignment: .topLeading) {
                    TabView(selection: $selectedReqId) {
                        ForEach($tabs) { $tab in
                            RequestResponseView(request: $tab)
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
            if let selectedReq = tabs.first(where: { $0.id == newId }) {
                appModel.selectedRequestId = selectedReq.id
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: createNewRequest) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func openRequest(_ request: APIRequest) {
        if let existingTab = tabs.first(where: { $0.id == request.id }) {
            selectedReqId = existingTab.id
        } else {
            tabs.append(request)
            selectedReqId = request.id
        }
    }

    private func createNewRequest() {
        let newRequest = APIRequest.new()
        let item = Item(newRequest.name, request: newRequest)
        appModel.addChild(item: item)
        tabs.append(newRequest)
        selectedReqId = newRequest.id
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
