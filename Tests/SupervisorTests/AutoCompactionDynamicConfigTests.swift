@testable import SwiftTQL
import Testing
import Foundation

struct AutoCompactionDynamicConfigTests {
    /// As returned by `GET /druid/indexer/v1/compaction/config/datasources/hanne.work` on Druid 37
    let druidValueString = """
    {"type":"inline","dataSource":"hanne.work","taskPriority":25,"inputSegmentSizeBytes":100000000000000,"maxRowsPerSegment":null,\
    "skipOffsetFromLatest":"P1D","tuningConfig":{"maxRowsInMemory":null,"appendableIndexSpec":null,"maxBytesInMemory":null,\
    "maxTotalRows":null,"splitHintSpec":null,"partitionsSpec":{"type":"dynamic","maxRowsPerSegment":5000000,"maxTotalRows":null},\
    "indexSpec":null,"indexSpecForIntermediatePersists":null,"maxPendingPersists":null,"pushTimeout":null,\
    "segmentWriteOutMediumFactory":null,"maxNumConcurrentSubTasks":1,"maxRetry":null,"taskStatusCheckPeriodMs":null,\
    "chatHandlerTimeout":null,"chatHandlerNumRetries":null,"maxNumSegmentsToMerge":null,"totalNumMergeTasks":null,\
    "maxColumnsToMerge":null,"type":"index_parallel","forceGuaranteedRollup":false},"granularitySpec":{"segmentGranularity":"MONTH"},\
    "dimensionsSpec":null,"metricsSpec":null,"transformSpec":null,"projections":null,"ioConfig":null,"engine":null,"taskContext":null}
    """

    let druidValue = AutoCompactionDynamicConfig(
        dataSource: "hanne.work",
        taskPriority: 25,
        inputSegmentSizeBytes: 100_000_000_000_000,
        skipOffsetFromLatest: "P1D",
        tuningConfig: .indexParallel(.init(
            partitionsSpec: .dynamic(.init(maxRowsPerSegment: 5_000_000)),
            forceGuaranteedRollup: false,
            maxNumConcurrentSubTasks: 1
        )),
        granularitySpec: .init(segmentGranularity: .month),
        maxRowsPerSegment: nil
    )

    let testedType = AutoCompactionDynamicConfig.self

    func withIOConfig(_ ioConfig: CompactionIOConfig?) -> AutoCompactionDynamicConfig {
        AutoCompactionDynamicConfig(
            dataSource: druidValue.dataSource,
            taskPriority: druidValue.taskPriority,
            inputSegmentSizeBytes: druidValue.inputSegmentSizeBytes,
            skipOffsetFromLatest: druidValue.skipOffsetFromLatest,
            tuningConfig: druidValue.tuningConfig,
            granularitySpec: druidValue.granularitySpec,
            maxRowsPerSegment: druidValue.maxRowsPerSegment,
            ioConfig: ioConfig
        )
    }

    @Test("Decoding a config returned by Druid should match expected value")
    func decodingDruidExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: druidValueString.data(using: .utf8)!)
        #expect(druidValue == decodedValue)
        #expect(decodedValue.ioConfig == nil)
    }

    @Test("Decoding a config returned by Druid with dropExisting set")
    func decodingDruidExampleWithIOConfig() throws {
        for ioConfigString in [#"{"dropExisting":true}"#, #"{"type":"compact","dropExisting":true}"#] {
            let valueString = druidValueString.replacingOccurrences(of: #""ioConfig":null"#, with: #""ioConfig":\#(ioConfigString)"#)
            let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: valueString.data(using: .utf8)!)
            #expect(decodedValue == withIOConfig(.init(dropExisting: true)))
        }
    }

    @Test("Round-tripping with and without ioConfig", arguments: [nil, CompactionIOConfig(dropExisting: true)])
    func roundTrip(ioConfig: CompactionIOConfig?) throws {
        let value = withIOConfig(ioConfig)
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(value)
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: encodedValue)
        #expect(value == decodedValue)

        let json = try #require(JSONSerialization.jsonObject(with: encodedValue) as? [String: Any])
        if ioConfig == nil {
            #expect(json["ioConfig"] == nil)
        } else {
            let ioConfigJSON = try #require(json["ioConfig"] as? [String: Any])
            #expect(ioConfigJSON["type"] as? String == "compact")
            #expect(ioConfigJSON["dropExisting"] as? Bool == true)
        }
    }

    @Test("Encoding a range partitionsSpec")
    func encodingRangePartitionsSpec() throws {
        let value = AutoCompactionDynamicConfig(
            dataSource: "com.example",
            taskPriority: 25,
            inputSegmentSizeBytes: 100_000_000_000_000,
            skipOffsetFromLatest: "P1D",
            tuningConfig: .indexParallel(.init(
                partitionsSpec: .range(.init(
                    partitionDimensions: ["appID", "type", "clientUser"],
                    targetRowsPerSegment: 2_000_000,
                    assumeGrouped: false
                )),
                forceGuaranteedRollup: true,
                maxNumConcurrentSubTasks: 4
            )),
            granularitySpec: .init(segmentGranularity: .month),
            maxRowsPerSegment: nil,
            ioConfig: .init(dropExisting: true)
        )

        let encodedValue = try JSONEncoder.telemetryEncoder.encode(value)
        let encodedString = try #require(String(data: encodedValue, encoding: .utf8))
        #expect(encodedString.contains(#""type":"range""#))
        #expect(encodedString.contains(#""partitionDimensions":["appID","type","clientUser"]"#))
        #expect(encodedString.contains(#""targetRowsPerSegment":2000000"#))
        #expect(encodedString.contains(#""forceGuaranteedRollup":true"#))
        #expect(encodedString.contains(#""dropExisting":true"#))

        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: encodedValue)
        #expect(value == decodedValue)
    }

    @Test("Encoding CompactionIOConfig should match expected JSON string")
    func encodingIOConfig() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(CompactionIOConfig(dropExisting: true))
        let json = try #require(JSONSerialization.jsonObject(with: encodedValue) as? [String: AnyHashable])
        #expect(json == ["type": "compact", "dropExisting": true])

        let encodedEmptyValue = try JSONEncoder.telemetryEncoder.encode(CompactionIOConfig())
        #expect(String(data: encodedEmptyValue, encoding: .utf8) == #"{"type":"compact"}"#)
    }
}
