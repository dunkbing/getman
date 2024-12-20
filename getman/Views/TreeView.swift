//
//  TreeView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 1/12/24.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class AppModel: ObservableObject {
    typealias Selection = Set<Item.Id>

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    @Published var bootstrapRoot: Item
    @Published var isDragging: Bool = false
    @Published var selectedRequestId: UUID?
    @Published var isEmpty: Bool = true

    init() {
        do {
            let schema = Schema([Item.self, APIRequest.self, KeyValuePair.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext

            // Try to load existing root item
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate<Item> { item in
                    item.parent == nil
                }
            )

            let existingRoots = try modelContext.fetch(descriptor)

            if let existingRoot = existingRoots.first {
                bootstrapRoot = existingRoot
            } else {
                bootstrapRoot = Item("__BOOTSTRAP_ROOT_ITEM")
                modelContext.insert(bootstrapRoot)
                try modelContext.save()
            }

            isEmpty = bootstrapRoot.children?.isEmpty ?? true

        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }

    func addChild(item: Item) {
        bootstrapRoot.adopt(child: item)
        updateIsEmpty()
    }

    private func updateIsEmpty() {
        isEmpty = bootstrapRoot.children?.isEmpty ?? true
    }

    func providerEncode(id: Item.Id) -> NSItemProvider {
        NSItemProvider(object: id.uuidString as NSString)
    }

    func providerDecode(loadedString: String?) -> [Item] {
        guard let possibleStringOfConcatIds: String = loadedString as String? else {
            return []
        }

        let decodedItems: [Item] =
            possibleStringOfConcatIds
            .split(separator: ",")
            .map { String($0) }
            .compactMap({ UUID(uuidString: $0) })
            .compactMap({ self.itemFindInTrees(id: $0) })

        return decodedItems
    }

    func itemFindInTrees(id: Item.Id) -> Item? {
        Item.findDescendant(with: id, inTreesWithRoots: [bootstrapRoot])
    }

    func itemsFind(ids: Set<Item.Id>) -> [Item] {
        ids.compactMap { id in
            itemFindInTrees(id: id)
        }
    }

    func itemIdsToMove(dragItemId: Item.Id, selectionIds: Selection) -> [Item.Id] {
        let asArray = itemsToMove(dragItemId: dragItemId, selectionIds: selectionIds)
            .map({ $0.id })
        return asArray
    }

    func itemsToMove(dragItemId: Item.Id, selectionIds: Selection) -> [Item] {
        let withPossibleChildrenIds =
            selectionIds.count == 0 || selectionIds.contains(dragItemId) == false
            ? [dragItemId]
            : selectionIds

        // Map to items and remove any ids that are not in the tree
        let inSystemWithPossibleChildrenItems =
            withPossibleChildrenIds
            .compactMap { id in
                itemFindInTrees(id: id)
            }

        // Remove any in the selection that are descendents of other items in the selection i.e. only need to reparent the
        // the top most item.
        let notMovedByOthersInSelection =
            inSystemWithPossibleChildrenItems
            .filter { item in
                item.isDescendant(ofAnyOf: inSystemWithPossibleChildrenItems) != true
            }

        return notMovedByOthersInSelection
    }

    func itemsToMoveIsValid(for possibleMovers: [Item.Id], into tgtFolder: Item) -> Bool {
        for i in possibleMovers.indices {
            // Invalid to move to self to self
            if possibleMovers[i] == tgtFolder.id {
                // print("Invalid move: attempting move an item into its self")
                return false
            }

            // Invalid to move root folders
            if itemFindInTrees(id: possibleMovers[i])?.parent == nil {
                // print("Invalid move: attempting to move a root item, i.e. one that has no parents")
                return false
            }
        }
        return true
    }

    func itemsMove(_ possibleMovers: [Item.Id], into tgtFolder: Item) {
        guard itemsToMoveIsValid(for: possibleMovers, into: tgtFolder) else {
            return
        }

        // Remove any items not in the system
        let possibleMoversExtant: [Item] = itemsFind(ids: Set(possibleMovers))

        // Remove any items that already have this folder as their parent.
        let notExistingChild = possibleMoversExtant.filter({
            if let parentId = $0.parent?.id, parentId == tgtFolder.id {
                return false
            } else {
                return true
            }
        })

        // Remove any in the selection that are descendents of other items in the selection i.e. only need to reparent the
        let notMovedByOthers = notExistingChild.filter { item in
            item.isDescendant(ofAnyOf: notExistingChild) != true
        }

        DispatchQueue.main.async {
            withAnimation {
                notMovedByOthers.forEach { i in
                    tgtFolder.adopt(child: i)
                }
                self.updateIsEmpty()
                self.objectWillChange.send()
            }
        }
    }
}

extension AppModel {
    func createNewRequest(parentItem: Item?) -> APIRequest {
        let request = APIRequest(
            name: "New Request",
            url: "",
            method: .GET
        )
        let item = Item("New Request", request: request)

        if let parent = parentItem {
            parent.adopt(child: item)
        } else {
            addChild(item: item)
        }
        save()
        return request
    }

    func createNewFolder(parentItem: Item?) {
        let folder = Item("New Folder", isFolder: true)
        if let parent = parentItem {
            parent.adopt(child: folder)
        } else {
            addChild(item: folder)
        }
        save()
    }
}

@Model
final class Item: ObservableObject, Identifiable, Equatable {
    typealias Id = UUID

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID
    var name: String
    var isFolder: Bool
    var request: APIRequest?
    var children: [Item]?
    var parent: Item?
    var read: Bool

    init(
        id: UUID = UUID(),
        _ name: String,
        request: APIRequest? = nil,
        isFolder: Bool = false,
        children: [Item]? = nil,
        read: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isFolder = isFolder
        self.children = children
        self.read = read
        self.request = request

        self.children?.forEach { item in
            item.parent = self
        }
    }

    func adopt(child adopteeItem: Item) {
        // Prevent accidentally adopting itself
        guard id != adopteeItem.id else {
            print("Rejecting adoption, of \(adopteeItem.name) - tried to adopt self ")
            return
        }

        // Prevent accidentally having a child adopt  one of its ancestors
        guard isDescendant(of: adopteeItem) != true else {
            print(
                "Rejecting adoption, of \(adopteeItem.name) - tried to have one of its descendants adopt it"
            )
            return
        }

        // If child has existing parent then remove it
        if let childsOriginalParent = adopteeItem.parent,
            let childsOriginalParentKids = childsOriginalParent.children
        {
            let remainingKids = childsOriginalParentKids.filter({ $0 != adopteeItem })

            if remainingKids.count == 0 {
                childsOriginalParent.children = []
            } else {
                childsOriginalParent.children = remainingKids
            }
        }

        // Add the item to the adopter's list of kids and update  the adoptee
        children = (children ?? []) + [adopteeItem]
        adopteeItem.parent = self
    }

    static func findDescendant(with id: Id?, inTreesWithRoots items: [Item]) -> Item? {
        guard let id = id else { return nil }

        return items.reduce(nil) { previouslyFoundItem, item in

            // Only find the first value & then don't repeat (& accidentally overwrite)
            guard previouslyFoundItem == nil else { return previouslyFoundItem }

            if item.id == id {
                return item
            }

            guard let children = item.children else {
                return nil
            }

            return findDescendant(with: id, inTreesWithRoots: children)
        }
    }

    func isDescendant(ofAnyOf possibleParents: [Item]) -> Bool {
        let found = possibleParents.first(where: { self.isDescendant(of: $0) })

        return found == nil ? false : true
    }

    func isDescendant(of possibleParent: Item) -> Bool {
        Self.isDescendant(item: self, of: possibleParent)
    }

    static func isDescendant(item: Item, of possibleParent: Item) -> Bool {
        guard let parentChildren = possibleParent.children else {
            return false
        }

        if findDescendant(with: item.id, inTreesWithRoots: parentChildren) == nil {
            return false
        } else {
            return true
        }
    }

    static func findAncestors(for item: Item, backTo possibleAncestor: Item?) -> [Item] {
        if let parent = item.parent {
            if let possibleAncestor = possibleAncestor, parent == possibleAncestor {
                return [parent]
            } else {
                return [parent] + findAncestors(for: parent, backTo: possibleAncestor)
            }

        } else {
            return []
        }
    }
}

struct Node: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var parent: Item
    let onRequestSelected: (APIRequest) -> Void
    let onRequestDeleted: (UUID) -> Void
    @State private var isEditing = false
    @State private var newName = ""

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ForEach(parent.children ?? []) { (childItem: Item) in
            Group {
                if childItem.isFolder == false {
                    let req = childItem.request
                    let method = req?.method ?? .GET
                    HStack(spacing: 3) {
                        Text(method.rawValue)
                            .font(.caption)
                            .bold()
                            .foregroundColor(method.color)
                            .frame(minWidth: 36)
                            .padding(.leading, 4)

                        if isEditing && appModel.selectedRequestId == childItem.request?.id {
                            TextField(
                                "Name", text: $newName,
                                onCommit: {
                                    if !newName.isEmpty {
                                        childItem.name = newName
                                        appModel.save()
                                    }
                                    isEditing = false
                                    isTextFieldFocused = false
                                }
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onAppear {
                                isTextFieldFocused = true
                            }
                        } else {
                            Text(childItem.name)
                        }
                    }
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                req?.id == appModel.selectedRequestId
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                    )
                    .onTapGesture {
                        if let request = childItem.request {
                            onRequestSelected(request)
                            appModel.selectedRequestId = request.id
                        }
                    }
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: req?.id == appModel.selectedRequestId
                    )
                    .onDrag {
                        appModel.providerEncode(id: childItem.id)
                    }
                    .contextMenu {
                        Button("Rename") {
                            newName = childItem.name
                            isEditing = true
                        }
                        Button("New Request") {
                            let request = appModel.createNewRequest(parentItem: parent)
                            onRequestSelected(request)
                            appModel.selectedRequestId = request.id
                        }
                        Button("New Folder") {
                            appModel.createNewFolder(parentItem: parent)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            if let parentChildren = parent.children {
                                parent.children = parentChildren.filter { $0.id != childItem.id }
                                if let requestId = childItem.request?.id {
                                    onRequestDeleted(requestId)
                                }
                                appModel.save()
                            }
                        }
                    }
                } else {
                    Parent(
                        item: childItem,
                        onRequestSelected: onRequestSelected,
                        onRequestDeleted: onRequestDeleted
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .selectionDisabled()
        }
    }
}

struct Parent: View, DropDelegate {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item
    let onRequestSelected: (APIRequest) -> Void
    let onRequestDeleted: (UUID) -> Void

    @State private var isExpanded: Bool = false
    @State internal var isTargeted: Bool = false
    @State private var isEditing = false
    @State private var newName = ""

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Node(
                parent: item,
                onRequestSelected: onRequestSelected,
                onRequestDeleted: onRequestDeleted
            )
        } label: {
            Group {
                if item.parent == nil {
                    Label(item.name, systemImage: "folder.badge.questionmark")
                } else {
                    if isEditing {
                        TextField(
                            "Name", text: $newName,
                            onCommit: {
                                if !newName.isEmpty {
                                    item.name = newName
                                    appModel.save()
                                }
                                isEditing = false
                                isTextFieldFocused = false
                            }
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onAppear {
                            isTextFieldFocused = true
                        }
                    } else {
                        Label(item.name, systemImage: "folder")
                    }
                }
            }
            .padding(.leading, 3.5)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isTargeted ? Color.accentColor.opacity(0.3) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isTargeted ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
        }
        .onDrop(of: [.text], delegate: self)
        .contextMenu {
            if item.parent != nil {
                Button("Rename") {
                    newName = item.name
                    isEditing = true
                }
            }
            Button("New Request") {
                let request = appModel.createNewRequest(parentItem: item)
                onRequestSelected(request)
                appModel.selectedRequestId = request.id
            }
            Button("New Folder") {
                appModel.createNewFolder(parentItem: item)
            }
            if item.parent != nil {
                Divider()
                Button("Delete", role: .destructive) {
                    if let parentItem = item.parent,
                        let parentChildren = parentItem.children
                    {
                        let requestIds = collectRequestIds(from: item)
                        parentItem.children = parentChildren.filter { $0.id != item.id }
                        // remove all requests in the folder from tabs
                        requestIds.forEach { onRequestDeleted($0) }
                        appModel.save()
                    }
                }
            }
        }
    }

    private func collectRequestIds(from item: Item) -> [UUID] {
        var ids: [UUID] = []
        if let request = item.request {
            ids.append(request.id)
        }
        if let children = item.children {
            for child in children {
                ids.append(contentsOf: collectRequestIds(from: child))
            }
        }
        return ids
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.text])

        providers.forEach { provider in
            _ = provider.loadObject(ofClass: String.self) { (string, error) in
                DispatchQueue.main.async {
                    let itemsToMove = appModel.providerDecode(loadedString: string)
                    for itemToMove in itemsToMove {
                        // Check if the move is valid
                        if itemToMove.id != item.id && !item.isDescendant(of: itemToMove) {
                            withAnimation {
                                item.adopt(child: itemToMove)
                            }
                        }
                    }
                }
            }
        }

        isTargeted = false
        return true
    }
}
