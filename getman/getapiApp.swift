//
//  getapiApp.swift
//  getman
//
//  Created by Bùi Đặng Bình on 29/11/24.
//

import SwiftUI

let topLevelTrash = Item(
    "Trash", isFolder: true,
    children: []
)

let topLevelSpam = Item(
    "Spam", isFolder: true,
    children: [
        Item("[SPAM] Open now!"),
        Item("[SPAM] Limited time offer"),
    ]
)

let topLevelInbox = Item(
    "Inbox", isFolder: true,
    children: [
        Item(
            "Friends", isFolder: true,
            children: [
                Item(
                    "FBook", isFolder: true,
                    children: [
                        Item("Mostly harmless"),
                        Item("Re: Mostly harmless"),
                    ]
                ),
                Item("Birthday party"),
                Item("Re: Birthday party"),
            ]),
        Item(
            "Work", isFolder: true,
            children: [
                Item("Next meeting"),
                Item("Team building"),
            ]
        ),
        Item("Holidays!"),
        Item("Report needed"),
    ]
)

let TestData = [
    topLevelInbox,
    topLevelSpam,
    topLevelTrash,
]

@main
struct getmanApp: App {
    @StateObject private var model = AppModel(items: TestData)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
