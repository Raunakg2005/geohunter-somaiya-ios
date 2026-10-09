//
//  CameraManager.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | AVFoundation & Modern Concurrency
//

import Foundation
import AVFoundation
import UIKit
import Observation

/// Low-latency camera capture service.
/// Configures AVCaptureSession and streams CMSampleBuffers off the main thread.
@Observable
public final class CameraManager: NSObject {
    
    // MARK: - Observed State
    public var isSessionRunning: Bool = false
    public var isTorchOn: Bool = false
    public var cameraError: String?
    
    // MARK: - Core AVFoundation Properties
    public let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.geohunter.sessionQueue", qos: .userInitiated)
    private let videoOutputQueue = DispatchQueue(label: "com.geohunter.videoOutputQueue", qos: .userInteractive)
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    /// Delegate handler receiving sample buffers on background thread for ML Kit processing
    public var sampleBufferHandler: ((CMSampleBuffer) -> Void)?
    
    /// Most recent captured high-res still image from confirmed lock-on
    public var lastCapturedImage: UIImage?
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Camera Setup
    
    public func checkPermissionsAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                } else {
                    Task { @MainActor in
                        self?.cameraError = "Optics Access Denied: Camera permission is required for tactical scan."
                    }
                }
            }
        default:
            self.cameraError = "Optics Access Denied: Enable camera permissions in iOS Settings."
        }
    }
    
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720 // Optimal balance between ML inference speed & crisp HUD preview
            
            // Configure default back camera
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                Task { @MainActor in self.cameraError = "No tactical camera unit discovered." }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                } else {
                    Task { @MainActor in self.cameraError = "Failed to link optical input feed." }
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                Task { @MainActor in self.cameraError = "Optical input error: \(error.localizedDescription)" }
                self.session.commitConfiguration()
                return
            }
            
            // Configure Video Data Output for ML stream
            if self.session.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutput.videoSettings = [
                    (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
                self.session.addOutput(self.videoDataOutput)
                
                // Ensure orientation is portrait
                if let connection = self.videoDataOutput.connection(with: .video),
                   connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Lifecycle Controls
    
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
            Task { @MainActor in
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Tactical Utilities
    
    public func toggleTorch() {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                self.isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                self.isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Tactical Torch Failure: \(error.localizedDescription)")
        }
    }
    
    /// Converts a CMSampleBuffer to a UIImage for freeze-frame capture
    public func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Delegate off to MLKitService on the dedicated background queue
        sampleBufferHandler?(sampleBuffer)
    }
}
