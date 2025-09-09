import SwiftTQL
import Testing
import Foundation

struct TopNQueryTests {
    let exampleTopNQueryString = """
        {
            "aggregations": [{"name":"count","type":"count"}],
            "dataSource":"telemetry-signals",
            "dimension":{"dimension":"appVersion","outputName":"appVersion","type":"default"},
            "granularity":"all",
            "intervals":["2021-12-03T00:00:00.000Z/2022-01-31T22:59:59.999Z"],
            "metric": {
                "ordering":"version",
                "type":"dimension"
            },
            "queryType":"topN",
            "threshold":1048576
        }
    """

    static let beginDate: Date = Formatter.iso8601().date(from: "2021-12-03T00:00:00.000Z")!
    static let endDate: Date = Formatter.iso8601().date(from: "2022-01-31T22:59:59.999Z")!

    let exampleTopNQuery = CustomQuery(
        queryType: .topN,
        dataSource: "telemetry-signals",
        intervals: [.init(beginningDate: beginDate, endDate: endDate)],
        granularity: .all,
        aggregations: [.count(.init(name: "count"))],
        threshold: 1_048_576,
        metric: .dimension(.init(ordering: .version)),
        dimension: .default(.init(dimension: "appVersion", outputName: "appVersion"))
    )

    @Test("Encoding")
    func encoding() throws {
        let encodedQuery = try JSONEncoder.telemetryEncoder.encode(exampleTopNQuery)
        #expect(String(data: encodedQuery, encoding: .utf8)! == exampleTopNQueryString.filter { !$0.isWhitespace })
    }

    @Test("Decoding")
    func decoding() throws {
        let decodedQuery = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: exampleTopNQueryString.data(using: .utf8)!)
        #expect(decodedQuery == exampleTopNQuery)
    }
}