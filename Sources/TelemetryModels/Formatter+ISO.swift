//
//  File.swift
//
//
//  Created by Daniel Jilg on 19.10.20.
//

import Foundation

@available(macOS 10.14, iOS 14.0, *)
public extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601noFS = ISO8601DateFormatter()
}
