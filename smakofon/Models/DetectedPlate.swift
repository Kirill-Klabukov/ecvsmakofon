//
//  DetectedPlate.swift
//  smakofon
//

import Foundation
import CoreGraphics

/// Represents a license plate detected in a single video frame.
struct DetectedPlate: Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float
    /// Bounding box in Vision normalized coordinates (origin bottom-left, 0…1).
    let boundingBox: CGRect

    init(text: String, confidence: Float, boundingBox: CGRect) {
        self.id = UUID()
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    static func == (lhs: DetectedPlate, rhs: DetectedPlate) -> Bool {
        lhs.text == rhs.text
    }
}
