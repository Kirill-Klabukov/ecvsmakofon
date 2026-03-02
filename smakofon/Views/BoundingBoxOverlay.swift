//
//  BoundingBoxOverlay.swift
//  smakofon
//
//  Draws bounding boxes and labels over detected plates.
//  Vision coordinates (bottom-left origin) are converted to SwiftUI (top-left).
//

import SwiftUI

struct BoundingBoxOverlay: View {
    let plates: [DetectedPlate]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ForEach(plates) { plate in
                let rect = Self.convert(plate.boundingBox, in: size)

                // Bounding rectangle
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green, lineWidth: 2.5)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                // Label above the box
                Text(plate.text)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
                    .position(x: rect.midX, y: rect.minY - 14)
            }
        }
    }

    // MARK: - Coordinate conversion

    /// Converts a Vision normalized rect (origin bottom-left) to
    /// SwiftUI points (origin top-left).
    private static func convert(_ box: CGRect, in size: CGSize) -> CGRect {
        let x      = box.origin.x * size.width
        let y      = (1 - box.origin.y - box.height) * size.height
        let width  = box.width  * size.width
        let height = box.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
