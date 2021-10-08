//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTOv1 {
    /// Actual row of data inside an InsightCalculationResult
    struct InsightData: Hashable {
        public var xAxisValue: String
        public var yAxisValue: String?
    }
}

#if canImport(Vapor)
import Vapor
extension DTOv1.InsightData: Content {}
#else
extension DTOv1.InsightData: Codable {}
#endif
