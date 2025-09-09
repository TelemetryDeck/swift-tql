@testable import SwiftTQL
import Testing
import Foundation

struct IoConfigTests {
    let tdValueString = """
    {
      "completionTimeout": "PT7200S",
      "endpoint": "kinesis.eu-central-1.amazonaws.com",
      "idleConfig": {
        "enabled": false
      },
      "inputFormat": {
        "keepNullColumns": false,
        "type": "json"
      },
      "period": "PT30S",
      "replicas": 1,
      "startDelay": "PT5S",
      "stream": "td-ingest-1-KinesisStream-abcdef",
      "taskCount": 1,
      "taskDuration": "PT600S",
      "type": "kinesis",
      "useEarliestSequenceNumber": true
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = IoConfig.kinesis(
        .init(
            stream: "td-ingest-1-KinesisStream-abcdef",
            inputFormat: .init(type: .json, keepNullColumns: false),
            endpoint: "kinesis.eu-central-1.amazonaws.com",
            taskCount: 1,
            replicas: 1,
            taskDuration: "PT600S",
            startDelay: "PT5S",
            period: "PT30S",
            useEarliestSequenceNumber: true,
            completionTimeout: "PT7200S",
            lateMessageRejectionPeriod: nil,
            earlyMessageRejectionPeriod: nil,
            lateMessageRejectionStartDateTime: nil,
            idleConfig: .init(enabled: false, inactiveAfterMillis: nil),
            stopTaskCount: nil,
            fetchDelayMillis: nil,
            awsAssumedRoleArn: nil,
            awsExternalId: nil
        )
    )

    let testedType = IoConfig.self

    @Test("Decoding TelemetryDeck example should match expected value")
    func decodingTelemetryDeckExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        #expect(tdValue == decodedValue)
    }

    @Test("Encoding TelemetryDeck example should match expected JSON string")
    func encodingTelemetryDeckExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(tdValue)
        #expect(tdValueString == String(data: encodedValue, encoding: .utf8)!)
    }
}
