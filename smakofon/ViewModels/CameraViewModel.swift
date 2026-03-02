//
//  CameraViewModel.swift
//  smakofon
//
//  Coordinates CameraService, OCRService, LocationService, LogService
//  and HapticService. Publishes state consumed by CameraScreen.
//

import AVFoundation
import CoreLocation
import Observation

@Observable
final class CameraViewModel {

    // MARK: - Observed UI state

    var detectedPlates: [DetectedPlate] = []
    var currentPlateText: String = ""
    var isScanning = false
    var permissionGranted = false
    var errorMessage: String?
    var plateCount: Int = 0

    // MARK: - Services (not observed)

    @ObservationIgnored let cameraService    = CameraService()
    @ObservationIgnored private let ocrService      = OCRService()
    @ObservationIgnored private let locationService  = LocationService()
    @ObservationIgnored private let hapticService    = HapticService()
    @ObservationIgnored private let logService: LogService

    // MARK: - Internal processing state

    @ObservationIgnored private var isProcessingFrame = false
    @ObservationIgnored private var recentPlates: [String: Date] = [:]
    @ObservationIgnored private let debounceInterval: TimeInterval = 5.0
    @ObservationIgnored private var emptyFrameCount = 0
    @ObservationIgnored private let clearThreshold  = 20

    // MARK: - Computed

    var captureSession: AVCaptureSession {
        cameraService.captureSession
    }

    // MARK: - Init

    init(logService: LogService = LogService()) {
        self.logService = logService
    }

    // MARK: - Lifecycle

    func requestPermission() async {
        let granted = await cameraService.checkPermission()
        permissionGranted = granted
        if granted {
            setupCamera()
        }
    }

    func stopScanning() {
        cameraService.stop()
        locationService.stopUpdating()
        isScanning = false
    }

    // MARK: - Camera setup

    private func setupCamera() {
        do {
            try cameraService.configure()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // Wire frame callback (fires on CameraService.outputQueue)
        let ocrService = self.ocrService
        cameraService.onFrameReceived = { [weak self] sampleBuffer in
            guard let self, !self.isProcessingFrame else { return }
            self.isProcessingFrame = true

            // Run OCR on the same serial output queue – blocks it,
            // causing AVFoundation to drop late frames automatically.
            let plates = ocrService.recognizePlates(in: sampleBuffer)
            self.isProcessingFrame = false

            // Hop to main actor for UI updates
            DispatchQueue.main.async {
                self.handleDetectedPlates(plates)
            }
        }

        locationService.requestPermission()
        locationService.startUpdating()
        cameraService.start()
        isScanning = true
    }

    // MARK: - Result handling (main queue)

    private func handleDetectedPlates(_ plates: [DetectedPlate]) {
        detectedPlates = plates

        if let best = plates.max(by: { $0.confidence < $1.confidence }) {
            currentPlateText = best.text
            emptyFrameCount = 0
        } else {
            emptyFrameCount += 1
            if emptyFrameCount >= clearThreshold {
                currentPlateText = ""
            }
        }

        for plate in plates {
            logNewPlateIfNeeded(plate)
        }
    }

    private func logNewPlateIfNeeded(_ plate: DetectedPlate) {
        let now = Date()

        // Debounce identical plates
        if let lastSeen = recentPlates[plate.text],
           now.timeIntervalSince(lastSeen) < debounceInterval {
            return
        }

        recentPlates[plate.text] = now

        let location = locationService.currentLocation
        logService.savePlate(
            number: plate.text,
            confidence: Double(plate.confidence),
            latitude:  location?.coordinate.latitude  ?? 0,
            longitude: location?.coordinate.longitude ?? 0
        )

        plateCount += 1
        hapticService.plateDetected()

        // Purge stale debounce entries
        recentPlates = recentPlates.filter {
            now.timeIntervalSince($0.value) < debounceInterval * 3
        }
    }
}
