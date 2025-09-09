import SwiftTQL
import Testing
import Foundation

struct CompileDownTests {
    let relativeIntervals = [
        RelativeTimeInterval(beginningDate: .init(.beginning, of: .month, adding: 0), endDate: .init(.end, of: .month, adding: 0)),
    ]

    let appID1 = UUID()
    let appID2 = UUID()

    @Test("Funnel query precompilation") func funnel() throws {
        let steps: [NamedFilter] = [
            .init(filter: .selector(.init(dimension: "type", value: "appLaunchedRegularly")), name: "Regular Launch"),
            .init(filter: .selector(.init(dimension: "type", value: "dataEntered")), name: "Data Entered"),
            .init(filter: .selector(.init(dimension: "type", value: "paywallSeen")), name: "Paywall Presented"),
            .init(filter: .selector(.init(dimension: "type", value: "conversion")), name: "Conversion"),
        ]

        let query = CustomQuery(queryType: .funnel, relativeIntervals: relativeIntervals, granularity: .all, steps: steps)

        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)

        // Exact query generation is in FunnelQueryGenerationTests,
        // here we're just making sure we're jumping into the correct paths.
        #expect(precompiledQuery.queryType == .groupBy)
    }

    @Test("Base filters for this organization") func baseFiltersThisOrganization() throws {
        let query = CustomQuery(queryType: .timeseries, baseFilters: .thisOrganization, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)

        #expect(
            precompiledQuery.filter ==
            .and(.init(fields: [
                .or(.init(fields: [
                    .selector(.init(
                        dimension: "appID",
                        value: appID1.uuidString
                    )),
                    .selector(.init(
                        dimension: "appID",
                        value: appID2.uuidString
                    )),
                ]
                )),
                .selector(.init(dimension: "isTestMode", value: "false")),
            ]
            ))
        )
    }

    @Test("Base filters for this app") func baseFiltersThisApp() throws {
        // this should fail because the query does not have an appID
        let queryFailing = CustomQuery(queryType: .timeseries, baseFilters: .thisApp, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try queryFailing.precompile(useNamespace: false, organizationAppIDs: [], isSuperOrg: false) }

        // This should succeed because an app ID is provided
        let appID = UUID()
        let query = CustomQuery(queryType: .timeseries, appID: appID, baseFilters: .thisApp, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID, appID1, appID2], isSuperOrg: false)

        #expect(
            precompiledQuery.filter ==
            .and(.init(fields: [
                .selector(.init(dimension: "appID", value: appID.uuidString)),
                .selector(.init(dimension: "isTestMode", value: "false")),
            ]))
        )
    }

    @Test("Base filters for example data") func baseFiltersExampleData() throws {
        let query = CustomQuery(queryType: .timeseries, baseFilters: .exampleData, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)

        #expect(
            precompiledQuery.filter ==
            .and(.init(fields: [
                .selector(.init(dimension: "appID", value: "B97579B6-FFB8-4AC5-AAA7-DA5796CC5DCE")),
                .selector(.init(dimension: "isTestMode", value: "false")),
            ]))
        )
    }

    @Test("Base filters with no filter") func baseFiltersNoFilter() throws {
        let query = CustomQuery(queryType: .timeseries, baseFilters: .noFilter, relativeIntervals: relativeIntervals, granularity: .all)

        // this should fail because isSuperOrg is not set to true
        #expect(throws: (any Error).self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }

        // this should succeed because isSuperOrg is set to true
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: true)

        #expect(precompiledQuery.filter == nil)
    }

    @Test("Data source handling") func dataSource() throws {
        // No datasource means data source is telemetry-signals
        let query1 = CustomQuery(queryType: .timeseries, baseFilters: .thisOrganization, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(try query1.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false).dataSource == DataSource("telemetry-signals"))

        // Specified datasource but not noFilter + super org will be replaced by telemetry-signals
        let query2 = CustomQuery(queryType: .timeseries, dataSource: "some-data-source", baseFilters: .thisOrganization, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(try query2.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false).dataSource == DataSource("telemetry-signals"))

        // Specified datasource will be retained if super org is set
        let query3 = CustomQuery(queryType: .timeseries, dataSource: "some-data-source", baseFilters: .noFilter, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(try query3.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: true).dataSource == DataSource("some-data-source"))
    }

    @Test("Throws if neither intervals nor relative intervals set") func throwsIfNeitherIntervalsNorRelativeIntervalsSet() throws {
        let query = CustomQuery(queryType: .timeseries, baseFilters: .noFilter, intervals: nil, relativeIntervals: nil, granularity: .all)

        #expect(throws: (any Error).self) { try query.precompile(useNamespace: false, organizationAppIDs: [], isSuperOrg: false) }
    }

    @Test("Compilation fails if no precompilation") func compilationFailsIfNoPrecompilation() throws {
        let query = CustomQuery(queryType: .timeseries, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try query.compileToRunnableQuery() }
    }

    @Test("Intervals are created") func intervalsAreCreated() throws {
        let query = CustomQuery(queryType: .timeseries, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        #expect(compiledQuery.intervals != nil)
        #expect(!compiledQuery.intervals!.isEmpty)
    }

    @Test("Filters support relative intervals") func filtersSupportRelativeIntervals() throws {
        let query = CustomQuery(
            queryType: .timeseries,
            filter: .or(
                .init(
                    fields: [.interval(
                        .init(
                            dimension: "__time",
                            relativeIntervals: [.init(
                                beginningDate: .init(.beginning, of: .month, adding: -6),
                                endDate: .init(.end, of: .month, adding: 0)
                            )]
                        )
                    )]
                )
            ),
            relativeIntervals: relativeIntervals,
            granularity: .all
        )

        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        guard case .and(let testModeFilter) = compiledQuery.filter else {
            Issue.record("Filter is of wrong type")
            return
        }

        guard case .and(let appIDsFilter) = testModeFilter.fields.first else {
            Issue.record("Filter is of wrong type")
            return
        }

        guard let orFilter = appIDsFilter.fields.first else {
            Issue.record("Filter is of wrong type")
            return
        }

        switch orFilter {
        case .or(let orFilterExpression):
            guard let intervalFilter = orFilterExpression.fields.first else {
                Issue.record("Filter is of wrong number")
                return
            }

            switch intervalFilter {
            case .interval(let filterInterval):
                #expect(filterInterval.intervals != nil)
                #expect(!filterInterval.intervals!.isEmpty)
            default:
                Issue.record("Filter is of wrong number")
            }
        default:
            Issue.record("Filter is of wrong type")
        }
    }

    @Test("Aggregations support relative intervals") func aggregationsSupportRelativeIntervals() throws {
        let query = CustomQuery(
            queryType: .timeseries,
            relativeIntervals: relativeIntervals,
            granularity: .all,
            aggregations: [
                .filtered(
                    .init(
                        filter: .interval(
                            .init(
                                dimension: "__time",
                                relativeIntervals: [.init(
                                    beginningDate: .init(.beginning, of: .month, adding: -6),
                                    endDate: .init(.end, of: .month, adding: 0)
                                )]
                            )
                        ),
                        aggregator: .count(.init(name: "appID"))
                    )
                ),
            ]
        )
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        guard let aggregation = compiledQuery.aggregations?.first else {
            Issue.record("CompiledQuery has no aggregations")
            return
        }

        guard case .filtered(let filteredAggregator) = aggregation else {
            Issue.record("CompiledQuery has wrong type of aggregation")
            return
        }

        guard case .interval(let filterInterval) = filteredAggregator.filter else {
            Issue.record("CompiledQuery has wrong type of filter")
            return
        }

        #expect(filterInterval.intervals != nil)
        #expect(!filterInterval.intervals!.isEmpty)
    }

    @Test("Compilation status is set correctly") func compilationStatusIsSetCorrectly() throws {
        let query = CustomQuery(queryType: .timeseries, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        #expect(precompiledQuery.compilationStatus == .precompiled)
        #expect(compiledQuery.compilationStatus == .compiled)
    }

    @Test("Throws if compilation status not set correctly") func throwsIfCompilationStatusNotSetCorrectly() throws {
        let query = CustomQuery(queryType: .timeseries, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try query.compileToRunnableQuery() }
    }

    @Test("Query restrictions") func restrictions() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]

        let restrictions: [QueryTimeInterval] = [
            // This restriction should be dropped in the final query, because it does not apply
            .init(beginningDate: Date(iso8601String: "2023-01-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-01-31T00:00:00.000Z")!),

            // This restriction should be included because it does apply
            .init(beginningDate: Date(iso8601String: "2023-05-14T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),

            // This restriction should be included because it applies partially
            .init(beginningDate: Date(iso8601String: "2023-03-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-04-02T00:00:00.000Z")!),
        ]

        let query = CustomQuery(queryType: .timeseries, restrictions: restrictions, intervals: intervals, granularity: .all)
        let precompiledQuery = try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        #expect(compiledQuery.restrictions == [
            .init(beginningDate: Date(iso8601String: "2023-03-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-04-02T00:00:00.000Z")!),
            .init(beginningDate: Date(iso8601String: "2023-05-14T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ])
    }

    @Test("Namespace handling") func namespace() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]

        var query = CustomQuery(queryType: .timeseries, intervals: intervals, granularity: .day)
        query.dataSource = nil
        let precompiledQuery = try query.precompile(namespace: "com.telemetrydeck.test", useNamespace: true, organizationAppIDs: [appID1, appID2], isSuperOrg: false)
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()
        #expect(compiledQuery.dataSource?.name == "com.telemetrydeck.test")
    }

    @Test("Allows hourly granularity for timeseries") func allowsHourlyGranularityForTimeseries() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .timeseries, intervals: intervals, granularity: .hour)
        #expect(throws: Never.self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }
    }

    @Test("Allows daily granularity for topN") func allowsDailyGranularityForTopN() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .topN, intervals: intervals, granularity: .day)
        #expect(throws: Never.self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }
    }

    @Test("Allows daily granularity for groupBy") func allowsDailyGranularityForGroupBy() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .groupBy, intervals: intervals, granularity: .day)
        #expect(throws: Never.self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }
    }

    @Test("Disallows hourly queries for topN") func disallowsHourlyQueriesForTopN() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .topN, intervals: intervals, granularity: .hour)

        #expect(throws: (any Error).self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }
    }

    @Test("Disallows hourly queries for groupBy") func disallowsHourlyQueriesForGroupBy() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .groupBy, intervals: intervals, granularity: .hour)

        #expect(throws: (any Error).self) { try query.precompile(useNamespace: false, organizationAppIDs: [appID1, appID2], isSuperOrg: false) }
    }
}
