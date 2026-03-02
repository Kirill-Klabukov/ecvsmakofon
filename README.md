<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/SwiftUI-Framework-0071E3?style=for-the-badge&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge" />
</p>

<h1 align="center">🚘 Smakofon</h1>

<p align="center">
  <strong>Real-time vehicle license plate recognition for iOS</strong><br/>
  <em>Powered by AVFoundation + Apple Vision — zero external dependencies</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/architecture-MVVM-blueviolet?style=flat-square" />
  <img src="https://img.shields.io/badge/persistence-CoreData-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/location-CoreLocation-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/haptics-UIKit-red?style=flat-square" />
</p>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📷 **Live Camera** | Full-screen AVFoundation video pipeline with high-res preset |
| 🔍 **Real-time OCR** | Apple Vision `VNRecognizeTextRequest` running on a background queue |
| 🟩 **Bounding Boxes** | Live overlay showing detected plate regions + recognized text |
| 🇪🇺 **EU Plate Validation** | Regex-based filtering for UK, DE, FR, IT, ES, PL, NL, Nordic formats |
| 📋 **Vehicle Journal** | Persistent history of all detected plates with timestamps |
| 📍 **GPS Tagging** | Each log entry records device location via CoreLocation |
| 📤 **CSV Export** | One-tap export of the full journal via share sheet |
| 📳 **Haptic Feedback** | Tactile confirmation when a new plate is captured |
| 🔇 **Smart Debouncing** | Identical plates suppressed for 5 seconds to avoid duplicates |
| 🌙 **Dark Mode** | Fully supports system appearance preferences |

---

## 🏗️ Architecture

The project follows **MVVM** with clear separation of concerns:

```
smakofon/
├── Models/
│   ├── DetectedPlate.swift          # Real-time detection result
│   └── PlateLogEntry.swift          # Persisted journal entry (value type)
├── Services/
│   ├── CameraService.swift          # AVCaptureSession management
│   ├── OCRService.swift             # Vision text recognition pipeline
│   ├── LogService.swift             # CoreData CRUD + CSV export
│   ├── LocationService.swift        # CLLocationManager wrapper
│   ├── HapticService.swift          # UIKit haptic feedback
│   └── CoreDataStack.swift          # Programmatic CoreData model
├── ViewModels/
│   ├── CameraViewModel.swift        # Coordinates all services
│   └── HistoryViewModel.swift       # Drives the journal screen
├── Views/
│   ├── CameraScreen.swift           # Full-screen scanner UI
│   ├── CameraPreviewView.swift      # UIViewRepresentable preview layer
│   ├── BoundingBoxOverlay.swift     # Detected plate rectangles + labels
│   └── HistoryScreen.swift          # Journal list with export & delete
├── Utilities/
│   └── PlateValidator.swift         # EU plate regex validation
├── ContentView.swift                # Root TabView
└── smakofonApp.swift                # App entry point
```

---

## 🚀 Getting Started

### Requirements

- **Xcode 15+**
- **iOS 17+** device (camera required — Simulator won't capture video)
- Apple Developer account (for device deployment)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/Kirill-Klabukov/ecvsmakofon.git

# Open in Xcode
open ecvsmakofon/smakofon.xcodeproj

# Select your physical iOS device → Build & Run (⌘R)
```

> **Note:** On first launch the app will request Camera and Location permissions.

---

## ⚙️ How It Works

```
┌─────────────┐    30 fps     ┌────────────┐   candidates    ┌─────────────────┐
│  AVFoundation├──────────────►│  Vision OCR├────────────────►│  PlateValidator │
│  Camera Feed │  CMSampleBuf  │  (fast mode)│   raw strings   │  (regex filter) │
└─────────────┘               └────────────┘                 └────────┬────────┘
                                                                      │
                                                              valid plates
                                                                      │
                              ┌────────────┐   debounced     ┌───────▼────────┐
                              │  CoreData  │◄────────────────│  CameraVM      │
                              │  Journal   │   + GPS tag     │  (main actor)  │
                              └────────────┘                 └───────┬────────┘
                                                                      │
                                                              UI updates
                                                                      │
                              ┌────────────┐                 ┌───────▼────────┐
                              │  Haptic    │◄────────────────│  SwiftUI Views │
                              │  Feedback  │                 │  (overlay + UI)│
                              └────────────┘                 └────────────────┘
```

1. **Camera frames** are captured via `AVCaptureVideoDataOutput` on a dedicated serial queue
2. **Vision OCR** processes each frame using `.fast` recognition level with language correction disabled
3. **PlateValidator** applies regex patterns to filter candidates — must contain letters + digits and match a known EU format
4. **Debouncing** prevents the same plate from being logged more than once within 5 seconds
5. **CoreData** persists each unique detection with timestamp, GPS coordinates, and confidence score
6. **Haptic feedback** fires on every new plate added to the journal

---

## 📱 Screens

### Scanner
- Full-screen live camera preview
- Green bounding boxes around detected plates
- Plate text banner at the bottom
- Status indicator (scanning / stopped) and plate counter

### Vehicle Journal
- Chronological list of all detected plates
- Plate number, timestamp, GPS coordinates, confidence score
- Swipe to delete individual entries
- Overflow menu: **Export CSV** / **Delete All**

---

## 🔐 Permissions

| Permission | Usage |
|-----------|-------|
| `NSCameraUsageDescription` | Real-time license plate scanning |
| `NSLocationWhenInUseUsageDescription` | GPS tagging of detected plates |

Both are configured in the Xcode build settings (auto-generated Info.plist).

---

## 📄 License

This project is available under the **MIT License**. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/Kirill-Klabukov">Kirill Klabukov</a></sub>
</p>
