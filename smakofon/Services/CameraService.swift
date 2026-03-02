//
//  CameraService.swift
//  smakofon
//
//  Manages AVCaptureSession, delivers CMSampleBuffers via closure.
//

import AVFoundation
import UIKit

final class CameraService: NSObject, @unchecked Sendable {

    // MARK: - Public

    let captureSession = AVCaptureSession()

    /// Called on the output queue for every captured video frame.
    nonisolated(unsafe) var onFrameReceived: ((CMSampleBuffer) -> Void)?

    // MARK: - Queues

    private let sessionQueue  = DispatchQueue(label: "com.smakofon.session")
    private let outputQueue   = DispatchQueue(label: "com.smakofon.videoOutput", qos: .userInitiated)

    // MARK: - Errors

    enum CameraError: Error, LocalizedError {
        case unauthorized
        case configurationFailed
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unauthorized:        return "Camera access was denied."
            case .configurationFailed: return "Failed to configure the camera."
            case .unavailable:         return "No camera is available on this device."
            }
        }
    }

    // MARK: - Permission

    func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Configuration

    func configure() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back
        ) else {
            throw CameraError.unavailable
        }

        // Optimise auto-focus for near objects (plates)
        if device.isFocusModeSupported(.continuousAutoFocus) {
            try? device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            device.unlockForConfiguration()
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: outputQueue)

        guard captureSession.canAddOutput(output) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(output)

        // Portrait orientation
        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    // MARK: - Session lifecycle

    func start() {
        sessionQueue.async { [captureSession] in
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [captureSession] in
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrameReceived?(sampleBuffer)
    }
}
