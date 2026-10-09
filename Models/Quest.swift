//
//  Quest.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | SwiftData Persistence
//

import Foundation
import SwiftData
import CoreLocation

/// Persistent data model for tactical campus scavenger quests.
/// Backed by SwiftData with on-disk storage for captured encrypted images.
@Model
public final class Quest: Identifiable {
    
    // MARK: - Identity & Metadata
    @Attribute(.unique) public var id: String
    public var title: String
    public var sectorName: String
    public var missionBrief: String
    public var targetLabels: [String]
    public var badgeIcon: String
    
    // MARK: - Geolocation Specifications
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    
    // MARK: - Completion & Captured Intel
    public var isCompleted: Bool
    public var capturedTimestamp: Date?
    public var verifiedLabel: String?
    public var matchConfidence: Double?
    
    /// Stored externally on disk via SwiftData to prevent memory bloat
    @Attribute(.externalStorage) public var filteredImageData: Data?
    
    // MARK: - Computed Properties
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var targetLabelsDisplay: String {
        targetLabels.joined(separator: " / ")
    }
    
    // MARK: - Initializer
    
    public init(
        id: String,
        title: String,
        sectorName: String,
        missionBrief: String,
        targetLabels: [String],
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        badgeIcon: String,
        isCompleted: Bool = false,
        capturedTimestamp: Date? = nil,
        verifiedLabel: String? = nil,
        matchConfidence: Double? = nil,
        filteredImageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.sectorName = sectorName
        self.missionBrief = missionBrief
        self.targetLabels = targetLabels
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.badgeIcon = badgeIcon
        self.isCompleted = isCompleted
        self.capturedTimestamp = capturedTimestamp
        self.verifiedLabel = verifiedLabel
        self.matchConfidence = matchConfidence
        self.filteredImageData = filteredImageData
    }
    
    /// Convenience initializer mapping from a seed configuration
    public convenience init(from seed: SomaiyaCampusConfig.SeedQuestDefinition) {
        self.init(
            id: seed.id,
            title: seed.title,
            sectorName: seed.sectorName,
            missionBrief: seed.missionBrief,
            targetLabels: seed.targetLabels,
            latitude: seed.coordinate.latitude,
            longitude: seed.coordinate.longitude,
            radiusMeters: seed.radiusMeters,
            badgeIcon: seed.badgeIcon
        )
    }
}
