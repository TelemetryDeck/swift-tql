@testable import SwiftDruid
import Foundation
import Testing

@Suite("CompactionRoutes Tests")
struct CompactionRoutesTests {
    /// Shape returned by `GET /druid/indexer/v1/compaction/config/datasources` on Druid 37 (trimmed to two entries)
    let listResponseString = """
    {"compactionConfigs":[\
    {"type":"inline","dataSource":"com.blasiappstudio","taskPriority":25,"inputSegmentSizeBytes":100000000000000,\
    "maxRowsPerSegment":null,"skipOffsetFromLatest":"P1D","tuningConfig":{"partitionsSpec":{"type":"dynamic",\
    "maxRowsPerSegment":5000000,"maxTotalRows":null},"maxNumConcurrentSubTasks":1,"type":"index_parallel",\
    "forceGuaranteedRollup":false},"granularitySpec":{"segmentGranularity":"MONTH"},"dimensionsSpec":null,"metricsSpec":null,\
    "transformSpec":null,"projections":null,"ioConfig":null,"engine":null,"taskContext":null},\
    {"type":"inline","dataSource":"hanne.work","taskPriority":25,"inputSegmentSizeBytes":100000000000000,\
    "maxRowsPerSegment":null,"skipOffsetFromLatest":"P1D","tuningConfig":null,"granularitySpec":{"segmentGranularity":"MONTH"},\
    "ioConfig":{"dropExisting":true},"engine":null,"taskContext":null}\
    ]}
    """

    @Test("Decoding the unified API list response")
    func decodingListResponse() throws {
        let response = try JSONDecoder().decode(
            CompactionRoutes.CompactionConfigsResponse.self,
            from: listResponseString.data(using: .utf8)!
        )

        #expect(response.compactionConfigs.map(\.dataSource) == ["com.blasiappstudio", "hanne.work"])
        #expect(response.compactionConfigs.map(\.type) == ["inline", "inline"])
        #expect(response.compactionConfigs[0].ioConfig == nil)
        #expect(response.compactionConfigs[1].ioConfig?.dropExisting == true)
        #expect(response.compactionConfigs[1].skipOffsetFromLatest == "P1D")
        #expect(response.compactionConfigs[1].taskPriority == 25)
    }

    @Test("Decoding the stored tuning and granularity config")
    func decodingTuningConfig() throws {
        let response = try JSONDecoder().decode(
            CompactionRoutes.CompactionConfigsResponse.self,
            from: listResponseString.data(using: .utf8)!
        )

        let dynamic = response.compactionConfigs[0]
        #expect(dynamic.tuningConfig?.partitionsSpec?.type == "dynamic")
        #expect(dynamic.tuningConfig?.partitionsSpec?.maxRowsPerSegment == 5_000_000)
        #expect(dynamic.tuningConfig?.maxNumConcurrentSubTasks == 1)
        #expect(dynamic.granularitySpec?.segmentGranularity == .month)

        #expect(response.compactionConfigs[1].tuningConfig == nil)
    }

    @Test("Decoding single_dim and range partitionsSpecs")
    func decodingPartitionedConfigs() throws {
        let singleDim = """
        {"type":"inline","dataSource":"a","taskPriority":25,"skipOffsetFromLatest":"P1D","tuningConfig":{\
        "type":"index_parallel","partitionsSpec":{"type":"single_dim","partitionDimension":"appID",\
        "targetRowsPerSegment":null,"maxRowsPerSegment":5000000,"assumeGrouped":false},\
        "maxNumConcurrentSubTasks":5}}
        """
        let range = """
        {"type":"inline","dataSource":"b","taskPriority":25,"skipOffsetFromLatest":"P2D","tuningConfig":{\
        "type":"index_parallel","partitionsSpec":{"type":"range","partitionDimensions":["appID","type"],\
        "targetRowsPerSegment":3000000,"maxRowsPerSegment":null,"assumeGrouped":false},\
        "maxNumConcurrentSubTasks":10},"granularitySpec":{"segmentGranularity":"MONTH","queryGranularity":null}}
        """

        let decodedSingleDim = try JSONDecoder().decode(
            CompactionRoutes.CompactionConfigReturnType.self, from: singleDim.data(using: .utf8)!
        )
        #expect(decodedSingleDim.tuningConfig?.partitionsSpec?.type == "single_dim")
        #expect(decodedSingleDim.tuningConfig?.partitionsSpec?.partitionDimension == "appID")
        #expect(decodedSingleDim.tuningConfig?.partitionsSpec?.maxRowsPerSegment == 5_000_000)
        #expect(decodedSingleDim.granularitySpec == nil)

        let decodedRange = try JSONDecoder().decode(
            CompactionRoutes.CompactionConfigReturnType.self, from: range.data(using: .utf8)!
        )
        #expect(decodedRange.tuningConfig?.partitionsSpec?.partitionDimensions == ["appID", "type"])
        #expect(decodedRange.tuningConfig?.partitionsSpec?.targetRowsPerSegment == 3_000_000)
        #expect(decodedRange.tuningConfig?.maxNumConcurrentSubTasks == 10)
        #expect(decodedRange.skipOffsetFromLatest == "P2D")
    }
}
