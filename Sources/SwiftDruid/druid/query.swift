import SwiftTQL
import Tracing
import Vapor

extension CustomQuery: Content {}

public struct QueryRoutes {
    let druid: Druid

    
    public func execute(query compiledQuery: CustomQuery) async throws -> QueryResult {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Druid.TQL.Query") { _ in
                let compiledQueryData: Data
                do {
                    compiledQueryData = try JSONEncoder.telemetryEncoder.encode(compiledQuery)
                } catch {
                    throw Abort(.internalServerError, reason: "Error encoding query: \(error)")
                }
                
                let queryAsString = String(data: compiledQueryData, encoding: .utf8) ?? "encoding error"
                
                druid.logger.info("Running Druid Query: \(queryAsString) on server \(baseURL)")
                
                // Send to Druid
                let uri = URI(string: "\(baseURL)v2/")
                let response = try await druid.client.post(uri, content: compiledQuery)
                let maxResponseSize = 32 * 1024 * 1024
                if response.body?.readableBytes ?? 0 > maxResponseSize {
                    druid.logger.warning("Query Result too large: \(response.body?.readableBytes ?? 0) bytes. Query was \n\(queryAsString)")
                    throw Abort(
                        .badRequest,
                        reason: "Query Result too large. The result of this query is \(response.body?.readableBytes ?? 0) bytes, which is larger than the maximum of \(maxResponseSize) bytes."
                    )
                }
                
                // Check for errors
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to run query")
                    }
                }
                
                // Decode Query Result
                let queryResult: QueryResult
                switch compiledQuery.queryType {
                case .timeseries:
                    do {
                        let timeSeriesRows = try response.content.decode([TimeSeriesQueryResultRow].self, using: JSONDecoder.telemetryDecoder)
                        let timeSeriesResult = TimeSeriesQueryResult(rows: timeSeriesRows, restrictions: compiledQuery.restrictions)
                        queryResult = .timeSeries(timeSeriesResult)
                    } catch {
                        druid.logger.warning("Failed to decode timeseries query result: \(error), query was \(queryAsString), response: \(response.body?.description ?? "no response body")")
                        throw Abort(.badRequest, reason: "Failed to decode timeseries query result: \(error)")
                    }
                    
                case .groupBy:
                    do {
                        let groupByRows = try response.content.decode([GroupByQueryResultRow].self, using: JSONDecoder.telemetryDecoder)
                        let groupByResult = GroupByQueryResult(rows: groupByRows, restrictions: compiledQuery.restrictions)
                        queryResult = .groupBy(groupByResult)
                    } catch {
                        druid.logger.warning("Failed to decode groupBy query result: \(error), query was \(queryAsString), response: \(response.body?.description ?? "no response body")")
                        throw Abort(.badRequest, reason: "Failed to decode groupBy query result: \(error)")
                    }
                    
                case .topN:
                    do {
                        var topNRows = try response.content.decode([TopNQueryResultRow].self, using: JSONDecoder.telemetryDecoder)
                        // This fixes a druid bug where query results sometimes contain a row with a timestamp of 1970-01-01
                        // Possible fix is https://github.com/apache/druid/pull/16915
                        topNRows = topNRows.filter { ($0.timestamp > Date(iso8601String: "2020-01-01T00:00:00.000Z")!) || (!$0.result.isEmpty) }
                        let topNResult = TopNQueryResult(rows: topNRows, restrictions: compiledQuery.restrictions)
                        queryResult = .topN(topNResult)
                    } catch {
                        druid.logger.warning("Failed to decode topN query result: \(error), query was \(queryAsString), response: \(response.body?.description ?? "no response body")")
                        throw Abort(.badRequest, reason: "Failed to decode topN query result: \(error)")
                    }
                    
                case .scan:
                    do {
                        let scanRows = try response.content.decode([ScanQueryResultRow].self, using: JSONDecoder.telemetryDecoder)
                        let scanResult = ScanQueryResult(rows: scanRows)
                        queryResult = .scan(scanResult)
                    } catch {
                        druid.logger.warning("Failed to decode scan query result: \(error), query was \(queryAsString), response: \(response.body?.description ?? "no response body")")
                        throw Abort(.badRequest, reason: "Failed to decode scan query result: \(error)")
                    }
                    
                case .timeBoundary:
                    do {
                        let timeboundaryRows = try response.content.decode([TimeBoundaryResultRow].self, using: JSONDecoder.telemetryDecoder)
                        let timeBoundaryResult = TimeBoundaryResult(rows: timeboundaryRows)
                        queryResult = .timeBoundary(timeBoundaryResult)
                    } catch {
                        druid.logger.warning("Failed to decode timeBoundary query result: \(error), query was \(queryAsString), response: \(response.body?.description ?? "no response body")")
                        throw Abort(.badRequest, reason: "Failed to decode timeBoundary query result: \(error)")
                    }
                    
                default:
                    throw Abort(.internalServerError, reason: "QueryManager.getLiveResult received a queryType it doesn't know how to handle: \(compiledQuery.queryType)")
                }
                
                return queryResult
            }
        }
    }
}
