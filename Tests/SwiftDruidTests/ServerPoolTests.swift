@testable import SwiftDruid
import Logging
import Testing

@Suite("ServerPool Tests")
struct ServerPoolTests {
    let logger = Logger(label: "SwiftDruid.Tests")

    @Test("Round-robin cycles through servers in order")
    func roundRobin() async {
        let pool = ServerPool(
            baseURLs: ["http://a/", "http://b/", "http://c/"],
            unavailableDuration: 60,
            logger: logger
        )

        let first = await pool.nextServer()
        let second = await pool.nextServer()
        let third = await pool.nextServer()
        let fourth = await pool.nextServer()

        #expect(first == "http://a/")
        #expect(second == "http://b/")
        #expect(third == "http://c/")
        #expect(fourth == "http://a/")
    }

    @Test("Single server always returns the same URL")
    func singleServer() async {
        let pool = ServerPool(
            baseURLs: ["http://only/"],
            unavailableDuration: 60,
            logger: logger
        )

        for _ in 0..<5 {
            let server = await pool.nextServer()
            #expect(server == "http://only/")
        }
    }

    @Test("Unavailable server is skipped")
    func markUnavailableSkips() async {
        let pool = ServerPool(
            baseURLs: ["http://a/", "http://b/", "http://c/"],
            unavailableDuration: 60,
            logger: logger
        )

        // Advance to "a", then mark it unavailable
        _ = await pool.nextServer()
        await pool.markUnavailable("http://a/")

        // Next calls should skip "a"
        let second = await pool.nextServer()
        let third = await pool.nextServer()
        let fourth = await pool.nextServer()

        #expect(second == "http://b/")
        #expect(third == "http://c/")
        // Wraps around, skips "a", returns "b"
        #expect(fourth == "http://b/")
    }

    @Test("Returns nil when all servers are unavailable")
    func allUnavailable() async {
        let pool = ServerPool(
            baseURLs: ["http://a/", "http://b/"],
            unavailableDuration: 60,
            logger: logger
        )

        await pool.markUnavailable("http://a/")
        await pool.markUnavailable("http://b/")

        let result = await pool.nextServer()
        #expect(result == nil)
    }

    @Test("Server recovers after unavailability duration expires")
    func serverRecovery() async {
        // Use a very short duration so we can test recovery
        let pool = ServerPool(
            baseURLs: ["http://a/", "http://b/"],
            unavailableDuration: 0.01,
            logger: logger
        )

        await pool.markUnavailable("http://a/")
        await pool.markUnavailable("http://b/")

        // Immediately, both should be unavailable
        let immediate = await pool.nextServer()
        #expect(immediate == nil)

        // Wait for the duration to expire
        try? await Task.sleep(for: .milliseconds(20))

        // Now both should be available again
        let recovered = await pool.nextServer()
        #expect(recovered != nil)
    }

    @Test("Multiple unavailable servers leaves remaining ones in rotation")
    func partialUnavailability() async {
        let pool = ServerPool(
            baseURLs: ["http://a/", "http://b/", "http://c/", "http://d/"],
            unavailableDuration: 60,
            logger: logger
        )

        await pool.markUnavailable("http://a/")
        await pool.markUnavailable("http://c/")

        // Should only get b and d
        var results: [String] = []
        for _ in 0..<4 {
            if let server = await pool.nextServer() {
                results.append(server)
            }
        }

        #expect(results.allSatisfy { $0 == "http://b/" || $0 == "http://d/" })
        #expect(results.contains("http://b/"))
        #expect(results.contains("http://d/"))
    }
}
