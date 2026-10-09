//
//  SomaiyaCampusConfig.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Modern SwiftUI & Swift Concurrency
//

import Foundation
import CoreLocation
import MapKit

/// Central coordinate repository and geofence perimeter configuration
/// for K. J. Somaiya Vidyavihar campus, Mumbai.
public enum SomaiyaCampusConfig {
    
    // MARK: - Campus Anchor & Bounds
    
    /// Exact central anchor for K. J. Somaiya Vidyavihar campus
    public static let campusCenter = CLLocationCoordinate2D(
        latitude: 19.0728,
        longitude: 72.8998
    )
    
    /// Strict campus bounding box:
    /// Min Lat: 19.0700°, Max Lat: 19.0760°
    /// Min Lon: 72.8960°, Max Lon: 72.9030°
    public static let minLatitude: Double = 19.0700
    public static let maxLatitude: Double = 19.0760
    public static let minLongitude: Double = 72.8960
    public static let maxLongitude: Double = 72.9030
    
    /// Bounding coordinate region centered on campus
    public static var campusRegion: MKCoordinateRegion {
        let center = campusCenter
        let latSpan = maxLatitude - minLatitude
        let lonSpan = maxLongitude - minLongitude
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latSpan * 1.1, longitudeDelta: lonSpan * 1.1)
        )
    }
    
    /// Camera map bounds restricting MapKit panning strictly within Somaiya campus
    public static var campusMapCameraBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: campusRegion,
            minimumDistance: 100,  // Max zoom-in
            maximumDistance: 1200  // Max zoom-out (prevents zooming away from campus)
        )
    }
    
    /// Validates whether a given GPS coordinate is within the Somaiya campus geofence
    public static func isWithinCampus(coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= minLatitude &&
               coordinate.latitude <= maxLatitude &&
               coordinate.longitude >= minLongitude &&
               coordinate.longitude <= maxLongitude
    }
    
    // MARK: - Pre-seeded Quests Template
    
    public struct SeedQuestDefinition: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let sectorName: String
        public let missionBrief: String
        public let targetLabels: [String]
        public let coordinate: CLLocationCoordinate2D
        public let radiusMeters: Double
        public let badgeIcon: String
    }
    
    /// The three pre-seeded tactical discovery quests for the Somaiya campus
    public static let seedQuests: [SeedQuestDefinition] = [
        SeedQuestDefinition(
            id: "KJSCE-ENG-01",
            title: "Engineering Sector (KJSCE)",
            sectorName: "K.J. Somaiya College of Engineering",
            missionBrief: "Infiltrate the computing labs or central foyer. Scan and register active hardware telemetry.",
            targetLabels: ["Laptop", "Keyboard", "Computer", "Computer keyboard", "Electronics"],
            coordinate: CLLocationCoordinate2D(latitude: 19.0733, longitude: 72.8990),
            radiusMeters: 40.0,
            badgeIcon: "laptopcomputer"
        ),
        SeedQuestDefinition(
            id: "CENTRAL-GREEN-02",
            title: "Central Green / Pathway",
            sectorName: "Campus Boulevard & Amphitheatre Greens",
            missionBrief: "Patrol the central green corridor. Identify carbon-neutral transit or campus flora.",
            targetLabels: ["Bicycle", "Plant", "Tree", "Houseplant", "Flower", "Vehicle"],
            coordinate: CLLocationCoordinate2D(latitude: 19.0725, longitude: 72.9005),
            radiusMeters: 35.0,
            badgeIcon: "bicycle"
        ),
        SeedQuestDefinition(
            id: "STUDENT-HUB-03",
            title: "Student Hub / Canteen",
            sectorName: "Somaiya Central Canteen & Cafeteria",
            missionBrief: "Surveil the refuel zone. Locate vital student hydration or caffeine supplies.",
            targetLabels: ["Coffee cup", "Bottle", "Cup", "Tableware", "Drink", "Coffee"],
            coordinate: CLLocationCoordinate2D(latitude: 19.0718, longitude: 72.8985),
            radiusMeters: 30.0,
            badgeIcon: "cup.and.saucer.fill"
        )
    ]
}
