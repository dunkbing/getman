//
//  TreeView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 1/12/24.
//

import Foundation
import SwiftUI

class AppModel: ObservableObject {
    typealias Selection = Set<Item.Id>

    init(items: [Item]) {
        itemsAtTopLevel = items
        bootstrapRoot = Item("__BOOTSTRAP_ROOT_ITEM")
        items.forEach { item in
            bootstrapRoot.adopt(child: item)
        }
        isEmpty = bootstrapRoot.children?.isEmpty ?? true
    }

    func addChild(item: Item) {
        bootstrapRoot.adopt(child: item)
        updateIsEmpty()
    }

    @Published var itemsAtTopLevel: [Item]
    @Published var isDragging: Bool = false
    @Published var bootstrapRoot: Item
    @Published var selectedRequestId: UUID?
    @Published var isEmpty: Bool = true

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

class Item: ObservableObject, Identifiable, Equatable {
    typealias Id = UUID

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    let id = Id()
    let isFolder: Bool
    let name: String
    var request: APIRequest?

    @Published var children: [Item]?
    @Published var parent: Item?
    @Published var read: Bool

    init(
        _ name: String, request: APIRequest? = nil, isFolder: Bool = false, children: [Item]? = nil,
        read: Bool = false
    ) {
        self.name = name
        self.isFolder = isFolder
        self.children = children
        self.read = read
        self.request = request

        self.children?.forEach({ item in
            item.parent = self
        })
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
    @State private var forceUpdate = false
    let onRequestSelected: (APIRequest) -> Void

    var body: some View {
        ForEach(parent.children ?? []) { (childItem: Item) in
            Group {
                if childItem.isFolder == false {
                    let req = childItem.request
                    let method = req?.method ?? .GET
                    Label {
                        Text(childItem.name)
                            .padding(.leading, 5)
                    } icon: {
                        Text(method.rawValue)
                            .font(.caption)
                            .bold()
                            .foregroundColor(method.color)
                            .frame(minWidth: 40)
                            .padding(.leading, 5)
                    }
                    .padding(.vertical, 3)
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                req?.id == appModel.selectedRequestId
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                    )
                    .contentShape(Rectangle())
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
                } else {
                    Parent(item: childItem, onRequestSelected: onRequestSelected)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .selectionDisabled()
        }
        .id(forceUpdate)
        .onReceive(appModel.objectWillChange) { _ in
            forceUpdate.toggle()
        }
    }
}

struct Parent: View, DropDelegate {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item
    let onRequestSelected: (APIRequest) -> Void

    @State private var isExpanded: Bool = false
    @State internal var isTargeted: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Node(parent: item, onRequestSelected: onRequestSelected)
        } label: {
            Group {
                if item.parent == nil {
                    Label(item.name, systemImage: "folder.badge.questionmark")
                } else {
                    Label(item.name, systemImage: "folder")
                        .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
                        .onDrag {
                            appModel.providerEncode(id: item.id)
                        }
                }
            }
        }
        .onDrop(of: [.text], delegate: self)
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
