import Foundation
@testable import SwiftDruid
import Testing

@Suite("Druid error body tests")
struct DruidErrorTests {
    private func decode(_ json: String) throws -> DruidError {
        try JSONDecoder().decode(DruidError.self, from: Data(json.utf8))
    }

    @Test("A deny from an authorizer keeps its reason")
    func accessCheckResult() throws {
        let error = try decode(#"{"Access-Check-Result":"Unauthorized, DATASOURCE READ is not allowed"}"#)
        #expect(error.localizedDescription == "Access denied: Unauthorized, DATASOURCE READ is not allowed")
    }

    @Test("A query error body keeps its fields, and the text does not name Druid")
    func queryError() throws {
        let error = try decode(#"{"error":"druidException","errorMessage":"Object 'x' not found","errorCode":"invalidInput"}"#)
        #expect(error.localizedDescription == "Error: queryError, Message: Object 'x' not found, Code: invalidInput")
    }

    @Test("The text does not contain the host or the Java class")
    func noHostOrClass() throws {
        let error = try decode(
            #"{"error":"Unknown exception","errorMessage":"Faulty channel","errorClass":"org.jboss.netty.channel.ChannelException","host":"druid-historical-1:8083"}"#
        )
        #expect(error.localizedDescription == "Error: Unknown exception, Message: Faulty channel")
    }

    @Test("A body without a known field is an unknown error")
    func unknownBody() throws {
        #expect(try decode("{}").localizedDescription == "Unknown query error")
    }
}
