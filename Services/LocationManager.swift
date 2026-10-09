//
//  LocationManager.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Modern @Observable & CoreLocation
//

import Foundation
import CoreLocation
import Observation

/// Real-time GPS and Geofencing Service for Somaiya Campus.
/// Utilizes iOS 17 `@Observable` to drive UI updates with zero Combine boilerplate.
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Published / Observed State
    
    /// Current verified GPS coordinate of the operative
    public var userLocation: CLLocationCoordinate2D?
    
    /// Operative heading (direction facing in degrees)
    public var heading: Double = 0.0
    
    /// CoreLocation authorization status
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// True if the user is strictly within the K. J. Somaiya Vidyavihar campus boundaries
    public var isInsideCampus: Bool = false
    
    /// Human-readable error message if GPS signal fails or permissions are denied
    public var errorMessage: String?
    
    /// Simulator debugging toggle to teleport operative directly to campus locations
    public var isSimulationMode: Bool = false
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1.0 // Trigger update every 1 meter
        locationManager.headingFilter = 5.0  // Trigger update every 5 degrees
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permissions & Lifecycle
    
    public func requestPermissions() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func startTracking() {
        requestPermissions()
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    public func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Geofencing & Proximity Logic
    
    /// Calculates distance in meters from the player to a target quest coordinate
    public func distance(to quest: Quest) -> CLLocationDistance? {
        guard let userLoc = userLocation else { return nil }
        let playerLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let questLocation = CLLocation(latitude: quest.latitude, longitude: quest.longitude)
        return playerLocation.distance(from: questLocation)
    }
    
    /// Determines if the operative has physically breached the target quest's geofenced radius
    public func isPlayerInside(quest: Quest) -> Bool {
        guard let dist = distance(to: quest) else { return false }
        return dist <= quest.radiusMeters
    }
    
    /// Finds the nearest available active (uncompleted) quest to the player
    public func nearestActiveQuest(from quests: [Quest]) -> (quest: Quest, distance: CLLocationDistance)? {
        guard let userLoc = userLocation else { return nil }
        let playerLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        let uncompleted = quests.filter { !$0.isCompleted }
        guard !uncompleted.isEmpty else { return nil }
        
        var nearest: (quest: Quest, distance: CLLocationDistance)? = nil
        for q in uncompleted {
            let qLoc = CLLocation(latitude: q.latitude, longitude: q.longitude)
            let dist = playerLocation.distance(from: qLoc)
            if nearest == nil || dist < nearest!.distance {
                nearest = (q, dist)
            }
        }
        return nearest
    }
    
    // MARK: - Debug / Simulation Teleportation
    
    /// Teleports the player to a specific campus coordinate for testing without leaving the desk
    public func simulateTeleport(to coordinate: CLLocationCoordinate2D) {
        self.isSimulationMode = true
        self.userLocation = coordinate
        self.isInsideCampus = SomaiyaCampusConfig.isWithinCampus(coordinate: coordinate)
    }
    
    /// Quick teleport to Somaiya campus center
    public func simulateCampusCenter() {
        simulateTeleport(to: SomaiyaCampusConfig.campusCenter)
    }
    
    /// Quick teleport inside a specific quest zone
    public func simulateTeleportInside(quest: Quest) {
        // Offset slightly (10 meters north) to simulate standing comfortably inside the radius
        let deltaLat = 10.0 / 111_000.0
        let coord = CLLocationCoordinate2D(latitude: quest.latitude + deltaLat, longitude: quest.longitude)
        simulateTeleport(to: coord)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.errorMessage = nil
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        case .denied, .restricted:
            self.errorMessage = "Access Denied: GPS permission required to track campus operative."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isSimulationMode else { return } // Keep simulation overrides active if enabled
        guard let latest = locations.last else { return }
        
        self.userLocation = latest.coordinate
        self.isInsideCampus = SomaiyaCampusConfig.isWithinCampus(coordinate: latest.coordinate)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = "Tactical GPS Warning: \(error.localizedDescription)"
    }
}
