//
//  brew_sixtyApp.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI
import SwiftData

@main
struct brew_sixtyApp: App {
    private let sharedModelContainer: ModelContainer

    init() {
        ReadmeCaptureConfiguration.prepareUserDefaults()

        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: ReadmeCaptureConfiguration.isEnabled)
            sharedModelContainer = try ModelContainer(
                for: BrewLog.self,
                BrewTemplate.self,
                configurations: configuration
            )

            try ReadmeCaptureConfiguration.seedDemoDataIfNeeded(in: sharedModelContainer.mainContext)
        } catch {
            fatalError("Failed to configure model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
