@testable import SwiftTQL
import Testing
import Foundation

struct QueryTimeIntervalTests {
    let exampleData = """
    {
      "type": "intervals",
      "intervals": [
        "-146136543-09-08T08:23:32.096Z/146140482-04-24T15:36:27.903Z"
      ]
    }
    """
    .filter { !$0.isWhitespace }
    .data(using: .utf8)!

    @Test("Decoding query time interval")
    func decodingQueryTimeInterval() throws {
        _ = try JSONDecoder.telemetryDecoder.decode(QueryTimeIntervalsContainer.self, from: exampleData)
    }
}