//
//  getapiApp.swift
//  getman
//
//  Created by Bùi Đặng Bình on 29/11/24.
//

import SwiftUI

@main
struct getmanApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .backport.thinWindowBg()
                .backport.hiddenToolbar()
                .environmentObject(model)
        }
    }
}
