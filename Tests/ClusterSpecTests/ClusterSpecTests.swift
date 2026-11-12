import ClusterSpec
import Foundation
import Testing

private func decode(_ json: String) throws -> ClusterSpec {
    try JSONDecoder().decode(ClusterSpec.self, from: Data(json.utf8))
}

private func encode(_ spec: ClusterSpec) throws -> String {
    try #require(String(bytes: JSONEncoder().encode(spec), encoding: .utf8))
}

// JSON values without the differences of key sequence and white space.
private func value(_ json: String) throws -> NSObject {
    try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? NSObject)
}

// A valid spec with `fields` after the necessary fields.
private func spec(_ fields: String = "") -> String {
    """
    {
        "version": 1,
        "queries": [{ "name": "main", "language": "sql", "query": "SELECT 1" }],
        "gauge": "line"\(fields.isEmpty ? "" : ", " + fields)
    }
    """
}

// Each field of spec version 1, with the SQL query of the design example.
private let completeSpec = """
{
    "version": 1,
    "queries": [
        {
            "name": "main",
            "language": "sql",
            "query": "SELECT TIME_FLOOR(__time, 'P1D') AS \\"day\\", appVersion, COUNT(*) AS events FROM {{events}} GROUP BY 1, 2",
            "refreshSeconds": 600
        },
        { "name": "users", "language": "sql", "query": "SELECT 1" }
    ],
    "gauge": "bar",
    "encoding": {
        "source": "main",
        "x": "day",
        "y": ["events"],
        "top": 24,
        "fillZero": true,
        "stack": "percent",
        "breakdown": { "column": "appVersion", "top": "all", "other": "sum", "sort": "name" }
    },
    "columnSettings": {
        "events": { "format": "compact", "label": "Events", "share": true, "valueLabels": { "0": "none" } },
        "seconds": { "format": { "name": "duration", "unit": "seconds" } },
        "size": { "format": { "name": "bytes", "base": 1024 } },
        "revenue": { "format": { "name": "intl", "locale": "en-US", "options": { "style": "currency", "currency": "USD" } } },
        "day": { "format": "auto" }
    },
    "seriesDefaults": {
        "smooth": true,
        "step": "middle",
        "connectNulls": true,
        "showSymbol": false,
        "symbolSize": 4,
        "lineStyle": { "width": 3, "type": "dashed", "color": "#F78564" },
        "areaStyle": { "opacity": 0.5, "color": "rgb(0 0 0)" },
        "itemStyle": { "color": "rebeccapurple", "opacity": 1 },
        "barWidth": "60%",
        "yAxisIndex": 1,
        "label": { "show": true, "position": "top", "formatter": "{c} users" },
        "markLine": {
            "data": [{ "yAxis": 1000, "name": "Target" }, { "xAxis": "2026-11-01T00:00:00" }],
            "lineStyle": { "color": "red", "width": 1, "type": "dotted" },
            "label": { "show": false }
        },
        "markArea": {
            "data": [[{ "yAxis": 0 }, { "yAxis": 100, "name": "Good" }]],
            "itemStyle": { "color": "green", "opacity": 0.1 }
        }
    },
    "seriesByName": { "2.1": { "lineStyle": { "width": 4 } } },
    "extraSeries": [
        { "type": "line", "name": "Users", "datasetId": "users", "encode": { "x": "day", "y": 1 }, "smooth": true }
    ],
    "echarts": {
        "xAxis": [{ "show": false, "type": "time", "min": "2026-11-01T00:00:00", "axisLabel": { "formatter": "{value}" } }],
        "yAxis": [{ "name": "Count", "inverse": false, "max": 100 }, { "position": "left" }],
        "legend": { "show": true, "top": 10, "left": "center", "orient": "horizontal" },
        "grid": { "top": 20, "bottom": "10%", "left": 0, "right": 26 },
        "dataZoom": [{ "type": "slider", "show": true, "start": 0, "end": 50, "startValue": 1, "endValue": "2026-11-02T00:00:00" }]
    },
    "colorScheme": ["#F78564", "rgb(0 0 0)", "rebeccapurple"],
    "explanation": "**Events** for each day."
}
"""

struct ClusterSpecTests {
    @Test("A spec with each field survives the decoder and the encoder") func roundTrip() throws {
        let encoded = try encode(decode(completeSpec))

        #expect(try value(encoded) == value(completeSpec))
    }

    @Test("A spec with only the necessary fields decodes") func minimalSpec() throws {
        let decoded = try decode(spec())

        #expect(decoded.gauge == .line)
        #expect(decoded.encoding == nil)
        #expect(try value(encode(decoded)) == value(spec()))
    }

    @Test("A TQL query in a spec is a CustomQuery") func tqlQuery() throws {
        let json = """
        {
            "version": 1,
            "queries": [{ "name": "main", "language": "tql", "query": { "queryType": "timeseries", "granularity": "day" } }],
            "gauge": "table"
        }
        """
        let decoded = try decode(json)

        guard case let .tql(query) = decoded.queries[0].query else {
            Issue.record("The query is not a TQL query")
            return
        }
        #expect(query.queryType == .timeseries)
        #expect(try decode(encode(decoded)) == decoded)
    }

    @Test("null means that a field is not set, and the encoder writes no null") func nullIsNotSet() throws {
        let decoded = try decode(spec("""
        "encoding": { "x": null, "top": null, "breakdown": null }, "seriesDefaults": null, "colorScheme": null
        """))
        let encoded = try encode(decoded)

        #expect(decoded.encoding?.top == nil)
        #expect(decoded.seriesDefaults == nil)
        #expect(!encoded.contains("null"))
    }

    @Test("A limit is a number or the text all") func limits() throws {
        #expect(try decode(spec(#""encoding": { "top": "all" }"#)).encoding?.top == .all)
        #expect(try decode(spec(#""encoding": { "top": 5 }"#)).encoding?.top == .count(5))
    }

    @Test("The colour scheme is a name or a list of colours") func colorSchemes() throws {
        #expect(try decode(spec(#""colorScheme": "vibrant""#)).colorScheme == .named(.vibrant))
        #expect(try decode(spec(##""colorScheme": ["#fff", "red"]"##)).colorScheme == .colors(["#fff", "red"]))
    }

    @Test("A format is a name or an object with a name") func formats() throws {
        let decoded = try decode(spec("""
        "columnSettings": {
            "a": { "format": "percent" },
            "b": { "format": { "name": "compact" } },
            "c": { "format": { "name": "duration" } },
            "d": { "format": { "name": "bytes", "base": 1000 } },
            "e": { "format": { "name": "intl", "options": { "style": "percent" } } }
        }
        """))
        let settings = try #require(decoded.columnSettings)

        #expect(settings["a"]?.format == .percent)
        #expect(settings["b"]?.format == .compact)
        #expect(settings["c"]?.format == .duration(unit: nil))
        #expect(settings["d"]?.format == .bytes(base: .decimal))
        #expect(try decode(encode(decoded)) == decoded)
    }

    // The type is the allowlist. A key that the type does not have is not in the encoded spec.
    @Test("A key that the type does not have is not in the encoded spec", arguments: [
        #""pivot": true"#,
        #""echarts": { "series": [{ "type": "line" }] }"#,
        #""echarts": { "dataset": { "source": [] } }"#,
        #""echarts": { "options": [], "baseOption": {}, "media": [], "timeline": {} }"#,
        #""echarts": { "tooltip": { "formatter": "<img src=x onerror=alert(1)>" } }"#,
        #""echarts": { "tooltip": { "extraCssText": "x", "className": "x", "appendTo": "body" } }"#,
        #""echarts": { "graphic": { "elements": [{ "type": "image", "style": { "image": "https://example.com/x.png" } }] } }"#,
        #""echarts": { "title": { "text": "x", "link": "javascript:alert(1)", "sublink": "javascript:alert(1)" } }"#,
        #""echarts": { "toolbox": { "feature": { "dataView": { "lang": ["<b>x</b>"] } } } }"#,
        #""echarts": { "useUTC": false, "animation": true }"#,
        #""seriesDefaults": { "symbol": "image://https://example.com/x.png" }"#,
        #""seriesDefaults": { "stack": "total", "data": [1, 2], "tooltip": { "formatter": "<b>x</b>" } }"#,
        #""seriesDefaults": { "markLine": { "symbol": "image://https://example.com/x.png" } }"#,
        #""seriesDefaults": { "type": "scatter", "datasetId": "main" }"#,
        #""extraSeries": [{ "type": "line", "data": [1, 2], "renderItem": "x" }]"#,
        #""encoding": { "breakdown": { "column": "a", "percent": true, "fillZero": true } }"#,
    ])
    func unknownKeys(fields: String) throws {
        let allowed: Set = [
            "version", "queries", "name", "language", "query", "gauge", "encoding", "breakdown", "column",
            "echarts", "seriesDefaults", "markLine", "extraSeries", "type",
        ]
        let encoded = try encode(decode(spec(fields)))
        let keys = try allKeys(JSONSerialization.jsonObject(with: Data(encoded.utf8)))

        #expect(keys.subtracting(allowed).isEmpty)
        #expect(!encoded.contains("example.com"))
        #expect(!encoded.contains("alert"))
    }

    @Test("A dangerous or wrong value does not decode", arguments: [
        // A colour must be text. An object can load an image from a different host.
        #""seriesDefaults": { "itemStyle": { "color": { "image": "https://example.com/x.png" } } }"#,
        #""seriesDefaults": { "lineStyle": { "color": { "image": "https://example.com/x.png" } } }"#,
        #""seriesDefaults": { "areaStyle": { "color": { "svgElement": "<svg/>" } } }"#,
        #""seriesDefaults": { "markArea": { "itemStyle": { "color": { "image": "x" } } } }"#,
        #""seriesByName": { "a": { "itemStyle": { "color": ["red"] } } }"#,
        #""colorScheme": [{ "image": "https://example.com/x.png" }]"#,
        #""colorScheme": "rainbow""#,
        #""colorScheme": []"#,
        // A text template must be text.
        #""seriesDefaults": { "label": { "formatter": { "x": 1 } } }"#,
        #""echarts": { "xAxis": [{ "axisLabel": { "formatter": ["x"] } }] }"#,
        // Only one form for each eCharts component.
        #""echarts": { "xAxis": { "show": false } }"#,
        #""echarts": { "legend": [{ "show": true }] }"#,
        #""echarts": { "grid": [{ "top": 1 }] }"#,
        // Values that are not in an enum.
        #""echarts": { "yAxis": [{ "type": "radius" }] }"#,
        #""echarts": { "dataZoom": [{ "type": "select" }] }"#,
        #""extraSeries": [{ "type": "custom" }]"#,
        #""extraSeries": [{ "name": "no type" }]"#,
        #""seriesDefaults": { "step": true }"#,
        #""seriesDefaults": { "smooth": 0.5 }"#,
        #""seriesDefaults": { "barWidth": true }"#,
        #""encoding": { "stack": "expand" }"#,
        #""encoding": { "top": 0 }"#,
        #""encoding": { "top": "many" }"#,
        #""encoding": { "breakdown": { "column": "a", "other": "hide" } }"#,
        #""encoding": { "breakdown": { "top": 3 } }"#,
        #""encoding": { "y": "events" }"#,
        #""columnSettings": { "a": { "format": "money" } }"#,
        #""columnSettings": { "a": { "format": { "locale": "en-US", "options": {} } } }"#,
        #""columnSettings": { "a": { "format": { "name": "duration", "unit": "days" } } }"#,
        #""columnSettings": { "a": { "format": { "name": "bytes", "base": 10 } } }"#,
        #""columnSettings": { "a": { "share": "count" } }"#,
        // Rules that need more than one field.
        #""encoding": { "source": "missing" }"#,
        #""extraSeries": [{ "type": "line", "datasetId": "missing" }]"#,
        #""encoding": { "y": ["a", "b"], "breakdown": { "column": "c" } }"#,
    ])
    func rejectedValues(fields: String) {
        #expect(throws: DecodingError.self) { try decode(spec(fields)) }
    }

    @Test("A spec with a wrong necessary field does not decode", arguments: [
        #"{ "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 2, "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": "1", "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }], "gauge": "funnel" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }], "gauge": { "type": "line" } }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1" }] }"#,
        #"{ "version": 1, "queries": [], "gauge": "line" }"#,
        #"{ "version": 1, "queries": { "a": { "language": "sql", "query": "SELECT 1" } }, "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "language": "sql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "", "language": "sql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": "" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": { "queryType": "timeseries" } }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "tql", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "druid", "query": "SELECT 1" }], "gauge": "line" }"#,
        #"{ "version": 1, "queries": [{ "name": "a", "language": "sql", "query": "SELECT 1", "refreshSeconds": 5 }], "gauge": "line" }"#,
        """
        { "version": 1, "gauge": "line", "queries": [
            { "name": "a", "language": "sql", "query": "SELECT 1" }, { "name": "a", "language": "sql", "query": "SELECT 2" }
        ] }
        """,
    ])
    func rejectedSpecs(json: String) {
        #expect(throws: DecodingError.self) { try decode(json) }
    }
}

// The keys of each object in a JSON value, at each depth.
private func allKeys(_ value: Any) -> Set<String> {
    switch value {
    case let object as [String: Any]:
        object.reduce(into: Set(object.keys)) { $0.formUnion(allKeys($1.value)) }
    case let list as [Any]:
        list.reduce(into: []) { $0.formUnion(allKeys($1)) }
    default:
        []
    }
}
