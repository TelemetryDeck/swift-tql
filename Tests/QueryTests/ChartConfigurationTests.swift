import SwiftTQL
import Testing
import Foundation

struct ChartConfigurationTests {
    @Test("Chart configuration") func chartConfiguration() throws {
        let chartConfiguration = ChartConfiguration(
            displayMode: .barChart,
            darkMode: false,
            options: .init(animation: false),
            aggregationConfiguration: .init(stack: "hello")
        )

        let encodedChartConfiguration = """
        {
            "aggregationConfiguration": {
                "stack": "hello"
            },
            "darkMode": false,
            "displayMode": "barChart",
            "options": {
                "animation": false
            }
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(chartConfiguration)
        #expect(String(data: encoded, encoding: .utf8)! == encodedChartConfiguration)

        let decoded = try JSONDecoder.telemetryDecoder.decode(ChartConfiguration.self, from: encoded)
        #expect(chartConfiguration == decoded)
    }
}
