//
//  QuestDetailSheet.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | SwiftData Intel & Sector Briefing
//

import SwiftUI
import CoreLocation

/// Tactical sector debrief modal showing quest specifications, target labels,
/// geofence radius, and captured visual intel if completed.
public struct QuestDetailSheet: View {
    
    let quest: Quest
    let locationManager: LocationManager
    let onInitiateScan: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    public init(quest: Quest, locationManager: LocationManager, onInitiateScan: @escaping () -> Void) {
        self.quest = quest
        self.locationManager = locationManager
        self.onInitiateScan = onInitiateScan
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Header Status Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.id)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            
                            Text(quest.title)
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.white)
                            
                            Text(quest.sectorName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: quest.isCompleted ? "checkmark.seal.fill" : quest.badgeIcon)
                            .font(.system(size: 36))
                            .foregroundColor(quest.isCompleted ? .purple : .cyan)
                    }
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(12)
                    
                    // Mission Briefing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("[ MISSION DIRECTIVE ]")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(quest.missionBrief)
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.9))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.08))
                    .cornerRadius(10)
                    
                    // Target Detection Specifications
                    VStack(alignment: .leading, spacing: 10) {
                        Text("[ TARGET VERIFICATION SPECS ]")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RECOGNIZE PATTERNS")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(quest.targetLabelsDisplay)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("PERIMETER RADIUS")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("\(Int(quest.radiusMeters)) METERS")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.08))
                    .cornerRadius(10)
                    
                    // Completed Captured Intel Showcase
                    if quest.isCompleted {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("[ ENCRYPTED INTEL SNAPSHOT ]")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            if let data = quest.filteredImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 240)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.8), lineWidth: 1.5)
                                    )
                            }
                            
                            HStack {
                                Text("VERIFIED: \(quest.verifiedLabel?.uppercased() ?? "CONFIRMED")")
                                Spacer()
                                if let date = quest.capturedTimestamp {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(white: 0.08))
                        .cornerRadius(10)
                    } else {
                        // Action Trigger if in range
                        let isInside = locationManager.isPlayerInside(quest: quest)
                        Button {
                            dismiss()
                            onInitiateScan()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isInside ? "viewfinder" : "lock.fill")
                                Text(isInside ? "INITIATE SCANNER HUD" : "OUT OF RANGE (APPROACH WITHIN \(Int(quest.radiusMeters))m)")
                            }
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isInside ? Color.green : Color(white: 0.2))
                            .foregroundColor(isInside ? .black : Color(white: 0.5))
                            .cornerRadius(8)
                        }
                        .disabled(!isInside)
                    }
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.07, blue: 0.10).edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}
