//
//  splendor_duelApp.swift
//  splendor duel
//
//  Created by Tuan Linh Doan on 18/3/26.
//

import SwiftUI

@main
struct splendor_duelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // CHANGED: Use AppRootView instead of ContentView
            AppRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
