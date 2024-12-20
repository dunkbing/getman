//
//  SideBarView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 5/12/24.
//

import SwiftUI

struct SideBarView: View {
    @EnvironmentObject var appModel: AppModel
    @Binding var selectionIds: AppModel.Selection
    @Binding var searchText: String
    @Binding var selectedReqId: UUID?

    let onRequestSelected: (APIRequest) -> Void
    let onRequestDeleted: (UUID) -> Void

    var body: some View {
        Group {
            if appModel.isEmpty {
                EmptySideBarView()
                    .contextMenu {
                        Button("New Request") {
                            let request = appModel.createNewRequest(parentItem: nil)
                            onRequestSelected(request)
                            appModel.selectedRequestId = request.id
                        }
                        Button("New Folder") {
                            appModel.createNewFolder(parentItem: nil)
                        }
                    }
            } else {
                VStack {
                    List(selection: $selectionIds) {
                        Node(
                            parent: appModel.bootstrapRoot,
                            onRequestSelected: { req in
                                selectedReqId = req.id
                                onRequestSelected(req)
                            },
                            onRequestDeleted: onRequestDeleted
                        )
                    }
                    .listStyle(.sidebar)
                    .contextMenu {
                        Button("New Request") {
                            let request = appModel.createNewRequest(parentItem: nil)
                            onRequestSelected(request)
                            appModel.selectedRequestId = request.id
                        }
                        Button("New Folder") {
                            appModel.createNewFolder(parentItem: nil)
                        }
                    }
                    SearchBar(searchText: $searchText)
                }
            }
        }
    }
}

struct EmptySideBarView: View {
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
