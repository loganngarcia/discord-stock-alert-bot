//
//  StockupApp.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI

@main
struct StockupApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 340, minHeight: 600)
                .clipShape(RoundedRectangle(cornerRadius: 20)) // macOS 26 increased corner radius
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1000, height: 700)
        .commands {
            // Remove default window title
            CommandGroup(replacing: .appInfo) {}
        }
    }
}
