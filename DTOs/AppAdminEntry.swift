import Foundation
import SwiftUI

public extension DTO {
    struct AppAdminEntry: Codable, Identifiable, Equatable {
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
            
            #if canImport(Vapor)
            #else
            var stringDescription: String {
                switch self {
                    case .explorers: return "Explorers"
                    case .free: return "Free Tier"
                    case .tier1: return "Tier 1"
                    case .tier2: return "Tier 2"
                }
            }

            @available(macOS 12, iOS 15, *)
            var tierColor: Color {
                switch self {
                case .explorers: return Color.secondary.opacity(0.9)
                case .free: return Color.mint.opacity(0.7)
                case .tier1: return Color.indigo.opacity(0.9)
                case .tier2: return Color.telemetryOrange.opacity(0.7)
                }
            }
            #endif
        }
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.AppAdminEntry: Content {}
#endif
