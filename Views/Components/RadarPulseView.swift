//
//  RadarPulseView.swift
//  GeoHunter: Somaiya Edition
//
//  Created for iOS 17+ | Cyberpunk HUD & Radar Animations
//

import SwiftUI

/// Animated radar pulse ring for the player's tactical position on the map
public struct RadarPulseView: View {
    @State private var isPulsing = false
    var heading: Double = 0.0
    
    public init(heading: Double = 0.0) {
        self.heading = heading
    }
    
    public var body: some View {
        ZStack {
            // Outermost radar expansion wave
            Circle()
                .stroke(Color(red: 0.0, green: 0.94, blue: 1.0, opacity: 0.7), lineWidth: 2)
                .scaleEffect(isPulsing ? 2.6 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)
            
            // Secondary intermediate ring
            Circle()
                .fill(Color(red: 0.0, green: 0.94, blue: 1.0, opacity: 0.15))
                .scaleEffect(isPulsing ? 1.8 : 1.0)
                .opacity(isPulsing ? 0.2 : 0.6)
            
            // Solid center operative core
            Circle()
                .fill(Color(red: 0.0, green: 0.94, blue: 1.0))
                .frame(width: 14, height: 14)
                .shadow(color: Color(red: 0.0, green: 0.94, blue: 1.0), radius: 6)
            
            // Heading directional pointer cone
            Image(systemName: "location.north.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .rotationEffect(.degrees(heading))
        }
        .frame(width: 28, height: 28)
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

/// Cyberpunk corner bracket element for tactical HUD views
public struct TacticalCornerBrackets: View {
    let color: Color
    let size: CGFloat
    let strokeWidth: CGFloat
    
    public init(color: Color = Color(red: 0.0, green: 0.94, blue: 1.0), size: CGFloat = 16, strokeWidth: CGFloat = 2) {
        self.color = color
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                // Top-Left
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                
                // Top-Right
                path.move(to: CGPoint(x: w - size, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: size))
                
                // Bottom-Left
                path.move(to: CGPoint(x: 0, y: h - size))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: size, y: h))
                
                // Bottom-Right
                path.move(to: CGPoint(x: w - size, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: h - size))
            }
            .stroke(color, lineWidth: strokeWidth)
        }
    }
}
