//
//  GeoHunterApp.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | SwiftData ModelContainer & Seed Engine
//

import SwiftUI
import SwiftData

@main
struct GeoHunterApp: App {
    
    // Global SwiftData container
    let container: ModelContainer
    
    // Core Location state holder
    @State private var locationManager = LocationManager()
    
    init() {
        do {
            let schema = Schema([Quest.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: [config])
            
            // Seed initial campus quests if database is empty
            seedInitialQuestsIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TacticalMapView(locationManager: locationManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
    
    // MARK: - Auto-Seed Engine
    
    @MainActor
    private func seedInitialQuestsIfNeeded(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Quest>()
            let existingCount = try context.fetchCount(descriptor)
            
            if existingCount == 0 {
                print("⚡️ [GeoHunter Engine] Seeding Somaiya Campus Quests...")
                for seed in SomaiyaCampusConfig.seedQuests {
                    let newQuest = Quest(from: seed)
                    context.insert(newQuest)
                }
                try context.save()
                print("✅ [GeoHunter Engine] Successfully seeded \(SomaiyaCampusConfig.seedQuests.count) tactical quests.")
            }
        } catch {
            print("⚠️ [GeoHunter Engine] Failed to seed initial quests: \(error.localizedDescription)")
        }
    }
}
