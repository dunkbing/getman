import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var searchText = ""
    @State private var tabs: [APIRequest] = []
    @State private var selectedReqId: UUID?
    @State private var selectionIds = AppModel.Selection()
    @State private var draggingIds = AppModel.Selection()
    @State private var isSelectionFromTree = false

    @AppStorage("isHorizontalLayout") private var isHorizontalLayout = true
    @AppStorage("isDarkMode") private var isDarkMode = false

    private var detailItemsSelected: [Item] {
        appModel.itemsFind(ids: selectionIds)
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)

                SideBarView(
                    selectionIds: $selectionIds,
                    searchText: $searchText,
                    selectedReqId: $selectedReqId,
                    onRequestSelected: openRequest,
                    onRequestDeleted: removeTab
                )
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
                            RequestResponseView(
                                request: $tab,
                                isHorizontalLayout: isHorizontalLayout
                            )
                            .tag(tab.id)
                        }
                    }

                    CustomTabBar(
                        tabs: $tabs,
                        selectedReqId: $selectedReqId,
                        isSelectionFromTree: $isSelectionFromTree
                    )
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

            ToolbarItemGroup(placement: .automatic) {
                Button(action: toggleTheme) {
                    Image(systemName: isDarkMode ? "sun.max" : "moon")
                        .help(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
                }

                Button(action: { isHorizontalLayout.toggle() }) {
                    Image(systemName: "rectangle.dock")
                        .resizable()
                        .frame(
                            width: isHorizontalLayout ? 16 : 20,
                            height: isHorizontalLayout ? 20 : 16
                        )
                        .rotationEffect(.degrees(isHorizontalLayout ? -90 : 0))
                        .help(
                            isHorizontalLayout
                                ? "Switch to vertical layout"
                                : "Switch to horizontal layout"
                        )
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private func toggleTheme() {
        isDarkMode.toggle()
        if let window = NSApplication.shared.windows.first {
            window.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
        }
    }

    private func openRequest(_ request: APIRequest) {
        if let existingTab = tabs.first(where: { $0.id == request.id }) {
            selectedReqId = existingTab.id
        } else {
            tabs.append(request)
            selectedReqId = request.id
        }
        isSelectionFromTree = true
    }

    private func createNewRequest() {
        let newRequest = APIRequest.new()
        tabs.append(newRequest)
        selectedReqId = newRequest.id
        let item = Item(newRequest.name, request: newRequest)
        appModel.addChild(item: item)
        isSelectionFromTree = true
    }

    private func closeTab(_ tab: APIRequest) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            if selectedReqId == tab.id {
                selectedReqId = tabs.last?.id
            }
        }
    }

    private func removeTab(_ requestId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == requestId }) {
            tabs.remove(at: index)
            if selectedReqId == requestId {
                selectedReqId = tabs.last?.id
            }
        }
    }
}
