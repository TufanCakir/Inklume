//
//  InklumeApp.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

@main
struct InklumeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
    }
}
