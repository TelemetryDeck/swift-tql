@testable import SwiftDruid
import Testing

@Suite("SupervisorRoutes Tests")
struct SupervisorRoutesTests {
    @Test("create posts to the bare supervisor URL by default")
    func createURLDefault() {
        #expect(
            SupervisorRoutes.createURL(baseURL: "http://druid:8888/druid/", skipRestartIfUnmodified: false)
                == "http://druid:8888/druid/indexer/v1/supervisor"
        )
    }

    @Test("create asks Druid to skip the restart for an unchanged spec")
    func createURLSkipRestart() {
        #expect(
            SupervisorRoutes.createURL(baseURL: "http://druid:8888/druid/", skipRestartIfUnmodified: true)
                == "http://druid:8888/druid/indexer/v1/supervisor?skipRestartIfUnmodified=true"
        )
    }
}
