//
//  PodCastScriptApp.swift
//  PodCastScript
//
//  Created by ezyeun on 3/31/26.
//

import SwiftUI
import SwiftData

@main
struct PodCastScriptApp: App {
    var body: some Scene {
        WindowGroup {
            AppCompositionRoot.makeChannelSearchView()
        }
        // Registers CachedTranscript with the same container used by AppCompositionRoot.
        // This ensures the SwiftUI environment and the manual mainContext share one store.
        .modelContainer(AppCompositionRoot.sharedModelContainer)
    }
}
