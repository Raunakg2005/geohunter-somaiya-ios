//
//  CameraPreviewView.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | AVFoundation Video Layer in SwiftUI
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper around AVCaptureVideoPreviewLayer for high-performance camera rendering
public struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Layout updates handled automatically via layoutSubviews
    }
}

public final class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
