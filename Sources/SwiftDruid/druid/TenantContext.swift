import Foundation
import Vapor

/// Identifies the organization user on whose behalf a Druid query runs.
///
/// The Druid tenant-auth extension reads two plain-text headers, `X-TD-Namespaces` and
/// `X-TD-User`, authenticates the user from them, and restricts the query to the listed
/// datasources. A request without a `TenantContext` sends neither header and runs as an
/// internal request with full access.
public struct TenantContext: Sendable, Equatable {
    public static let namespacesHeaderName = "X-TD-Namespaces"
    public static let userHeaderName = "X-TD-User"

    /// Upper bound for the joined namespaces value. Druid's Jetty default for the whole request
    /// header block is 8 KiB, so the client refuses anything above half of that.
    public static let maxHeaderValueBytes = 4096

    /// The ID of the user who made the request. Sent as the Druid identity.
    public let userID: UUID

    /// The namespaces of every organization the user belongs to, in order, without trimming.
    /// Druid allows DATASOURCE READ on exactly these names.
    public let namespaces: [String]

    public init(userID: UUID, namespaces: [String]) {
        self.userID = userID
        self.namespaces = namespaces
    }

    /// The two headers for this context.
    ///
    /// Throws `TenantContextError` when the namespaces would not pass the extension's checks:
    /// an empty list, an empty entry, a character outside `[a-z0-9.-]`, or a joined value larger
    /// than `maxHeaderValueBytes`. Callers validate before they open a request so that a bad
    /// value never reaches Druid and never counts as a server failure.
    public func headers() throws -> HTTPHeaders {
        guard !namespaces.isEmpty else {
            throw TenantContextError.emptyNamespaces
        }

        for (index, namespace) in namespaces.enumerated() {
            guard !namespace.isEmpty else {
                throw TenantContextError.emptyNamespace(index: index)
            }
            guard namespace.utf8.allSatisfy(Self.isAllowedNamespaceByte) else {
                throw TenantContextError.invalidCharacter(namespace: namespace)
            }
        }

        let namespacesValue = namespaces.joined(separator: ",")
        let bytes = namespacesValue.utf8.count
        guard bytes <= Self.maxHeaderValueBytes else {
            throw TenantContextError.headerTooLarge(bytes: bytes)
        }

        var headers = HTTPHeaders()
        headers.add(name: Self.namespacesHeaderName, value: namespacesValue)
        headers.add(name: Self.userHeaderName, value: userID.uuidString)
        return headers
    }

    /// `[a-z0-9.-]`. The comma is the list separator and is not allowed inside an entry.
    private static func isAllowedNamespaceByte(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "."),
             UInt8(ascii: "-"):
            return true
        default:
            return false
        }
    }
}

public enum TenantContextError: Error, Equatable, LocalizedError {
    /// The namespace list is empty.
    case emptyNamespaces
    /// The entry at `index` is an empty string.
    case emptyNamespace(index: Int)
    /// `namespace` contains a character outside `[a-z0-9.-]`.
    case invalidCharacter(namespace: String)
    /// The joined header value is `bytes` long, more than `TenantContext.maxHeaderValueBytes`.
    case headerTooLarge(bytes: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyNamespaces:
            return "The tenant context has no namespaces."
        case let .emptyNamespace(index):
            return "The tenant namespace at index \(index) is empty."
        case let .invalidCharacter(namespace):
            return "The tenant namespace '\(namespace)' contains a character outside [a-z0-9.-]."
        case let .headerTooLarge(bytes):
            return "The tenant namespaces header is \(bytes) bytes, more than the maximum of \(TenantContext.maxHeaderValueBytes) bytes."
        }
    }
}
