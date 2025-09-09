import SwiftTQL
import Testing
import Foundation

struct ScanQueryResultTests {
    @Test("Regular scan query result encoding and decoding")
    func regularScanQueryResult() throws {
        let stringRepresentation = """
        [{
            "columns": ["__time", "clientUser"],
            "events": [{
                "__time": 1741168800000,
                "clientUser": "3b140ae"
            }],
            "rowSignature": [{
                "name": "__time",
                "type": "LONG"
            }, {
                "name": "clientUser",
                "type": "STRING"
            }]
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation: [ScanQueryResultRow] = [
            .init(
                columns: ["__time", "clientUser"],
                events: [
                    .init(metrics: ["__time": .init(1741168800000)], dimensions: ["clientUser": .init("3b140ae")], nullValues: [])
                ],
                rowSignature: [.init(name: "__time", type: "LONG"), .init(name: "clientUser", type: "STRING")]
            )
        ]

        let decoded = try JSONDecoder.telemetryDecoder.decode([ScanQueryResultRow].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decoded == swiftRepresentation)

        let encoded = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encoded, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Scan query result with multi-dimensional values")
    func scanQueryResultWithMultiDimValues() throws {
        let stringRepresentation = """
        [{
            "columns": ["__time", "payload"],
            "events": [{
                "__time": 1741168800000,
                "payload": [
                    "TelemetryDeck.API.Ingest.version:v2",
                    "TelemetryDeck.Accessibility.isInvertColorsEnabled:false",
                    "TelemetryDeck.Accessibility.isReduceMotionEnabled:false"
                ]
            }],
            "rowSignature": [{
                "name": "__time",
                "type": "LONG"
            }, {
                "name": "payload",
                "type": "STRING"
            }]
        }]

        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation: [ScanQueryResultRow] = [
            .init(
                columns: ["__time", "payload"],
                events: [
                    .init(
                        metrics: ["__time": .init(1741168800000)],
                        dimensions: ["payload": .init([
                            "TelemetryDeck.API.Ingest.version:v2",
                            "TelemetryDeck.Accessibility.isInvertColorsEnabled:false",
                            "TelemetryDeck.Accessibility.isReduceMotionEnabled:false"
                        ])],
                        nullValues: []
                    )
                ],
                rowSignature: [.init(name: "__time", type: "LONG"), .init(name: "payload", type: "STRING")]
            )
        ]

        let decoded = try JSONDecoder.telemetryDecoder.decode([ScanQueryResultRow].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decoded == swiftRepresentation)

        let encoded = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encoded, encoding: .utf8)! == stringRepresentation)
    }
}
