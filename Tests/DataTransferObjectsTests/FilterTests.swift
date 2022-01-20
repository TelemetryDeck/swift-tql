//
//  FilterTests.swift
//
//
//  Created by Daniel Jilg on 22.12.21.
//

import DataTransferObjects
import XCTest

class FilterTests: XCTestCase {
    func testEncoding() throws {
        let exampleFilter = Filter.not(FilterNot(field: Filter.selector(FilterSelector(dimension: "test", value: "abc"))))
        _ = try JSONEncoder.telemetryEncoder.encode(exampleFilter)
    }
}
