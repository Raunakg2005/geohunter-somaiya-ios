//
//  ImageProcessorService.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Core Image & Tactical VFX Pipeline
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Asynchronous image processing engine generating arcade/cyberpunk
/// tactical visual effects using Metal-backed Core Image filters.
public actor ImageProcessorService {
    
    // MARK: - Reusable Metal CIContext
    private let ciContext: CIContext
    
    public init() {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice)
        } else {
            self.ciContext = CIContext(options: nil)
        }
    }
    
    // MARK: - Tactical Cyberpunk Filter Pipeline
    
    public enum TacticalTheme: Sendable {
        case matrixGreen      // Radioactive lime / military night-vision
        case cyberpunkCyan    // High-tech terminal blue-cyan
        case amberHazard      // Tactical combat telemetry
        
        var ciColor: CIColor {
            switch .matrixGreen:
                return CIColor(red: 0.15, green: 1.0, blue: 0.35)
            case .cyberpunkCyan:
                return CIColor(red: 0.0, green: 0.94, blue: 1.0)
            case .amberHazard:
                return CIColor(red: 1.0, green: 0.65, blue: 0.0)
            }
        }
    }
    
    /// Processes an input image with multi-stage tactical VFX:
    /// 1. Color Monochrome (Tactical tint)
    /// 2. Bloom (Glow highlights)
    /// 3. Vignette (Surveillance reticle edges)
    /// 4. Tactical telemetry stamp overlay
    public func applyTacticalCyberpunkVFX(
        to sourceImage: UIImage,
        theme: TacticalTheme = .cyberpunkCyan,
        questCode: String,
        verifiedLabel: String,
        confidence: Float
    ) -> (processedImage: UIImage, imageData: Data)? {
        guard let cgInput = sourceImage.cgImage else { return nil }
        var currentCI = CIImage(cgImage: cgInput)
        
        // 1. Color Monochrome: Convert into tactical tint
        let monochrome = CIFilter.colorMonochrome()
        monochrome.inputImage = currentCI
        monochrome.color = theme.ciColor
        monochrome.intensity = 0.85
        if let output = monochrome.outputImage {
            currentCI = output
        }
        
        // 2. Bloom: Add subtle neon luminescence to bright areas
        let bloom = CIFilter.bloom()
        bloom.inputImage = currentCI
        bloom.intensity = 0.70
        bloom.radius = 8.0
        if let output = bloom.outputImage {
            currentCI = output
        }
        
        // 3. Vignette: Darken edges like a tactical scope
        let vignette = CIFilter.vignette()
        vignette.inputImage = currentCI
        vignette.intensity = 1.3
        vignette.radius = 1.8
        if let output = vignette.outputImage {
            currentCI = output
        }
        
        // Render from Metal CIContext
        guard let outputCG = ciContext.createCGImage(currentCI, from: currentCI.extent) else {
            return nil
        }
        
        let filteredBaseImage = UIImage(cgImage: outputCG, scale: sourceImage.scale, orientation: sourceImage.imageOrientation)
        
        // 4. Tactical Telemetry Watermark Overlay
        let stampedImage = stampTacticalTelemetry(
            on: filteredBaseImage,
            questCode: questCode,
            verifiedLabel: verifiedLabel,
            confidence: confidence
        )
        
        guard let compressedData = stampedImage.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        
        return (stampedImage, compressedData)
    }
    
    // MARK: - Telemetry Watermarking
    
    private func stampTacticalTelemetry(
        on image: UIImage,
        questCode: String,
        verifiedLabel: String,
        confidence: Float
    ) -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            // Draw base filtered image
            image.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw tactical top-left / bottom-left HUD brackets
            let margin: CGFloat = 24.0
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.9)
            ]
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withTime, .withColonSeparatorInTime]
            let timeString = formatter.string(from: Date())
            
            let headerText = "[ GEOHUNTER // SOMAIYA ARCHIVE ]\nSECTOR: \(questCode)\nTIME: \(timeString) UTC"
            headerText.draw(at: CGPoint(x: margin, y: margin), withAttributes: textAttributes)
            
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .black),
                .foregroundColor: UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 0.95)
            ]
            let matchPct = Int((confidence * 100).rounded())
            let footerText = "[ TARGET VERIFIED: \(verifiedLabel.uppercased()) // \(matchPct)% CONFIDENCE ]"
            
            let footerY = size.height - margin - 35
            footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
        }
    }
}
