import Foundation

/// Extraction functions define the transformation applied to each dimension value.
public indirect enum ExtractionFunction: Codable, Equatable {
    case regex(RegularExpressionExtractionFunction)
}

/// Returns the first matching group for the given regular expression. If there is no match,
/// it returns the dimension value as is.
public struct RegularExpressionExtractionFunction: Codable, Equatable {
    /// The regular expression to match.
    ///
    /// For example, using `(\\w\\w\\w).*` will transform 'Monday', 'Tuesday', 'Wednesday' into 'Mon', 'Tue', 'Wed'.
    let expr: String?
    
    /// The group to extract, default 1
    let index: Int?
    let replaceMissingValue: Bool?
    let replaceMissingValueWith: String?
}
