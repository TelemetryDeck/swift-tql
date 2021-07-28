import Foundation

public extension DTO {
    struct AppAdminEntry: Codable, Identifiable {
        public let id: UUID
        public let appName: String?
        public let organisationName: String?
        public let organisationID: UUID?
        public let signalCount: Int
        public let userCount: Int
        public var tier: TierType {
            if signalCount > 5_000_000 {
                return .tier2
            }
            if signalCount > 100_000 {
                return .tier1
            }
            if signalCount > 100 {
                return .free
            }
            return .explorers
        }
                
        public enum TierType {
            case explorers
            case free
            case tier1
            case tier2
            
            var stringDescription: String {
                switch self {
                    case .explorers: return "Explorers"
                    case .free: return "Free Tier"
                    case .tier1: return "Tier 1"
                    case .tier2: return "Tier 2"
                }
            }
        }
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.AppAdminEntry: Content {}
#endif
