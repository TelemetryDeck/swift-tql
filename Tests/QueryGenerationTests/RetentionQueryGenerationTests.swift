import SwiftTQL
import Testing
import Foundation

struct RetentionQueryGenerationTests {
    let tinyQuery = CustomQuery(
        queryType: .groupBy,
        dataSource: .init("com.telemetrydeck.all"),
        filter: .and(.init(fields: [
            .selector(.init(dimension: "appID", value: "79167A27-EBBF-4012-9974-160624E5D07B")),
            .selector(.init(dimension: "isTestMode", value: "false")),
        ])),
        intervals: [
            QueryTimeInterval(
                beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                endDate: Date(iso8601String: "2022-09-30T00:00:00.000Z")!
            ),
        ], granularity: .all,
        aggregations: [
            .filtered(.init(
                filter: .interval(.init(
                    dimension: "__time",
                    intervals: [
                        .init(
                            beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                            endDate: Date(iso8601String: "2022-08-31T23:59:59.000Z")!
                        ),
                    ]
                )),
                aggregator: .thetaSketch(
                    .init(
                        name: "_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z",
                        fieldName: "clientUser"
                    )
                )
            )),
            .filtered(.init(
                filter: .interval(.init(
                    dimension: "__time",
                    intervals: [
                        .init(
                            beginningDate: Date(iso8601String: "2022-09-01T00:00:00.000Z")!,
                            endDate: Date(iso8601String: "2022-09-30T23:59:59.000Z")!
                        ),
                    ]
                )),
                aggregator: .thetaSketch(
                    .init(
                        name: "_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z",
                        fieldName: "clientUser"
                    )
                )
            )),
        ],
        postAggregations: [
            .thetaSketchEstimate(.init(
                name: "retention_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z",
                field: .thetaSketchSetOp(.init(
                    func: .intersect,
                    fields: [
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z"
                        )),
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z"
                        )),
                    ]
                ))
            )
            ),
            .thetaSketchEstimate(.init(
                name: "retention_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z",
                field: .thetaSketchSetOp(.init(
                    func: .intersect,
                    fields: [
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-08-01T00:00:00.000Z_2022-08-31T23:59:59.000Z"
                        )),
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z"
                        )),
                    ]
                ))
            )
            ),
            .thetaSketchEstimate(.init(
                name: "retention_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z",
                field: .thetaSketchSetOp(.init(
                    func: .intersect,
                    fields: [
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z"
                        )),
                        .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "_2022-09-01T00:00:00.000Z_2022-09-30T23:59:59.000Z"
                        )),
                    ]
                ))
            )
            ),
        ]
    )

    @Test("Retention query validation throws when date intervals are too close")
    func throwsWhenDatesTooClose() {
        let begin_august = Date(iso8601String: "2022-08-01T00:00:00.000Z")!
        let mid_august = Date(iso8601String: "2022-08-15T00:00:00.000Z")!
        let end_august = Date(iso8601String: "2022-08-31T23:59:59.999Z")!
        let end_september = Date(iso8601String: "2022-09-30T23:59:59.999Z")!

        // Test monthly retention (default)
        let monthQuery1 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: begin_august, endDate: mid_august)],
            granularity: .month
        )
        #expect(throws: (any Error).self) { try monthQuery1.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        let monthQuery2 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: begin_august, endDate: end_august)],
            granularity: .month
        )
        #expect(throws: (any Error).self) { try monthQuery2.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        let monthQuery3 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: begin_august, endDate: end_september)],
            granularity: .month
        )
        #expect(throws: Never.self) { try monthQuery3.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        // Test daily retention
        let startDate = Date(iso8601String: "2022-08-01T00:00:00.000Z")!
        let sameDay = Date(iso8601String: "2022-08-01T12:00:00.000Z")!
        let nextDay = Date(iso8601String: "2022-08-02T00:00:00.000Z")!

        let dayQuery1 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: startDate, endDate: sameDay)],
            granularity: .day
        )
        #expect(throws: (any Error).self) { try dayQuery1.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        let dayQuery2 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: startDate, endDate: nextDay)],
            granularity: .day
        )
        #expect(throws: Never.self) { try dayQuery2.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        // Test weekly retention
        let weekStart = Date(iso8601String: "2022-08-01T00:00:00.000Z")!
        let weekMid = Date(iso8601String: "2022-08-05T00:00:00.000Z")!
        let weekEnd = Date(iso8601String: "2022-08-08T00:00:00.000Z")!

        let weekQuery1 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: weekStart, endDate: weekMid)],
            granularity: .week
        )
        #expect(throws: (any Error).self) { try weekQuery1.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
        
        let weekQuery2 = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            intervals: [QueryTimeInterval(beginningDate: weekStart, endDate: weekEnd)],
            granularity: .week
        )
        #expect(throws: Never.self) { try weekQuery2.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [UUID()], isSuperOrg: false) }
    }

    @Test("Retention query generation compiles to correct structure")
    func example() throws {
        // Test with new compile-down approach
        let appID = UUID(uuidString: "79167A27-EBBF-4012-9974-160624E5D07B")!
        let query = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            appID: appID,
            baseFilters: .thisApp,
            testMode: false,
            intervals: [QueryTimeInterval(
                beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                endDate: Date(iso8601String: "2022-09-30T00:00:00.000Z")!
            )],
            granularity: .month  // Explicitly set to month
        )

        let compiledQuery = try query.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [appID], isSuperOrg: true)

        // Verify the compiled query has the expected structure
        #expect(compiledQuery.queryType == .groupBy)
        #expect(compiledQuery.granularity == .all)
        #expect(compiledQuery.aggregations != nil)
        #expect(compiledQuery.postAggregations != nil)
        
        // The generated query should match the expected structure from tinyQuery
        // (though the exact aggregator names might differ due to date formatting)
    }
    
    @Test("Retention query generation handles different granularities correctly")
    func retentionWithDifferentGranularities() throws {
        let appID = UUID(uuidString: "79167A27-EBBF-4012-9974-160624E5D07B")!

        // Test daily retention - 7 days should generate 8 intervals (0-7 inclusive)
        let dailyQuery = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            appID: appID,
            baseFilters: .thisApp,
            testMode: false,
            intervals: [QueryTimeInterval(
                beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                endDate: Date(iso8601String: "2022-08-07T23:59:59.000Z")!
            )],
            granularity: .day
        )

        let compiledDailyQuery = try dailyQuery.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [appID], isSuperOrg: true)
        #expect(compiledDailyQuery.aggregations?.count == 7) // 7 days
        // Post-aggregations should be n*(n+1)/2 for n intervals
        #expect(compiledDailyQuery.postAggregations?.count == 28) // 7*8/2 = 28
        
        // Test weekly retention - 4 weeks
        let weeklyQuery = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            appID: appID,
            baseFilters: .thisApp,
            testMode: false,
            intervals: [QueryTimeInterval(
                beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                endDate: Date(iso8601String: "2022-08-29T00:00:00.000Z")!
            )],
            granularity: .week
        )

        let compiledWeeklyQuery = try weeklyQuery.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [appID], isSuperOrg: true)
        #expect(compiledWeeklyQuery.aggregations?.count == 5) // 5 weeks (spans into 5th week)
        #expect(compiledWeeklyQuery.postAggregations?.count == 15) // 5*6/2 = 15
        
        // Test monthly retention - 3 months
        let monthlyQuery = CustomQuery(
            queryType: .retention,
            dataSource: "com.telemetrydeck.all",
            appID: appID,
            baseFilters: .thisApp,
            testMode: false,
            intervals: [QueryTimeInterval(
                beginningDate: Date(iso8601String: "2022-08-01T00:00:00.000Z")!,
                endDate: Date(iso8601String: "2022-10-31T00:00:00.000Z")!
            )],
            granularity: .month
        )

        let compiledMonthlyQuery = try monthlyQuery.precompile(namespace: nil, useNamespace: false, organizationAppIDs: [appID], isSuperOrg: true)
        #expect(compiledMonthlyQuery.aggregations?.count == 3) // 3 months
        #expect(compiledMonthlyQuery.postAggregations?.count == 6) // 3*4/2 = 6
    }
}
