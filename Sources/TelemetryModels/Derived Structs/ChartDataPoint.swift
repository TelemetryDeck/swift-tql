//
//  File.swift
//  
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct ChartDataPoint: Hashable, Identifiable {
    public var id: String { xAxisValue }

    public let xAxisValue: String
    public let yAxisValue: Double

    public init(insightData: InsightData) throws {
        xAxisValue = insightData.xAxisValue

        if let yAxisValue = insightData.yAxisDouble {
            self.yAxisValue = yAxisValue
        } else {
            throw ChartDataSet.DataError.insufficientData
        }
    }
}
