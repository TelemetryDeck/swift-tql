import Foundation
import Tracing

extension CustomQuery {
    func precompiledFunnelQuery(accuracy: Int? = nil) throws -> CustomQuery {
        try withSpan("TQL.Query.Funnel.compile") { span in
            var query = self

            guard let steps = steps else { throw QueryGenerationError.keyMissing(reason: "Missing key 'steps'") }
            span.attributes["tql.funnel.steps_count"] = steps.count
            // Only the explicit accuracy is recorded; a nil accuracy lets Druid pick its own default size.
            if let accuracy { span.attributes["tql.funnel.theta_sketch_size"] = accuracy }

            // Funnel queries with more than 5 steps regularly break our infrastruture at the moment, but only when they touch
            // "realtime" data. When they only run on finished segments, they work fine, because historicals have bigger merge
            // buffers. To mitigate this, we're excluding the last two hours of data from funnels with more than 5 steps.
            if steps.count > 4 {
                if let relativeIntervals = relativeIntervals {
                    var newRelativeIntervals: [RelativeTimeInterval] = []
                    for interval in relativeIntervals {
                        let absoluteInterval = QueryTimeInterval.from(relativeTimeInterval: interval, timeZone: context?.timezone)
                        if absoluteInterval.endDate.timeIntervalSinceNow > -24 * 60 * 60 { // 24 hours ago
                            newRelativeIntervals.append(.init(beginningDate: interval.beginningDate, endDate: .init(.end, of: .day, adding: -1)))
                        } else {
                            newRelativeIntervals.append(interval)
                        }
                    }

                    query.relativeIntervals = newRelativeIntervals
                }

                if let intervals = intervals {
                    var newIntervals: [QueryTimeInterval] = []
                    for interval in intervals {
                        var newBeginningDate = interval.beginningDate
                        guard let newEndDate = Date(timeIntervalSinceNow: -24 * 60 * 60).beginning(of: .day) else { continue }

                        if newBeginningDate > newEndDate {
                            newBeginningDate = newEndDate
                        }

                        if interval.endDate.timeIntervalSinceNow > -24 * 60 * 60 { // 24 hours ago
                            newIntervals.append(.init(beginningDate: newBeginningDate, endDate: newEndDate))
                        } else {
                            newIntervals.append(interval)
                        }
                    }
                }
            }

            // Generate Filter Statement
            let stepsFilters = Filter.or(.init(fields: steps.compactMap(\.filter)))
            let queryFilter = filter && stepsFilters

            // Generate Aggregations
            let aggregationNamePrefix = "_funnel_step_"
            var aggregations = [Aggregator]()

            for (index, step) in steps.enumerated() {
                aggregations.append(.filtered(.init(
                    filter: step.filter ?? Filter.empty,
                    aggregator: .thetaSketch(.init(
                        name: "\(aggregationNamePrefix)\(index)",
                        fieldName: "clientUser",
                        size: accuracy
                    ))
                )))
            }

            // Generate Post-Agregations
            var postAggregations = [PostAggregator]()
            for (index, step) in steps.enumerated() {
                if index == 0 {
                    postAggregations.append(.thetaSketchEstimate(.init(
                        name: "\(index)_\(step.name)",
                        field: .fieldAccess(.init(
                            type: .fieldAccess,
                            fieldName: "\(aggregationNamePrefix)\(index)"
                        ))
                    )))
                    continue
                }

                postAggregations.append(.thetaSketchEstimate(.init(
                    name: "\(index)_\(step.name)",
                    field: .thetaSketchSetOp(.init(
                        func: .intersect,
                        fields: (0 ... index).map { stepNumber in
                            .fieldAccess(.init(type: .fieldAccess, fieldName: "\(aggregationNamePrefix)\(stepNumber)"))
                        }
                    ))
                )))
            }

            // Combine query
            query.queryType = .groupBy
            query.filter = queryFilter
            query.aggregations = aggregations
            query.postAggregations = postAggregations

            return query
        }
    }
}

private extension Array {
    subscript(safe index: Index, default defaultValue: Element) -> Element {
        indices.contains(index) ? self[index] : defaultValue
    }
}
