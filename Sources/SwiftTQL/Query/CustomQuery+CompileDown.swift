import Foundation
import Tracing

public extension CustomQuery {
    enum QueryGenerationError: Error {
        case notAllowed(reason: String)
        case notImplemented(reason: String)
        case keyMissing(reason: String)
        case compilationStatusError
    }

    /// Compiles almost all TelemetryDeck-properties down into a regular query that can be enqueued in the Query Task Runner.
    ///
    /// Will not compile the relativeTimeIntervals property into intervals. These need to be calculated directly before running the query.
    ///
    /// @warn Both precompile AND compileToRunnableQuery need to be run before a query can safely be handed to Druid!
    ///
    /// @see compileToRunnableQuery
    func precompile() throws -> CustomQuery {
        try withSpan("TQL.Query.precompile") { span in
            // Make an editable copy of self
            var query = self

            span.attributes["tql.query.type"] = queryType.rawValue
            if let namespace = query.dataSource?.name {
                span.attributes["tql.namespace"] = namespace
            } else {
                throw QueryGenerationError.keyMissing(reason: "Missing key 'dataSource'")
            }

            guard (compilationStatus ?? .notCompiled) == .notCompiled else {
                throw QueryGenerationError.compilationStatusError
            }

            // Make sure either intervals or relative intervals are set
            if query.intervals == nil && query.relativeIntervals == nil {
                query.relativeIntervals = [.init(beginningDate: .init(.beginning, of: .day, adding: -30), endDate: .init(.end, of: .day, adding: 0))]
            }

            // Check if query granularity needs a time zone
            query.granularity = query.granularity?.precompile(withTimezone: query.context?.timezone)

            // Custom Query Types
            if query.queryType == .funnel {
                query = try precompiledFunnelQuery()
            } else if query.queryType == .experiment {
                query = try precompiledExperimentQuery()
            } else if query.queryType == .retention {
                query = try precompiledRetentionQuery()
            }

            // Handle precompilable aggregators and post aggregators
            var aggregations = [Aggregator]()
            var postAggregations = [PostAggregator]()
            for aggregator in query.aggregations ?? [] {
                guard let compiled = aggregator.precompile() else {
                    aggregations.append(aggregator)
                    continue
                }
                aggregations.append(contentsOf: compiled.aggregators)
                postAggregations.append(contentsOf: compiled.postAggregators)
            }
            for postAggregator in query.postAggregations ?? [] {
                guard let compiled = postAggregator.precompile() else {
                    postAggregations.append(postAggregator)
                    continue
                }
                aggregations.append(contentsOf: compiled.aggregators)
                postAggregations.append(contentsOf: compiled.postAggregators)
            }
            query.aggregations = aggregations
            query.postAggregations = postAggregations

            // Apply base filters and data source
            query = try Self.applyBaseFilters(query: query)

            // Update compilationStatus so the next steps in the pipeline are sure the query has been precompiled
            query.compilationStatus = .precompiled

            return query
        }
    }

    /// Compiles all TelemetryDeck additions down into a regular query that can be run on Apache Druid.
    ///
    /// Since this includes the `relativeTimeIntervals` property, this should only be called directly before actually running the query.
    ///
    /// @warn Both precompile AND compileToRunnableQuery need to be run before a query can safely be handed to Druid!
    ///
    /// @see precompile
    func compileToRunnableQuery() throws -> CustomQuery {
        try withSpan("TQL.Query.compileToRunnableQuery") { span in
            span.attributes["tql.query.type"] = queryType.rawValue

            guard compilationStatus == .precompiled else {
                throw QueryGenerationError.compilationStatusError
            }

            // Make an editable copy of self
            var query = self

            // Compile relative Time intervals
            let timeZone = query.context?.timezone
            if let relativeIntervals = query.relativeIntervals {
                query.intervals = relativeIntervals.map { QueryTimeInterval.from(relativeTimeInterval: $0, timeZone: timeZone) }
            }

            guard query.intervals != nil, !query.intervals!.isEmpty else {
                throw QueryGenerationError.keyMissing(reason: "Either 'relativeIntervals' or 'intervals' need to be set")
            }
            span.attributes["tql.intervals.count"] = query.intervals!.count

            // Compile relative intervals in Relative Interval filters
            if let filter = query.filter {
                query.filter = compileRelativeFilterInterval(filter: filter, timeZone: timeZone)
            }

            // Comppile relative intervals in Aggregators
            if let aggregations = query.aggregations {
                query.aggregations = aggregations.map { agg in compileRelativeIntervalFilterInAggregations(agg: agg, timeZone: timeZone) }
            }

            // Update compilationStatus so the next steps in the pipeline are sure the query has been compiled
            query.compilationStatus = .compiled

            return query
        }
    }

    private func compileRelativeFilterInterval(filter: Filter, timeZone: String?) -> Filter {
        switch filter {
        case .selector:
            return filter
        case .columnComparison:
            return filter
        case .interval(let filterInterval):
            if let relativeIntervals = filterInterval.relativeIntervals {
                return Filter.interval(
                    .init(
                        dimension: filterInterval.dimension,
                        intervals: relativeIntervals.map { QueryTimeInterval.from(relativeTimeInterval: $0, timeZone: timeZone) }
                    )
                )
            } else {
                return filter
            }
        case .regex:
            return filter
        case .range:
            return filter
        case .equals:
            return filter
        case .null:
            return filter
        case .in:
            return filter
        case .and(let filterExpression):
            return Filter.and(.init(fields: filterExpression.fields.map { compileRelativeFilterInterval(filter: $0, timeZone: timeZone) }))
        case .or(let filterExpression):
            return Filter.or(.init(fields: filterExpression.fields.map { compileRelativeFilterInterval(filter: $0, timeZone: timeZone) }))
        case .not(let filterNot):
            return Filter.not(.init(field: compileRelativeFilterInterval(filter: filterNot.field, timeZone: timeZone)))
        }
    }

    private func compileRelativeIntervalFilterInAggregations(agg: Aggregator, timeZone: String?) -> Aggregator {
        switch agg {
        case .filtered(let filteredAggregator):
            return Aggregator.filtered(
                .init(
                    filter: compileRelativeFilterInterval(filter: filteredAggregator.filter, timeZone: timeZone),
                    aggregator: compileRelativeIntervalFilterInAggregations(agg: filteredAggregator.aggregator, timeZone: timeZone)
                )
            )
        default:
            return agg
        }
    }
}

extension CustomQuery {
    static func applyBaseFilters(query: CustomQuery) throws -> CustomQuery {
        // make an editable copy of the query
        var query = query
            let maxPriority = 2
            let minPriority = -1
            var clampedPriority = query.context?.priority ?? 1
            if clampedPriority > maxPriority {
                clampedPriority = maxPriority
            }
            if clampedPriority < minPriority {
                clampedPriority = minPriority
            }

            query.context = QueryContext(
                timeout: "200000",
                priority: query.context?.priority == nil ? nil : clampedPriority,
                timestampResultField: query.context?.timestampResultField,
                minTopNThreshold: query.context?.minTopNThreshold,
                grandTotal: query.context?.grandTotal,
                skipEmptyBuckets: false,
                cacheValidityDuration: query.context?.cacheValidityDuration,
                timezone: query.context?.timezone
            )

        // Apply filters according to the basefilters property
        let baseFilters = query.baseFilters ?? .thisOrganization
        switch baseFilters {
        case .thisOrganization:
            return query

        case .thisApp:
            guard let appID = query.appID else { throw QueryGenerationError.keyMissing(reason: "Missing key 'appID'") }
            query.filter = query.filter && .selector(.init(dimension: "appID", value: appID.uuidString))
            return query

        case .exampleData:
            query.dataSource = .init("space.ooo")
            return query

        case .noFilter:
            return query
        }
    }
}
