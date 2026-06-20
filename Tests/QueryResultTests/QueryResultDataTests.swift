import Foundation
import SwiftTQL
import Testing

struct QueryResultDataTests {
    let randomDate = Date(iso8601String: "2021-10-21T12:00:00.000Z")!

    @Test("Decoding timeseries QueryResultData")
    func decodingTimeSeries() async throws {
        let raw = """
        [{"timestamp":"2021-01-01T00:00:00.000Z","result":{"d0":1609459200000}}]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .timeseries)

        let expected = QueryResult.timeSeries(TimeSeriesQueryResult(rows: [
            TimeSeriesQueryResultRow(timestamp: Date(iso8601String: "2021-01-01T00:00:00.000Z")!, result: ["d0": DoubleWrapper(1609459200000)]),
        ]))

        #expect(try await data.decode() == expected)
    }

    @Test("Decoding groupBy QueryResultData")
    func decodingGroupBy() async throws {
        let raw = """
        [{"event":{"abc":"def","uno":"due","count":12},"timestamp":"2021-10-21T12:00:00+0000","version":"v1"}]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .groupBy)

        let expected = QueryResult.groupBy(GroupByQueryResult(rows: [
            GroupByQueryResultRow(
                timestamp: randomDate,
                event: .init(metrics: ["count": .init(12)], dimensions: ["abc": .init("def"), "uno": .init("due")])
            ),
        ]))

        #expect(try await data.decode() == expected)
    }

    @Test("Decoding topN QueryResultData drops the spurious 1970-01-01 row")
    func decodingTopNFiltersBogusRow() async throws {
        let raw = """
        [
          {"result":[],"timestamp":"1970-01-01T00:00:00+0000"},
          {"result":[{"appVersion":"408","count":35}],"timestamp":"2021-12-01T00:00:00+0000"}
        ]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .topN)

        let expected = QueryResult.topN(TopNQueryResult(rows: [
            TopNQueryResultRow(
                timestamp: Date(iso8601String: "2021-12-01T00:00:00.000Z")!,
                result: [.init(metrics: ["count": .init(35)], dimensions: ["appVersion": .init("408")])]
            ),
        ]))

        #expect(try await data.decode() == expected)
    }

    @Test("Decoding scan QueryResultData")
    func decodingScan() async throws {
        let raw = """
        [{"segmentId":"seg_1","columns":["__time","type"],"events":[{"__time":1725004800000,"type":"RevenueCat.Events.CANCELLATION"}],"rowSignature":[{"name":"__time","type":"LONG"},{"name":"type","type":"STRING"}]}]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .scan)

        let expected = QueryResult.scan(ScanQueryResult(rows: [
            .init(
                segmentId: "seg_1",
                columns: ["__time", "type"],
                events: [.init(metrics: ["__time": .init(1725004800000)], dimensions: ["type": .init("RevenueCat.Events.CANCELLATION")])],
                rowSignature: [.init(name: "__time", type: "LONG"), .init(name: "type", type: "STRING")]
            ),
        ]))

        #expect(try await data.decode() == expected)
    }

    @Test("Decoding timeBoundary QueryResultData")
    func decodingTimeBoundary() async throws {
        let raw = """
        [{"timestamp":"2013-05-09T18:24:00.000Z","result":{"minTime":"2013-05-09T18:24:00.000Z","maxTime":"2013-05-09T18:37:00.000Z"}}]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .timeBoundary)

        let expected = QueryResult.timeBoundary(TimeBoundaryResult(rows: [
            .init(
                timestamp: Date(iso8601String: "2013-05-09T18:24:00.000Z")!,
                result: [
                    "minTime": Date(iso8601String: "2013-05-09T18:24:00.000Z")!,
                    "maxTime": Date(iso8601String: "2013-05-09T18:37:00.000Z")!,
                ]
            ),
        ]))

        #expect(try await data.decode() == expected)
    }

    @Test("decode() carries the query restrictions into the result")
    func decodePropagatesRestrictions() async throws {
        let restriction = QueryTimeInterval(beginningDate: randomDate - 3600 * 24 * 10, endDate: randomDate)
        let raw = """
        [{"timestamp":"2021-01-01T00:00:00.000Z","result":{"d0":1}}]
        """
        let data = QueryResultData(data: Data(raw.utf8), queryType: .timeseries, restrictions: [restriction])

        let expected = QueryResult.timeSeries(TimeSeriesQueryResult(
            rows: [TimeSeriesQueryResultRow(timestamp: Date(iso8601String: "2021-01-01T00:00:00.000Z")!, result: ["d0": DoubleWrapper(1)])],
            restrictions: [restriction]
        ))

        #expect(try await data.decode() == expected)
    }

    @Test("Decoding an unsupported query type throws")
    func decodingUnsupportedQueryTypeThrows() async throws {
        let data = QueryResultData(data: Data("[]".utf8), queryType: .funnel)
        await #expect(throws: QueryResultDataError.unsupportedQueryType(.funnel)) {
            _ = try await data.decode()
        }
    }
}
