import Foundation

/// DimensionSpecs define how dimension values get transformed prior to aggregation.
///
/// The default dimensionSpec returns dimension values as is and optionally renames the dimension.
///
/// If an etraction function is set, it returns dimension values transformed using the given
/// extraction function.
public struct DimensionSpec: Codable, Equatable {
    public enum DimensionSpecType: String, Codable, Equatable {
        case `default`
        case extraction
    }
    
    public enum OutputType: String, Codable, Equatable {
        case string = "STRING"
        case long = "LONG"
        case float = "FLOAT"
    }
    
    let type: DimensionSpecType
    let dimension: String
    let outputName: String
    let outputType: OutputType?
}
