import Foundation

/// The selector filter will match a specific dimension with a specific value.
/// Selector filters can be used as the base filters for more complex Boolean
/// expressions of filters.
public struct DruidFilterSelector: Codable {
    public init(dimension: String, value: String) {
        self.dimension = dimension
        self.value = value
    }
    
    public let dimension: String
    public let value: String
}

/// The column comparison filter is similar to the selector filter, but instead
/// compares dimensions to each other.
public struct DruidFilterColumnComparison: Codable {
    public init(dimensions: [String]) {
        self.dimensions = dimensions
    }
    
    public let dimensions: [String]
}

/// The regular expression filter is similar to the selector filter, but using regular
/// expressions. It matches the specified dimension with the given pattern. The
/// pattern can be any standard Java regular expression.
///
/// @see http://docs.oracle.com/javase/6/docs/api/java/util/regex/Pattern.html
public struct DruidFilterRegex: Codable {
    public init(dimension: String, pattern: String) {
        self.dimension = dimension
        self.pattern = pattern
    }
    
    public let dimension: String
    public let pattern: String
}

// logical expression filters
public struct DruidFilterExpression: Codable {
    public init(fields: [DruidFilter]) {
        self.fields = fields
    }
    
    public let fields: [DruidFilter]
}

public struct DruidFilterNot: Codable {
    public init(field: DruidFilter) {
        self.field = field
    }
    
    public let field: DruidFilter
}

/// A filter is a JSON object indicating which rows of data should be included in the computation
/// for a query. It’s essentially the equivalent of the WHERE clause in SQL.
public indirect enum DruidFilter: Codable {
    /// The selector filter will match a specific dimension with a specific value.
    /// Selector filters can be used as the base filters for more complex Boolean
    /// expressions of filters.
    case selector(DruidFilterSelector)

    /// The column comparison filter is similar to the selector filter, but instead
    /// compares dimensions to each other.
    case columnComparison(DruidFilterColumnComparison)

    /// The regular expression filter is similar to the selector filter, but using regular
    /// expressions. It matches the specified dimension with the given pattern. The
    /// pattern can be any standard Java regular expression.
    case regex(DruidFilterRegex)

    // logical expression filters
    case and(DruidFilterExpression)
    case or(DruidFilterExpression)
    case not(DruidFilterNot)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)

        switch type {
        case "selector":
            self = .selector(try DruidFilterSelector(from: decoder))
        case "columnComparison":
            self = .columnComparison(try DruidFilterColumnComparison(from: decoder))
        case "regex":
            self = .regex(try DruidFilterRegex(from: decoder))
        case "and":
            self = .and(try DruidFilterExpression(from: decoder))
        case "or":
            self = .or(try DruidFilterExpression(from: decoder))
        case "not":
            self = .not(try DruidFilterNot(from: decoder))
        default:
            throw EncodingError.invalidValue("Invalid type", .init(codingPath: [CodingKeys.type], debugDescription: "Invalid Type", underlyingError: nil))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .selector(let selector):
            try container.encode("selector", forKey: .type)
            try selector.encode(to: encoder)
        case .columnComparison(let columnComparison):
            try container.encode("columnComparison", forKey: .type)
            try columnComparison.encode(to: encoder)
        case .regex(let regex):
            try container.encode("regex", forKey: .type)
            try regex.encode(to: encoder)
        case .and(let and):
            try container.encode("and", forKey: .type)
            try and.encode(to: encoder)
        case .or(let or):
            try container.encode("or", forKey: .type)
            try or.encode(to: encoder)
        case .not(let not):
            try container.encode("not", forKey: .type)
            try not.encode(to: encoder)
        }
    }
}
