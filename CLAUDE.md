# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftTQL is a Swift implementation of the TelemetryDeck Query Language that includes a Swift client for Apache Druid's API. The library provides comprehensive query building, data ingestion, and result handling capabilities for interacting with Apache Druid.

## Build and Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter QueryTests
swift test --filter QueryResultTests
swift test --filter QueryGenerationTests
swift test --filter SupervisorTests
swift test --filter DataSchemaTests

# Run a specific test case
swift test --filter CustomQueryTests.testRegexQueryDecoding
```

## Architecture Overview

### Core Components

1. **Query System** (`Sources/SwiftTQL/Query/`)
   - `CustomQuery` - Main query builder supporting multiple query types (groupBy, topN, scan, etc.)
   - `Filter`, `Aggregator`, `PostAggregator` - Query building blocks
   - `DimensionSpec`, `VirtualColumn` - Dimension and virtual column specifications
   - Query compilation and optimization through `CustomQuery+CompileDown`

2. **Druid Integration** (`Sources/SwiftTQL/Druid/`)
   - **Data Ingestion**: Specs for batch and streaming ingestion (Kinesis support)
   - **Configuration**: Tuning configs, compaction configs, IO configs
   - **Schema Management**: DataSchema, GranularitySpec, TransformSpec
   - **Supervisor Support**: Supervisor configurations for streaming ingestion

3. **Query Generation** (`Sources/SwiftTQL/QueryGeneration/`)
   - Specialized query generators for analytics patterns:
     - `CustomQuery+Experiment` - A/B testing queries
     - `CustomQuery+Funnel` - Funnel analysis
     - `CustomQuery+Retention` - Retention analysis
   - SQL query conversion capabilities

4. **Result Processing** (`Sources/SwiftTQL/QueryResult/`)
   - `QueryResult` - Generic result handling
   - Type-safe result parsing for different query types

5. **Chart Configuration** (`Sources/SwiftTQL/Chart Configuration/`)
   - Chart aggregation and configuration for visualization

6. **SwiftDruid** (`Sources/SwiftDruid/`) - Vapor-based HTTP client for Apache Druid's REST API
   - `Druid` - Main client struct, initialized with a base URL and Vapor `Client`
   - Route-based API organized by Druid namespace (e.g., `indexer/v1/`)
   - `SupervisorRoutes` - List and terminate Druid supervisors
   - Separate library target from SwiftTQL with no shared dependency — SwiftTQL handles query/model building, SwiftDruid handles HTTP communication

### Key Design Patterns

- **Codable Protocol**: All query and configuration types conform to Codable for JSON serialization
- **Builder Pattern**: CustomQuery uses extensive initialization parameters for flexible query construction
- **Type Safety**: Strong typing throughout with enums for query types, granularities, etc.
- **Hashable/Equatable**: Most types support these protocols for testing and caching

### Test Organization

Tests are organized by functional area with comprehensive coverage:
- Each major component has its own test target
- Tests use XCTest framework
- JSON serialization/deserialization tests validate Druid API compatibility

## Dependencies

- **SwiftDateOperations** (1.0.5+): Date manipulation utilities
- **swift-crypto** (3.8.0+): Cryptographic operations for hashing
- **Vapor** (4.89.0+): HTTP client used by SwiftDruid target only

## Platform Requirements

- macOS 11.0+
- Swift 5.9+