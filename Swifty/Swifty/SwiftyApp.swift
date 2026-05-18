//
//  SwiftyApp.swift
//  Swifty
//
//  Created by Ethan on 20.04.2026.
//

import SwiftUI

@main
struct SwiftyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, idealWidth: 760, minHeight: 520, idealHeight: 720)
        }
        .defaultSize(width: 760, height: 720)
        .windowResizability(.contentSize)
    }
}
