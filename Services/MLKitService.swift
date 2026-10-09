//
//  MLKitService.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Google ML Kit Image Labeling & On-Device Vision
//

import Foundation
import CoreMedia
import UIKit
import Observation

#if canImport(MLKitVision) && canImport(MLKitImageLabeling)
import MLKitVision
import MLKitImageLabeling
#endif

/// Real-time on-device machine learning detection telemetry item
public struct DetectedLabel: Identifiable, Sendable {
    public let id = UUID()
    public let text: String
    public let confidence: Float // 0.0 ... 1.0
    public let isTargetMatch: Bool
    
    public var confidencePercentage: Int {
        Int((confidence * 100.0).rounded())
    }
}

/// Service orchestrating real-time on-device Google ML Kit Vision inference.
/// Runs inferences asynchronously on background threads to ensure 60 FPS UI stability.
@Observable
public final class MLKitService {
    
    // MARK: - Observable Telemetry State
    
    /// List of top labels currently detected in the camera viewport
    public var currentLabels: [DetectedLabel] = []
    
    /// Strongest target match found for the active quest
    public var bestTargetMatch: DetectedLabel?
    
    /// Target lock achieved indicator (when confidence >= 70%)
    public var isTargetLocked: Bool = false
    
    /// Highest match confidence (0.0 ... 1.0)
    public var currentConfidence: Float = 0.0
    
    /// Diagnostic telemetry: frames per second of the inference engine
    public var estimatedFps: Double = 0.0
    
    /// Toggle to simulate detection in Xcode simulator environment
    public var isSimulationMode: Bool = false
    
    // MARK: - Internal Engine Properties
    
    private var targetLabels: [String] = []
    private var isBusy: Bool = false
    private var lastInferenceTime: Date = Date.distantPast
    private let inferenceInterval: TimeInterval = 0.22 // ~4.5 inferences/second: smooth yet thermally cool
    
    #if canImport(MLKitVision) && canImport(MLKitImageLabeling)
    private var labeler: ImageLabeler?
    #endif
    
    // MARK: - Initialization
    
    public init() {
        setupMLKit()
    }
    
    private func setupMLKit() {
        #if canImport(MLKitVision) && canImport(MLKitImageLabeling)
        let options = ImageLabelerOptions()
        options.confidenceThreshold = 0.40 // Capture candidate labels down to 40%
        self.labeler = ImageLabeler.imageLabeler(options: options)
        #endif
    }
    
    // MARK: - Target Configuration
    
    public func setTargetLabels(_ labels: [String]) {
        self.targetLabels = labels.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        self.resetTelemetry()
    }
    
    public func resetTelemetry() {
        self.currentLabels = []
        self.bestTargetMatch = nil
        self.isTargetLocked = false
        self.currentConfidence = 0.0
    }
    
    // MARK: - Frame Processing Pipeline (Background Queue)
    
    public func processFrame(sampleBuffer: CMSampleBuffer) {
        // Enforce throttling to preserve battery and UI responsiveness
        let now = Date()
        guard now.timeIntervalSince(lastInferenceTime) >= inferenceInterval else { return }
        guard !isBusy else { return }
        
        isBusy = true
        lastInferenceTime = now
        
        #if canImport(MLKitVision) && canImport(MLKitImageLabeling)
        guard let labeler = self.labeler else {
            self.isBusy = false
            return
        }
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = .right // Back camera portrait default
        
        labeler.process(visionImage) { [weak self] rawLabels, error in
            guard let self = self else { return }
            defer { self.isBusy = false }
            
            if let error = error {
                print("ML Kit Vision Inference Error: \(error.localizedDescription)")
                return
            }
            
            guard let rawLabels = rawLabels else { return }
            
            let detected = rawLabels.map { label in
                let cleanText = label.text
                let isMatch = self.evaluateMatch(detectedText: cleanText)
                return DetectedLabel(
                    text: cleanText,
                    confidence: label.confidence.floatValue,
                    isTargetMatch: isMatch
                )
            }
            
            self.updateTelemetry(with: detected)
        }
        #else
        // Fallback for Simulator or environments before CocoaPods Podfile install
        fallbackProcessSimulated()
        self.isBusy = false
        #endif
    }
    
    // MARK: - Match Evaluation
    
    private func evaluateMatch(detectedText: String) -> Bool {
        let lower = detectedText.lowercased()
        for target in targetLabels {
            if lower.contains(target) || target.contains(lower) {
                return true
            }
        }
        return false
    }
    
    @MainActor
    private func updateTelemetry(with detected: [DetectedLabel]) {
        self.currentLabels = detected
        
        // Find highest confidence target match
        let matches = detected.filter { $0.isTargetMatch }.sorted { $0.confidence > $1.confidence }
        if let topMatch = matches.first {
            self.bestTargetMatch = topMatch
            self.currentConfidence = topMatch.confidence
            self.isTargetLocked = topMatch.confidence >= 0.70 // 70% confidence threshold requirement
        } else {
            self.bestTargetMatch = nil
            self.currentConfidence = 0.0
            self.isTargetLocked = false
        }
    }
    
    // MARK: - Simulator Debug Mode
    
    /// Allows the developer to cycle through mock detection levels in the Simulator
    public func simulateMatch(label: String, confidence: Float) {
        Task { @MainActor in
            let item = DetectedLabel(text: label, confidence: confidence, isTargetMatch: true)
            self.currentLabels = [
                item,
                DetectedLabel(text: "Room", confidence: 0.88, isTargetMatch: false),
                DetectedLabel(text: "Desk", confidence: 0.65, isTargetMatch: false)
            ]
            self.bestTargetMatch = item
            self.currentConfidence = confidence
            self.isTargetLocked = confidence >= 0.70
        }
    }
    
    private func fallbackProcessSimulated() {
        guard isSimulationMode, let target = targetLabels.first else { return }
        Task { @MainActor in
            // Simulated oscillating confidence between 65% and 88%
            let randomConfidence = Float.random(in: 0.65...0.88)
            self.simulateMatch(label: target.capitalized, confidence: randomConfidence)
        }
    }
}
