import SwiftTQL
import Testing
import Foundation

struct CompileDownTests {
    let relativeIntervals = [
        RelativeTimeInterval(beginningDate: .init(.beginning, of: .month, adding: 0), endDate: .init(.end, of: .month, adding: 0)),
    ]

    @Test("Funnel query precompilation") func funnel() throws {
        let steps: [NamedFilter] = [
            .init(filter: .selector(.init(dimension: "type", value: "appLaunchedRegularly")), name: "Regular Launch"),
            .init(filter: .selector(.init(dimension: "type", value: "dataEntered")), name: "Data Entered"),
            .init(filter: .selector(.init(dimension: "type", value: "paywallSeen")), name: "Paywall Presented"),
            .init(filter: .selector(.init(dimension: "type", value: "conversion")), name: "Conversion"),
        ]

        let query = CustomQuery(queryType: .funnel, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .all, steps: steps)

        let precompiledQuery = try query.precompile()

        // Exact query generation is in FunnelQueryGenerationTests,
        // here we're just making sure we're jumping into the correct paths.
        #expect(precompiledQuery.queryType == .groupBy)
    }

    @Test("Throws if no data source set") func throwsIfNoDataSource() throws {
        let query = CustomQuery(queryType: .timeseries, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try query.precompile() }
    }

    @Test("Base filters for this organization") func baseFiltersThisOrganization() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", baseFilters: .thisOrganization, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()

        // The caller is responsible for injecting any app/organization filters, so
        // the base filter no longer adds anything on top of the query's own filter.
        #expect(precompiledQuery.filter == nil)
    }

    @Test("Base filters for this app") func baseFiltersThisApp() throws {
        // this should fail because the query does not have an appID
        let queryFailing = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", baseFilters: .thisApp, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try queryFailing.precompile() }

        // This should succeed because an app ID is provided
        let appID = UUID()
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", appID: appID, baseFilters: .thisApp, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()

        #expect(
            precompiledQuery.filter ==
            .selector(.init(dimension: "appID", value: appID.uuidString))
        )
    }

    @Test("Base filters for example data") func baseFiltersExampleData() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", baseFilters: .exampleData, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()

        #expect(precompiledQuery.dataSource == DataSource("space.ooo"))
        #expect(precompiledQuery.filter == nil)
    }

    @Test("Base filters with no filter") func baseFiltersNoFilter() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", baseFilters: .noFilter, relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()

        #expect(precompiledQuery.filter == nil)
    }

    @Test("Data source is preserved") func dataSourceIsPreserved() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "some-data-source", baseFilters: .thisOrganization, relativeIntervals: relativeIntervals, granularity: .all)
        #expect(try query.precompile().dataSource == DataSource("some-data-source"))
    }

    @Test("Compilation fails if no precompilation") func compilationFailsIfNoPrecompilation() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try query.compileToRunnableQuery() }
    }

    @Test("Intervals are created") func intervalsAreCreated() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        #expect(compiledQuery.intervals != nil)
        #expect(!compiledQuery.intervals!.isEmpty)
    }

    @Test("Filters support relative intervals") func filtersSupportRelativeIntervals() throws {
        let query = CustomQuery(
            queryType: .timeseries,
            dataSource: "telemetry-signals",
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

        let precompiledQuery = try query.precompile()
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        // The base filter no longer wraps the query filter, so the query's own
        // filter is passed through with its relative intervals compiled.
        guard case .or(let orFilterExpression) = compiledQuery.filter else {
            Issue.record("Filter is of wrong type")
            return
        }

        guard let intervalFilter = orFilterExpression.fields.first else {
            Issue.record("Filter has wrong number of fields")
            return
        }

        switch intervalFilter {
        case .interval(let filterInterval):
            #expect(filterInterval.intervals != nil)
            #expect(!filterInterval.intervals!.isEmpty)
        default:
            Issue.record("Filter is of wrong type")
        }
    }

    @Test("Aggregations support relative intervals") func aggregationsSupportRelativeIntervals() throws {
        let query = CustomQuery(
            queryType: .timeseries,
            dataSource: "telemetry-signals",
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
        let precompiledQuery = try query.precompile()
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
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .all)
        let precompiledQuery = try query.precompile()
        let compiledQuery = try precompiledQuery.compileToRunnableQuery()

        #expect(precompiledQuery.compilationStatus == .precompiled)
        #expect(compiledQuery.compilationStatus == .compiled)
    }

    @Test("Throws if compilation status not set correctly") func throwsIfCompilationStatusNotSetCorrectly() throws {
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .all)
        #expect(throws: (any Error).self) { try query.compileToRunnableQuery() }
    }

    @Test("Precompile converts simple granularity to period when context has timezone") func granularityPrecompileWithTimezone() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]

        var context = QueryContext()
        context.timezone = "America/Los_Angeles"

        var query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", intervals: intervals, granularity: .day)
        query.context = context

        let precompiledQuery = try query.precompile()

        guard case let .period(periodGranularity) = precompiledQuery.granularity else {
            Issue.record("Expected period granularity, got \(String(describing: precompiledQuery.granularity))")
            return
        }

        #expect(periodGranularity.period == "P1D")
        #expect(periodGranularity.timeZone == "America/Los_Angeles")
    }

    @Test("Precompile leaves granularity unchanged when no timezone in context") func granularityPrecompileWithoutTimezone() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]

        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", intervals: intervals, granularity: .day)
        let precompiledQuery = try query.precompile()

        #expect(precompiledQuery.granularity == .day)
    }

    @Test("Precompile leaves duration granularity unchanged even with timezone") func granularityPrecompileDurationWithTimezone() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]

        let durationGranularity = QueryGranularity.duration(DurationGranularity(duration: 3600000))
        var context = QueryContext()
        context.timezone = "Europe/Berlin"

        var query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", intervals: intervals, granularity: durationGranularity)
        query.context = context

        let precompiledQuery = try query.precompile()

        #expect(precompiledQuery.granularity == durationGranularity)
    }

    @Test("Allows hourly granularity for timeseries") func allowsHourlyGranularityForTimeseries() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", intervals: intervals, granularity: .hour)
        #expect(throws: Never.self) { try query.precompile() }
    }

    @Test("Allows daily granularity for topN") func allowsDailyGranularityForTopN() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .topN, dataSource: "telemetry-signals", intervals: intervals, granularity: .day)
        #expect(throws: Never.self) { try query.precompile() }
    }

    @Test("Allows daily granularity for groupBy") func allowsDailyGranularityForGroupBy() throws {
        let intervals: [QueryTimeInterval] = [
            .init(beginningDate: Date(iso8601String: "2023-04-01T00:00:00.000Z")!, endDate: Date(iso8601String: "2023-05-31T00:00:00.000Z")!),
        ]
        let query = CustomQuery(queryType: .groupBy, dataSource: "telemetry-signals", intervals: intervals, granularity: .day)
        #expect(throws: Never.self) { try query.precompile() }
    }

    @Test("Timezone is preserved through precompile and compile") func timezonePreservedThroughCompile() throws {
        var context = QueryContext()
        context.timezone = "America/New_York"

        var query = CustomQuery(queryType: .timeseries, dataSource: "telemetry-signals", relativeIntervals: relativeIntervals, granularity: .day)
        query.context = context

        let precompiledQuery = try query.precompile()
        #expect(precompiledQuery.context?.timezone == "America/New_York")

        let compiledQuery = try precompiledQuery.compileToRunnableQuery()
        #expect(compiledQuery.context?.timezone == "America/New_York")
        #expect(compiledQuery.intervals != nil)
        #expect(!compiledQuery.intervals!.isEmpty)
    }
}
