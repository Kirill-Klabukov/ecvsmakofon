//
//  PlateLogEntry.swift
//  smakofon
//

import Foundation
import CoreLocation

/// Value-type representation of a persisted plate log used in the UI layer.
struct PlateLogEntry: Identifiable, Sendable {
    let id: UUID
    let plateNumber: String
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let confidence: Double

    var coordinate: CLLocationCoordinate2D? {
        guard latitude != 0 || longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: timestamp)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
}
