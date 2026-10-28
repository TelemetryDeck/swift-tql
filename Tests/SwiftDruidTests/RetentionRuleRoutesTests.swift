@testable import SwiftDruid
import Foundation
import SwiftTQL
import Testing

@Suite("RetentionRuleRoutes Tests")
struct RetentionRuleRoutesTests {
    @Test("Building the rules URLs")
    func rulesURL() {
        let baseURL = "http://druid:8888/druid/"
        #expect(RetentionRuleRoutes.rulesURL(baseURL: baseURL) == "http://druid:8888/druid/coordinator/v1/rules")
        #expect(
            RetentionRuleRoutes.rulesURL(baseURL: baseURL, dataSource: "com.example")
                == "http://druid:8888/druid/coordinator/v1/rules/com.example"
        )
        #expect(
            RetentionRuleRoutes.rulesURL(baseURL: baseURL, dataSource: "com.example", full: true)
                == "http://druid:8888/druid/coordinator/v1/rules/com.example?full"
        )
    }

    /// Shape returned by `GET /druid/coordinator/v1/rules` on Druid 37 (`_default` is the production default)
    @Test("Decoding the rules list response")
    func decodingListResponse() throws {
        let responseString = """
        {"_default":[{"period":"P2M","includeFuture":false,"tieredReplicants":{"_default_tier":2,"slower":0},\
        "useDefaultTierForNull":true,"type":"loadByPeriod"},{"period":"P36M","includeFuture":false,\
        "tieredReplicants":{"_default_tier":0,"slower":1},"useDefaultTierForNull":true,"type":"loadByPeriod"},\
        {"tieredReplicants":{},"useDefaultTierForNull":false,"type":"loadForever"}],\
        "com.example":[{"period":"P1Y","includeFuture":true,"tieredReplicants":{"hot":1,"_default_tier":1},\
        "useDefaultTierForNull":true,"type":"loadByPeriod"},{"period":"P1Y","type":"dropBeforeByPeriod"}],\
        "com.gone":[]}
        """

        let rules = try JSONDecoder().decode([String: [RetentionRule]].self, from: responseString.data(using: .utf8)!)

        #expect(rules["_default"] == [
            .loadByPeriod(
                period: "P2M",
                includeFuture: false,
                tieredReplicants: ["_default_tier": 2, "slower": 0],
                useDefaultTierForNull: true
            ),
            .loadByPeriod(
                period: "P36M",
                includeFuture: false,
                tieredReplicants: ["_default_tier": 0, "slower": 1],
                useDefaultTierForNull: true
            ),
            .loadForever(tieredReplicants: [:], useDefaultTierForNull: false),
        ])
        #expect(rules["com.example"] == [
            .loadByPeriod(
                period: "P1Y",
                includeFuture: true,
                tieredReplicants: ["hot": 1, "_default_tier": 1],
                useDefaultTierForNull: true
            ),
            .dropBeforeByPeriod(period: "P1Y"),
        ])
        #expect(rules["com.gone"] == [])
    }

    @Test("Encoding rules omits unset optional fields")
    func encodingRules() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let encoded = try String(
            data: encoder.encode([
                RetentionRule.loadByPeriod(period: "P3M"),
                .dropByPeriod(period: "P1M", includeFuture: false),
                .dropBeforeByPeriod(period: "P3M"),
                .dropForever,
            ]),
            encoding: .utf8
        )

        #expect(encoded == """
        [{"period":"P3M","type":"loadByPeriod"},{"includeFuture":false,"period":"P1M","type":"dropByPeriod"},\
        {"period":"P3M","type":"dropBeforeByPeriod"},{"type":"dropForever"}]
        """)
    }

    @Test("Interval rules round-trip")
    func intervalRulesRoundTrip() throws {
        let json = """
        [{"type":"dropByInterval","interval":"2024-01-01T00:00:00.000Z/2025-01-01T00:00:00.000Z"},\
        {"type":"loadByInterval","interval":"2025-01-01T00:00:00.000Z/2026-01-01T00:00:00.000Z","tieredReplicants":{"_default_tier":1}}]
        """

        let rules = try JSONDecoder().decode([RetentionRule].self, from: json.data(using: .utf8)!)
        let start2024 = Date(timeIntervalSince1970: 1_704_067_200)
        let start2025 = Date(timeIntervalSince1970: 1_735_689_600)
        let start2026 = Date(timeIntervalSince1970: 1_767_225_600)

        #expect(rules == [
            .dropByInterval(interval: .init(beginningDate: start2024, endDate: start2025)),
            .loadByInterval(interval: .init(beginningDate: start2025, endDate: start2026), tieredReplicants: ["_default_tier": 1]),
        ])

        let reencoded = try JSONDecoder().decode([RetentionRule].self, from: JSONEncoder().encode(rules))
        #expect(reencoded == rules)
    }

    @Test("Decoding an unknown rule type fails")
    func decodingUnknownRuleType() {
        let json = #"{"type":"broadcastForever"}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RetentionRule.self, from: json.data(using: .utf8)!)
        }
    }
}
