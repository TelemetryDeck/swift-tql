import SwiftTQL
import Testing
import Foundation

struct ConvenienceAggregatorTests {
    @Test("User count query gets precompiled")
    func userCountQueryGetsPrecompiled() throws {
        let query = CustomQuery(queryType: .timeseries, aggregations: [.userCount(.init())])
        let precompiled = try query.precompile(useNamespace: true, organizationAppIDs: [UUID()], isSuperOrg: false)
        let expectedAggregations: [Aggregator] = [.thetaSketch(.init(name: "Users", fieldName: "clientUser"))]
        #expect(precompiled.aggregations == expectedAggregations)
    }

    @Test("Event count query gets precompiled")
    func eventCountQueryGetsPrecompiled() throws {
        let query = CustomQuery(queryType: .timeseries, aggregations: [.eventCount(.init())])
        let precompiled = try query.precompile(useNamespace: true, organizationAppIDs: [UUID()], isSuperOrg: false)
        let expectedAggregations: [Aggregator] = [.longSum(.init(type: .longSum, name: "Events", fieldName: "count"))]
        #expect(precompiled.aggregations == expectedAggregations)
    }

    @Test("Histogram query gets precompiled")
    func histogramQueryGetsPrecompiled() throws {
        let query = CustomQuery(queryType: .timeseries, aggregations: [.histogram(.init())])
        let precompiled = try query.precompile(useNamespace: true, organizationAppIDs: [UUID()], isSuperOrg: false)
        let expectedAggregations: [Aggregator] = [
            .quantilesDoublesSketch(.init(name: "_histogramSketch", fieldName: "floatValue", k: 1024, maxStreamLength: nil, shouldFinalize: nil)),
            .longMin(.init(type: .longMin, name: "_quantilesMinValue", fieldName: "floatValue")),
            .longMax(.init(type: .longMax, name: "_quantilesMaxValue", fieldName: "floatValue")),
        ]
        let expectedPostAggregations: [PostAggregator] = [.quantilesDoublesSketchToHistogram(
            .init(
                name: "Histogram",
                field: .fieldAccess(.init(type: .fieldAccess, name: nil, fieldName: "_histogramSketch")),
                splitPoints: nil,
                numBins: nil
            )
        )]
        #expect(precompiled.aggregations == expectedAggregations)
        #expect(precompiled.postAggregations == expectedPostAggregations)
    }
}
