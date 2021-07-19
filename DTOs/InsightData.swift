//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTO {
    /// Actual row of data inside an InsightCalculationResult
    struct InsightData: Hashable {
        public var xAxisValue: String
        public var yAxisValue: String?
    }
}

#if canImport(Vapor)
import Vapor
extension DTO.InsightData: Content {}
#else
extension DTO.InsightData: Codable {}
#endif
