//
//  File.swift
//
//
//  Created by Daniel Jilg on 15.04.21.
//

import Foundation

public struct AggregateDTO: Codable {
    public let min: TimeInterval
    public let avg: TimeInterval
    public let max: TimeInterval
}
