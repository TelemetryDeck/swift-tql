import Foundation

/// Extraction functions define the transformation applied to each dimension value.
public struct ExtractionFunction: Codable, Equatable {
    public enum ExtractionFunctionType: String, Codable, Equatable {
        /// Returns the first matching group for the given regular expression. If there is no match, it returns the dimension value as is.
        case regex
    }
    
    let type: ExtractionFunctionType
    
    /// If type is regex, the regular expression to match.
    ///
    /// For example, using `(\\w\\w\\w).*` will transform 'Monday', 'Tuesday', 'Wednesday' into 'Mon', 'Tue', 'Wed'.
    let expr: String?
    
    /// If type regex, the group to extract, default 1
    let index: Int?
    
    /// If type regex,
    let replaceMissingValue: Bool?
    
    /// If type regex,
    let replaceMissingValueWith: String?
    
}
