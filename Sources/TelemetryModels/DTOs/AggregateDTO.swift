//
//  File.swift
//  
//
//  Created by Daniel Jilg on 15.04.21.
//

import Foundation

struct AggregateDTO: Codable {
    let min: TimeInterval
    let avg: TimeInterval
    let max: TimeInterval
}
