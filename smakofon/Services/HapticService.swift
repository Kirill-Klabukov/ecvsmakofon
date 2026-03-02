//
//  HapticService.swift
//  smakofon
//
//  Provides haptic feedback when a new plate is detected.
//

import UIKit

final class HapticService {

    private let generator = UINotificationFeedbackGenerator()

    init() {
        generator.prepare()
    }

    /// Trigger a success haptic and re-prepare the engine.
    func plateDetected() {
        generator.notificationOccurred(.success)
        generator.prepare()
    }
}
