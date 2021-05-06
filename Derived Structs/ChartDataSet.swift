//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct ChartDataSet {
    public enum DataError: Error {
        case insufficientData
    }

    public let data: [ChartDataPoint]
    public let lowestValue: Double
    public let highestValue: Double

    public init(data: [InsightData]) throws {
        self.data = try data.map { try ChartDataPoint(insightData: $0) }

        highestValue = self.data.reduce(0) { max($0, $1.yAxisValue) }
        lowestValue = 0
    }
}
