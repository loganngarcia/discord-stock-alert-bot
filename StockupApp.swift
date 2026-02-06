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
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 700)
    }
}
