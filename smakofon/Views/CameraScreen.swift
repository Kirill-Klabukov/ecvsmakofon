//
//  CameraScreen.swift
//  smakofon
//
//  Full-screen camera viewfinder with live plate detection overlay,
//  scanning status indicator, and detected plate banner.
//

import SwiftUI

struct CameraScreen: View {

    @State private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            if viewModel.permissionGranted {
                cameraContent
            } else if let msg = viewModel.errorMessage {
                errorView(msg)
            } else {
                permissionPlaceholder
            }
        }
        .task { await viewModel.requestPermission() }
        .onDisappear { viewModel.stopScanning() }
    }

    // MARK: - Camera content

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            BoundingBoxOverlay(plates: viewModel.detectedPlates)
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if !viewModel.currentPlateText.isEmpty {
                    plateBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentPlateText)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            statusPill
            Spacer()
            counterPill
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isScanning ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(viewModel.isScanning ? "Scanning" : "Stopped")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var counterPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "car.fill")
                .font(.caption2)
            Text("\(viewModel.plateCount)")
                .font(.caption2.weight(.bold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Plate banner

    private var plateBanner: some View {
        VStack(spacing: 6) {
            Text("DETECTED PLATE")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))

            Text(viewModel.currentPlateText)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.85))
                )
        }
        .padding(.bottom, 48)
    }

    // MARK: - Placeholder views

    private var permissionPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.title3.weight(.semibold))
            Text("Smakofon needs camera access to recognise license plates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(40)
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView(
            "Camera Error",
            systemImage: "exclamationmark.camera.fill",
            description: Text(message)
        )
    }
}
