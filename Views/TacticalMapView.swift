//
//  TacticalMapView.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | MapKit, Custom Annotations & Geofencing HUD
//

import SwiftUI
import MapKit
import SwiftData

/// Primary tactical operations view displaying the Somaiya campus tactical satellite map,
/// geofence perimeters, dynamic quest radar rings, and proximity-locked scanner activation.
public struct TacticalMapView: View {
    
    // MARK: - SwiftData & Dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.title) private var allQuests: [Quest]
    
    // Observed Location Service
    @Bindable var locationManager: LocationManager
    
    // MARK: - Map State (iOS 17)
    @State private var cameraPosition: MapCameraPosition = .region(SomaiyaCampusConfig.campusRegion)
    @State private var selectedQuest: Quest?
    @State private var activeScanningQuest: Quest?
    @State private var showBriefingSheet: Bool = false
    @State private var showDebugDrawer: Bool = false
    
    public init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    public var body: some View {
        ZStack {
            // MARK: 1. Native iOS 17 Hard-Bounded Campus Map
            Map(
                position: $cameraPosition,
                bounds: SomaiyaCampusConfig.campusMapCameraBounds
            ) {
                // User Location Custom Pin with Animated Radar Pulse
                if let userLoc = locationManager.userLocation {
                    Annotation("Operative", coordinate: userLoc) {
                        RadarPulseView(heading: locationManager.heading)
                    }
                }
                
                // Quest Perimeter Circles & Tactical Pins
                ForEach(allQuests) { quest in
                    let isPlayerInside = locationManager.isPlayerInside(quest: quest)
                    
                    // MapCircle geofence zone indicator
                    // Color shifts from Cyan/Neutral to Neon Radioactive Green when inside radius!
                    MapCircle(center: quest.coordinate, radius: quest.radiusMeters)
                        .foregroundStyle(
                            quest.isCompleted
                            ? Color.purple.opacity(0.18)
                            : (isPlayerInside
                               ? Color(red: 0.2, green: 1.0, blue: 0.2, opacity: 0.28)
                               : Color(red: 0.0, green: 0.7, blue: 1.0, opacity: 0.20))
                        )
                        .stroke(
                            quest.isCompleted
                            ? Color.purple.opacity(0.8)
                            : (isPlayerInside
                               ? Color(red: 0.2, green: 1.0, blue: 0.2)
                               : Color(red: 0.0, green: 0.85, blue: 1.0)),
                            lineWidth: isPlayerInside ? 2.5 : 1.5
                        )
                    
                    // Tactical Landmark Annotation Pin
                    Annotation(quest.title, coordinate: quest.coordinate) {
                        QuestPinView(
                            quest: quest,
                            isPlayerInside: isPlayerInside,
                            isSelected: selectedQuest?.id == quest.id
                        )
                        .onTapGesture {
                            selectedQuest = quest
                            showBriefingSheet = true
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .colorScheme(.dark) // Cyberpunk dark mode map
            .edgesIgnoringSafeArea(.all)
            
            // MARK: 2. Tactical Telemetry Overlay (Top Header)
            VStack(spacing: 0) {
                tacticalTopHUD
                Spacer()
                tacticalBottomCommandCard
            }
            
            // MARK: 3. Collapsible Simulator Teleport Drawer (Debug Tool)
            if showDebugDrawer {
                simulationControlOverlay
            }
        }
        .sheet(item: $activeScanningQuest) { quest in
            ScannerView(quest: quest)
        }
        .sheet(item: $selectedQuest) { quest in
            QuestDetailSheet(
                quest: quest,
                locationManager: locationManager,
                onInitiateScan: {
                    activeScanningQuest = quest
                    selectedQuest = nil
                }
            )
            .presentationDetents([.fraction(0.45), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            locationManager.startTracking()
            // Auto-select nearest uncompleted quest on load
            if let nearest = locationManager.nearestActiveQuest(from: allQuests) {
                selectedQuest = nearest.quest
            }
        }
    }
    
    // MARK: - Tactical Top HUD
    
    private var tacticalTopHUD: some View {
        VStack(spacing: 6) {
            HStack {
                // Cyberpunk Header Title
                HStack(spacing: 8) {
                    Circle()
                        .fill(locationManager.isInsideCampus ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: locationManager.isInsideCampus ? Color.green : Color.red, radius: 4)
                    
                    Text("GEOHUNTER")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    
                    Text("// SOMAIYA")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Debug Teleport Button for Quick Testing
                Button {
                    withAnimation(.spring()) { showDebugDrawer.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("SIM-GPS")
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(red: 1.0, green: 0.7, blue: 0.0), lineWidth: 1)
                    )
                }
            }
            
            // Live Coordinate Bar
            HStack {
                if let loc = locationManager.userLocation {
                    Text(String(format: "LAT: %.4f° N  LON: %.4f° E", loc.latitude, loc.longitude))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))
                } else {
                    Text("ACQUIRING GPS LOCK...")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(locationManager.isInsideCampus ? "CAMPUS GEOFENCE: ACTIVE" : "OUTSIDE PERIMETER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(locationManager.isInsideCampus ? .green : .red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(red: 0.04, green: 0.06, blue: 0.09).opacity(0.92)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.4)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Tactical Bottom Command Card
    
    private var tacticalBottomCommandCard: some View {
        let nearestInfo = locationManager.nearestActiveQuest(from: allQuests)
        let targetQuest = selectedQuest ?? nearestInfo?.quest
        let isInsideTargetRadius = targetQuest.flatMap { locationManager.isPlayerInside(quest: $0) } ?? false
        let distanceMeters = targetQuest.flatMap { locationManager.distance(to: $0) }
        
        return VStack(spacing: 12) {
            if let quest = targetQuest {
                // Active Target Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("ACTIVE OBJECTIVE:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Text(quest.id)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        }
                        
                        Text(quest.title)
                            .font(.system(size: 17, weight: .black, design: .default))
                            .foregroundColor(.white)
                        
                        Text("TARGET: [ \(quest.targetLabelsDisplay.uppercased()) ]")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(red: 0.2, green: 1.0, blue: 0.5))
                    }
                    
                    Spacer()
                    
                    // Sector Proximity Status Badge
                    VStack(alignment: .trailing, spacing: 2) {
                        if let dist = distanceMeters {
                            Text(String(format: "%.0f m", dist))
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(isInsideTargetRadius ? .green : .cyan)
                            
                            Text(isInsideTargetRadius ? "ZONE BREACHED" : "SECTOR RANGE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(isInsideTargetRadius ? .green : .gray)
                        }
                    }
                }
                
                // Scanner Activation Button (Proximity Validated)
                Button {
                    activeScanningQuest = quest
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isInsideTargetRadius ? "viewfinder" : "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(isInsideTargetRadius ? "ACTIVATE OPTICAL SCANNER" : "PROXIMITY LOCKED (MOVE WITHIN \(Int(quest.radiusMeters))m)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isInsideTargetRadius
                        ? LinearGradient(
                            colors: [Color(red: 0.0, green: 0.9, blue: 0.4), Color(red: 0.0, green: 0.6, blue: 0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color(white: 0.15), Color(white: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(isInsideTargetRadius ? .black : Color(white: 0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isInsideTargetRadius
                                ? Color(red: 0.2, green: 1.0, blue: 0.4)
                                : Color(white: 0.25),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: isInsideTargetRadius ? Color.green.opacity(0.4) : .clear, radius: 10)
                }
                .disabled(!isInsideTargetRadius)
            } else {
                // All Quests Completed Banner
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("ALL CAMPUS SECTORS SECURED")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(
            Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.95)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .overlay(
                    TacticalCornerBrackets(color: Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.6), size: 14, strokeWidth: 1.5)
                        .padding(4)
                )
        )
    }
    
    // MARK: - Simulation Control Overlay
    
    private var simulationControlOverlay: some View {
        VStack {
            Spacer().frame(height: 70)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("[ TACTICAL SIMULATION RELAY ]")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    Spacer()
                    Button {
                        withAnimation { showDebugDrawer = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Select a campus zone to teleport the operative for instant testing:")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                
                ForEach(allQuests) { quest in
                    Button {
                        locationManager.simulateTeleportInside(quest: quest)
                        selectedQuest = quest
                        withAnimation { showDebugDrawer = false }
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Teleport inside: \(quest.title)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                            Spacer()
                            Text("(\(Int(quest.radiusMeters))m)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(white: 0.15))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                }
                
                Button {
                    locationManager.simulateCampusCenter()
                    withAnimation { showDebugDrawer = false }
                } label: {
                    HStack {
                        Image(systemName: "scope")
                        Text("Teleport to Somaiya Campus Center")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(white: 0.12))
                    .cornerRadius(6)
                    .foregroundColor(.cyan)
                }
            }
            .padding(14)
            .background(Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.98))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            Spacer()
        }
    }
}

// MARK: - QuestPinView

private struct QuestPinView: View {
    let quest: Quest
    let isPlayerInside: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Hexagonal or circular tactical pin base
                Circle()
                    .fill(
                        quest.isCompleted
                        ? Color.purple
                        : (isPlayerInside ? Color(red: 0.1, green: 0.9, blue: 0.3) : Color(red: 0.0, green: 0.5, blue: 0.9))
                    )
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.black.opacity(0.4), lineWidth: isSelected ? 2.5 : 1.5)
                    )
                    .shadow(
                        color: isPlayerInside ? Color.green : Color.cyan,
                        radius: isPlayerInside ? 8 : 4
                    )
                
                Image(systemName: quest.isCompleted ? "checkmark.seal.fill" : quest.badgeIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(quest.isCompleted ? .white : (isPlayerInside ? .black : .white))
            }
            
            // Pin title badge
            Text(quest.title)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.85))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isPlayerInside ? Color.green : Color.cyan.opacity(0.5), lineWidth: 0.8)
                )
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
