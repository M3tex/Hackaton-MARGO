//
//  HackatonMARGOApp.swift
//  HackatonMARGO
//
//  Created by Mathis Sedkaoui on 13/03/2025.
//

import SwiftUI
import SwiftData
import CoreLocation

@main
struct HackatonMARGOApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        // Accès à la position
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
