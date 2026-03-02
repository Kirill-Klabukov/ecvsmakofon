//
//  OCRService.swift
//  smakofon
//
//  Uses Apple Vision to detect and recognise text in video frames,
//  then filters results through PlateValidator.
//

import Vision
import AVFoundation
import CoreImage

final class OCRService: @unchecked Sendable {

    /// Minimum confidence score to accept an OCR candidate.
    private let minimumConfidence: Float = 0.5

    // MARK: - Public

    /// Synchronously recognises license plates in **sampleBuffer**.
    /// - Important: Call from a background queue only.
    func recognizePlates(in sampleBuffer: CMSampleBuffer) -> [DetectedPlate] {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return []
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast          // favour throughput for real-time
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = false     // plates are not words
        request.minimumTextHeight = 0.04           // ignore tiny text

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }
        return processObservations(observations)
    }

    // MARK: - Private

    private func processObservations(
        _ observations: [VNRecognizedTextObservation]
    ) -> [DetectedPlate] {
        var plates: [DetectedPlate] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= minimumConfidence else { continue }

            let cleaned = candidate.string
                .uppercased()
                .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

            guard PlateValidator.isValid(cleaned) else { continue }

            plates.append(DetectedPlate(
                text: cleaned,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            ))
        }
        return plates
    }
}
