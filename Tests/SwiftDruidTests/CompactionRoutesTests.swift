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
}
