//
//  DruidFilterTests.swift
//
//
//  Created by Daniel Jilg on 22.12.21.
//

import DataTransferObjects
import XCTest

class DruidFilterTests: XCTestCase {
    func testEncoding() throws {
        let exampleFilter = DruidFilter.not(DruidFilterNot(field: DruidFilter.selector(DruidFilterSelector(dimension: "test", value: "abc"))))
        _ = try JSONEncoder.druidEncoder.encode(exampleFilter)
    }
}
