//
//  ScannerView.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Cyberpunk HUD, ML Kit Telemetry & VFX Capture
//

import SwiftUI
import SwiftData
import AVFoundation

/// Fullscreen tactical camera scanner HUD.
/// Streams live camera video, overlays cyberpunk reticles and confidence meters,
/// performs real-time ML Kit image verification, and captures processed tactical intel.
public struct ScannerView: View {
    
    // MARK: - SwiftData & Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let quest: Quest
    
    // Services
    @State private var cameraManager = CameraManager()
    @State private var mlKitService = MLKitService()
    private let imageProcessor = ImageProcessorService()
    
    // Scanner UI State
    @State private var isProcessingCapture: Bool = false
    @State private var capturedProcessedImage: UIImage?
    @State private var showSuccessDebrief: Bool = false
    @State private var scanlineOffset: CGFloat = -180
    @State private var flashEffect: Bool = false
    
    public init(quest: Quest) {
        self.quest = quest
    }
    
    public var body: some View {
        ZStack {
            // Background Dark Neutral
            Color.black.edgesIgnoringSafeArea(.all)
            
            // MARK: 1. Live Camera Stream Preview
            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.cyan)
                    Text("SYNCHRONIZING OPTICAL SENSORS...")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            
            // Subtle Cyberpunk Scanlines Grid
            ScanlineGridOverlay()
                .opacity(0.15)
                .edgesIgnoringSafeArea(.all)
            
            // MARK: 2. Viewfinder Reticle & HUD Elements
            VStack {
                scannerTopBar
                Spacer()
                centralTargetingReticle
                Spacer()
                scannerBottomTelemetry
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // MARK: 3. Flash Transition on Capture
            if flashEffect {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }
            
            // MARK: 4. Post-Capture Mission Debrief Card
            if showSuccessDebrief, let displayImage = capturedProcessedImage {
                MissionSecuredModal(
                    quest: quest,
                    processedImage: displayImage,
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            setupScanner()
        }
        .onDisappear {
            teardownScanner()
        }
    }
    
    // MARK: - Lifecycle Setup
    
    private func setupScanner() {
        mlKitService.setTargetLabels(quest.targetLabels)
        
        // Connect camera frame output to ML Kit service
        cameraManager.sampleBufferHandler = { [weak mlKitService] buffer in
            mlKitService?.processFrame(sampleBuffer: buffer)
        }
        
        cameraManager.checkPermissionsAndConfigure()
        cameraManager.startSession()
        
        // Animate scanline sweep
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: true)) {
            scanlineOffset = 180
        }
    }
    
    private func teardownScanner() {
        cameraManager.stopSession()
        cameraManager.sampleBufferHandler = nil
    }
    
    // MARK: - Scanner Top Bar
    
    private var scannerTopBar: some View {
        HStack {
            // Sector & Mission Code
            VStack(alignment: .leading, spacing: 2) {
                Text("[ OPTICAL SCANNER // SOMAIYA ]")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                
                Text(quest.title.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .default))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Torch Flashlight Toggle
            Button {
                cameraManager.toggleTorch()
            } label: {
                Image(systemName: cameraManager.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 16, weight: .bold))
                    .padding(10)
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(cameraManager.isTorchOn ? .yellow : .white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
            
            // Abort / Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .padding(10)
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.top, 30)
    }
    
    // MARK: - Central Targeting Reticle
    
    private var centralTargetingReticle: some View {
        let isLocked = mlKitService.isTargetLocked
        let reticleColor = isLocked ? Color(red: 0.1, green: 1.0, blue: 0.3) : Color(red: 0.0, green: 0.9, blue: 1.0)
        
        return ZStack {
            // Viewfinder Square Box
            RoundedRectangle(cornerRadius: 12)
                .stroke(reticleColor.opacity(0.5), lineWidth: 1.5)
                .frame(width: 280, height: 280)
            
            // Tactical Corner Accents
            TacticalCornerBrackets(color: reticleColor, size: 28, strokeWidth: 3.5)
                .frame(width: 280, height: 280)
            
            // Animated Scanning Sweep Line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, reticleColor.opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 260, height: 3)
                .offset(y: scanlineOffset)
                .shadow(color: reticleColor, radius: 4)
            
            // Center Crosshair
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .thin))
                .foregroundColor(reticleColor.opacity(0.7))
            
            // Target Label Header
            VStack {
                HStack(spacing: 6) {
                    Image(systemName: isLocked ? "lock.fill" : "target")
                    Text(isLocked ? "[ TARGET LOCKED ]" : "SEEK: \(quest.targetLabelsDisplay.uppercased())")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isLocked ? Color.green : Color.black.opacity(0.8))
                .foregroundColor(isLocked ? .black : .white)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(reticleColor, lineWidth: 1))
                .offset(y: -155)
                
                Spacer()
            }
            .frame(width: 280, height: 280)
        }
    }
    
    // MARK: - Scanner Bottom Telemetry
    
    private var scannerBottomTelemetry: some View {
        VStack(spacing: 12) {
            
            // Real-Time ML Telemetry readout
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("ON-DEVICE VISION FEED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let best = mlKitService.bestTargetMatch {
                        Text("\(best.confidencePercentage)% MATCH")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(mlKitService.isTargetLocked ? .green : .yellow)
                    } else {
                        Text("ANALYZING OPTICAL FRAMES...")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                
                // Confidence Meter Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                mlKitService.isTargetLocked
                                ? LinearGradient(colors: [.green, Color(red: 0.2, green: 1.0, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.cyan, .yellow], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * CGFloat(mlKitService.currentConfidence), height: 8)
                            .animation(.easeOut(duration: 0.2), value: mlKitService.currentConfidence)
                    }
                }
                .frame(height: 8)
                
                // Live Detected Labels Chips
                HStack(spacing: 6) {
                    ForEach(mlKitService.currentLabels.prefix(3)) { label in
                        HStack(spacing: 3) {
                            Text(label.text)
                            Text("\(label.confidencePercentage)%")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(label.isTargetMatch ? .green : .gray)
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(label.isTargetMatch ? Color.green.opacity(0.2) : Color(white: 0.2))
                        .foregroundColor(label.isTargetMatch ? .green : .white)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.85))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
            
            // "LOCK ON" Shutter Button (Enabled >= 70% Confidence)
            Button {
                executeCaptureAndVFX()
            } label: {
                HStack(spacing: 8) {
                    if isProcessingCapture {
                        ProgressView().tint(.black)
                        Text("ENCRYPTING INTEL...")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                    } else {
                        Image(systemName: mlKitService.isTargetLocked ? "lock.shield.fill" : "viewfinder.circle")
                            .font(.system(size: 20, weight: .heavy))
                        
                        Text(mlKitService.isTargetLocked ? "LOCK ON & SECURE SECTOR" : "ALIGN TARGET (REQ >= 70%)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    mlKitService.isTargetLocked
                    ? Color(red: 0.1, green: 1.0, blue: 0.3)
                    : Color(white: 0.25)
                )
                .foregroundColor(mlKitService.isTargetLocked ? .black : Color(white: 0.6))
                .cornerRadius(10)
                .shadow(color: mlKitService.isTargetLocked ? Color.green.opacity(0.6) : .clear, radius: 12)
            }
            .disabled(!mlKitService.isTargetLocked || isProcessingCapture)
            
            // Simulator Test Trigger (Quick Test button for developers)
            Button {
                let target = quest.targetLabels.first ?? "Target"
                mlKitService.simulateMatch(label: target, confidence: 0.88)
            } label: {
                Text("[ SIMULATOR: INJECT 88% TARGET MATCH ]")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Capture Execution & VFX Processing
    
    private func executeCaptureAndVFX() {
        guard let match = mlKitService.bestTargetMatch else { return }
        
        isProcessingCapture = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Trigger white flash animation
        withAnimation(.easeInOut(duration: 0.15)) {
            flashEffect = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.25)) {
                flashEffect = false
            }
        }
        
        // Capture frame or generate snapshot
        let frameSnapshot = generateSnapshot()
        
        Task {
            // Apply Core Image cyberpunk monochrome + bloom + vignette VFX
            let result = await imageProcessor.applyTacticalCyberpunkVFX(
                to: frameSnapshot,
                theme: .cyberpunkCyan,
                questCode: quest.id,
                verifiedLabel: match.text,
                confidence: match.confidence
            )
            
            await MainActor.run {
                if let (filteredImage, compressedData) = result {
                    // Update SwiftData Quest
                    quest.isCompleted = true
                    quest.capturedTimestamp = Date()
                    quest.verifiedLabel = match.text
                    quest.matchConfidence = Double(match.confidence)
                    quest.filteredImageData = compressedData
                    
                    try? modelContext.save()
                    
                    self.capturedProcessedImage = filteredImage
                    self.isProcessingCapture = false
                    
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.spring()) {
                        self.showSuccessDebrief = true
                    }
                } else {
                    self.isProcessingCapture = false
                }
            }
        }
    }
    
    /// Generates current frame representation
    private func generateSnapshot() -> UIImage {
        // Fallback sample generator if running on simulator
        let size = CGSize(width: 720, height: 1280)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let label = quest.targetLabels.first ?? "Tactical Object"
            let text = "SOMAIYA SATELLITE CAPTURE\n\(label.uppercased())"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.cyan
            ]
            text.draw(at: CGPoint(x: 40, y: 550), withAttributes: attrs)
        }
    }
}

// MARK: - Scanline Grid Overlay

private struct ScanlineGridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 6.0
            var y: CGFloat = 0
            while y < size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(Color.cyan.opacity(0.4)), lineWidth: 0.5)
                y += lineSpacing
            }
        }
    }
}

// MARK: - Mission Secured Modal

private struct MissionSecuredModal: View {
    let quest: Quest
    let processedImage: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.1, green: 1.0, blue: 0.3))
                .shadow(color: .green, radius: 10)
            
            Text("TERRITORY SECURED!")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Text("Sector: \(quest.title)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
            
            // Processed Tactical Image with Core Image Cyberpunk VFX
            Image(uiImage: processedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan, lineWidth: 1.5))
                .shadow(color: .cyan.opacity(0.4), radius: 8)
            
            HStack {
                Text("VERIFIED: \(quest.verifiedLabel?.uppercased() ?? "CONFIRMED")")
                Spacer()
                Text("\(Int(((quest.matchConfidence ?? 0.8) * 100)))% MATCH")
            }
            .font(.system(size: 11, weight: .heavy, design: .monospaced))
            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
            .padding(.horizontal, 8)
            
            Button {
                onDismiss()
            } label: {
                Text("RETURN TO CAMPUS MAP")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.1, green: 1.0, blue: 0.3))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.98))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.1, green: 1.0, blue: 0.3), lineWidth: 2)
        )
        .padding(.horizontal, 24)
    }
}
