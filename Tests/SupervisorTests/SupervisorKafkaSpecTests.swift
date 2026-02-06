@testable import SwiftTQL
import XCTest

final class SupervisorKafkaSpecTests: XCTestCase {
    let tdValueString = """
    {
        "dataSchema": {
          "dataSource": "telemetry-signals",
          "timestampSpec": {
            "column": "receivedAt",
            "format": "iso",
            "missingValue": null
          },
          "dimensionsSpec": {
            "dimensions": [
              {
                "type": "string",
                "name": "appID",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "applicationName",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "appVersion",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "architecture",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "buildNumber",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "deviceType",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "isAppStore",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "isDebug",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "isSimulator",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "isTestFlight",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "isTestMode",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "locale",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "majorMinorSystemVersion",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "majorSystemVersion",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "modelName",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "float",
                "name": "floatValue",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "RevenueCat.event.commission_percentage",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "RevenueCat.event.price",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "RevenueCat.event.price_in_purchased_currency",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "RevenueCat.event.takehome_percentage",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "RevenueCat.event.tax_percentage",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Presets.Onboarding.step",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationExitMetrics.backgroundExitData.cumulativeMemoryPressureExitCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationLaunchMetrics.histogrammedExtendedLaunch.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationLaunchMetrics.histogrammedOptimizedTimeToFirstDrawKey.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationLaunchMetrics.histogrammedResumeTime.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationLaunchMetrics.histogrammedTimeToFirstDrawKey.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.0.bucketCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.0.bucketEnd.ms",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.0.bucketStart.ms",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.1.bucketCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.1.bucketEnd.ms",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationResponsivenessMetrics.histogrammedAppHangTime.histogramValue.1.bucketStart.ms",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationTimeMetrics.cumulativeBackgroundAudioTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationTimeMetrics.cumulativeBackgroundLocationTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationTimeMetrics.cumulativeBackgroundTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.applicationTimeMetrics.cumulativeForegroundTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramNumBuckets",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.0.bucketCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.0.bucketEnd.bars",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.0.bucketStart.bars",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.1.bucketCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.1.bucketEnd.bars",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cellularConditionMetrics.cellConditionTime.histogramValue.1.bucketStart.bars",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cpuMetrics.cumulativeCPUInstructions.kiloinstructions",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.cpuMetrics.cumulativeCPUTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.diskIOMetrics.cumulativeLogicalWrites.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.displayMetrics.averagePixelLuminance.averageValue.apl",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.displayMetrics.averagePixelLuminance.sampleCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.gpuMetrics.cumulativeGPUTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeBestAccuracyForNavigationTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeBestAccuracyTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeHundredMetersAccuracyTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeKilometerAccuracyTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeNearestTenMetersAccuracyTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.locationActivityMetrics.cumulativeThreeKilometersAccuracyTime.sec",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.memoryMetrics.averageSuspendedMemory.averageValue.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.memoryMetrics.averageSuspendedMemory.sampleCount",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.memoryMetrics.peakMemoryUsage.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.metaData.pid",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.networkTransferMetrics.cumulativeCellularDownload.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.networkTransferMetrics.cumulativeCellularUpload.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.networkTransferMetrics.cumulativeWifiDownload.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "string",
                "name": "TelemetryDeck.Metrics.Swift.networkTransferMetrics.cumulativeWifiUpload.kB",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": true
              },
              {
                "type": "float",
                "name": "TelemetryDeck.Metrics.Swift.displayMetrics.averagePixelLuminance.standardDeviation",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              },
              {
                "type": "float",
                "name": "TelemetryDeck.Metrics.Swift.memoryMetrics.averageSuspendedMemory.standardDeviation",
                "multiValueHandling": "SORTED_ARRAY",
                "createBitmapIndex": false
              }
            ],
            "dimensionExclusions": [
              "__time",
              "count",
              "receivedAt"
            ],
            "includeAllDimensions": true,
            "useSchemaDiscovery": false
          },
          "metricsSpec": [
            {
              "type": "count",
              "name": "count"
            }
          ],
          "granularitySpec": {
            "type": "uniform",
            "segmentGranularity": "DAY",
            "queryGranularity": "HOUR",
            "rollup": true,
            "intervals": []
          },
          "transformSpec": {
            "filter": null,
            "transforms": []
          }
        },
        "ioConfig": {
          "type": "kafka",
          "topic": "metrics",
          "inputFormat": {
            "type": "json"
          },
          "consumerProperties": {
            "bootstrap.servers": "localhost:9092"
          },
          "taskCount": 1,
          "replicas": 1,
          "taskDuration": "PT1H"
        },
        "tuningConfig": {
          "type": "kafka",
          "maxRowsPerSegment": 5000000
        }
      }
    """
    .filter { !$0.isWhitespace }

    let testedType = ParallelIndexIngestionSpec.self

    func testDecodingTelemetryDeckExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        XCTAssertEqual(decodedValue.dataSchema?.dataSource, "telemetry-signals")
    }
}
