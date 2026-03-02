//
//  PlateValidator.swift
//  smakofon
//
//  Regex-based validation for common EU license plate formats.
//  Filters Vision OCR candidates to reduce false positives.
//

import Foundation

enum PlateValidator {

    // MARK: - Public

    /// Returns `true` when the cleaned text looks like a valid EU plate.
    static func isValid(_ rawText: String) -> Bool {
        let cleaned = rawText
            .uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

        // Length gate – most plates are 4-10 alphanumeric characters
        guard cleaned.count >= 4, cleaned.count <= 10 else { return false }

        // Must contain at least one letter AND at least one digit
        let hasLetter = cleaned.contains(where: \.isLetter)
        let hasDigit  = cleaned.contains(where: \.isNumber)
        guard hasLetter, hasDigit else { return false }

        return matchesKnownFormat(cleaned)
    }

    // MARK: - Private

    private static let patterns: [String] = [
        // UK:      AB12 CDE
        "^[A-Z]{2}\\d{2}[A-Z]{3}$",
        // French / Italian:  AB 123 CD
        "^[A-Z]{2}\\d{3}[A-Z]{2}$",
        // Spanish:  1234 ABC
        "^\\d{4}[A-Z]{3}$",
        // German:   M AB 1234
        "^[A-Z]{1,3}[A-Z]{1,2}\\d{1,4}[EH]?$",
        // Polish:   WX 12345
        "^[A-Z]{2,3}\\d{4,5}$",
        // Dutch:    12-AB-34 / AB-12-CD
        "^\\d{1,2}[A-Z]{2,3}\\d{1,2}$",
        "^[A-Z]{2}\\d{2}[A-Z]{2}$",
        // Nordic / generic:  ABC 123, AB 1234, etc.
        "^[A-Z]{1,4}\\d{1,5}[A-Z]{0,3}$",
        // Reverse generic:  1234 AB
        "^\\d{1,4}[A-Z]{2,4}$",
    ]

    private static func matchesKnownFormat(_ text: String) -> Bool {
        patterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
