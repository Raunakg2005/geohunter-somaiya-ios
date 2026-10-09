# GeoHunter: Somaiya Edition (iOS 17+)
> **Tactical Real-World Campus Scavenger Hunt Game**  
> *Exclusively geofenced to K. J. Somaiya Vidyavihar campus, Mumbai.*

Built with **pure modern SwiftUI (iOS 17+)**, SwiftData, `@Observable`, Swift Concurrency (`async/await`, actors), on-device **Google ML Kit Vision**, and **Metal-accelerated Core Image VFX**.

---

## Campus Coordinates and Geofencing Anchor

- **Campus Center Anchor**: `19.0728° N, 72.8998° E`
- **Campus Bounding Perimeter**:
  - `Min Lat: 19.0700°`, `Max Lat: 19.0760°`
  - `Min Lon: 72.8960°`, `Max Lon: 72.9030°`
- **Pre-Seeded Quests**:
  1. **Engineering Sector (KJSCE)**: Identify `Laptop` or `Keyboard` (Radius: 40m).
  2. **Central Green / Pathway**: Identify `Bicycle` or `Plant` (Radius: 35m).
  3. **Student Hub / Canteen**: Identify `Coffee cup` or `Bottle` (Radius: 30m).

---

## Architecture and Directory Structure

```
GeoHunterSomaiya/
├── App/
│   └── GeoHunterApp.swift            # App entry point, ModelContainer setup & auto-seed engine
├── Models/
│   ├── SomaiyaCampusConfig.swift     # GPS coordinates, strict bounding box, seed definitions
│   └── Quest.swift                   # SwiftData @Model with external image storage
├── Services/
│   ├── LocationManager.swift         # @Observable CoreLocation manager, geofence & proximity math
│   ├── CameraManager.swift           # Low-latency AVCaptureSession & background frame pipeline
│   ├── MLKitService.swift            # Google ML Kit Image Labeler, confidence scoring & throttling
│   └── ImageProcessorService.swift   # Actor-isolated Metal Core Image pipeline (Bloom, Vignette, Stamp)
├── Views/
│   ├── TacticalMapView.swift         # MapKit iOS 17 Map, camera bounds locking, radar circles
│   ├── ScannerView.swift             # Fullscreen AR camera HUD, reticle, confidence bar & freeze trigger
│   ├── QuestDetailSheet.swift        # Sector briefing and encrypted intel debrief modal
│   └── Components/
│       ├── RadarPulseView.swift      # Animated radar wave and tactical HUD corner brackets
│       └── CameraPreviewView.swift   # High-efficiency AVCaptureVideoPreviewLayer in SwiftUI
├── Podfile                           # CocoaPods configuration for GoogleMLKit/ImageLabeling
└── README.md                         # Documentation & build instructions
```

---

## CocoaPods and Google ML Kit Installation

1. Open Terminal in the project root folder.
2. Ensure CocoaPods is installed:
   ```bash
   pod install
   ```
3. Open the generated **`GeoHunterSomaiya.xcworkspace`** in Xcode 15 or 16 (do **not** open the `.xcodeproj` file directly).

---

## Required Info.plist Privacy Keys

Add the following keys to your app's `Info.plist` (or under Target -> **Info** in Xcode):

```xml
<key>NSCameraUsageDescription</key>
<string>GeoHunter requires optical camera access to scan and classify tactical campus targets.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>GeoHunter requires campus GPS coordinates to track your proximity to Somaiya mission zones.</string>
```

---

## Simulator Testing (No Physical Travel Required)

For convenience while grading or developing on Mac/Simulator:
- **Instant GPS Teleportation**: Tap the **`SIM-GPS`** button on the top-right of `TacticalMapView` to instantly teleport your operative inside KJSCE, the Canteen, or Central Green.
- **Proximity Unlock**: As soon as you teleport inside a quest radius, the circle shifts from Cyan to **Neon Radioactive Green**, and the bottom button unlocks to **`ACTIVATE OPTICAL SCANNER`**.
- **Mock Target Match**: Inside `ScannerView`, tap **`[ SIMULATOR: INJECT 88% TARGET MATCH ]`** to simulate detecting the target with 88% confidence. The HUD reticle locks to green and enables the **`LOCK ON & SECURE SECTOR`** capture trigger!
- **Core Image VFX Stamping**: Once locked, the image is passed through Metal-accelerated Core Image filters (`CIColorMonochrome`, `CIBloom`, `CIVignette`) with a tactical timestamp overlay and saved automatically to SwiftData.
