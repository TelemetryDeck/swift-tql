import SwiftTQL
import Testing
import Foundation

struct ChartAggregtionConfigurationTests {
    @Test("Chart aggregation configuration") func chartAggregationConfiguration() throws {
        let aggregationConfiguration = ChartAggregationConfiguration(
            startAngle: 12,
            endAngle: 13,
            radius: ["12%", "50%"],
            center: ["0%", "12%"],
            stack: "hello"
        )

        let encodedAggregationConfiguration = """
        {
            "center": ["0%", "12%"],
            "endAngle": 13,
            "radius": ["12%", "50%"],
            "stack": "hello",
            "startAngle": 12
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(aggregationConfiguration)
        #expect(String(data: encoded, encoding: .utf8)! == encodedAggregationConfiguration)

        let decoded = try JSONDecoder.telemetryDecoder.decode(ChartAggregationConfiguration.self, from: encoded)
        #expect(aggregationConfiguration == decoded)
    }
}
