/// https://druid.apache.org/docs/latest/ingestion/kafka-ingestion/#consumer-properties
public struct KafkaIndexTaskConsumerProperties: Codable, Hashable, Equatable, Sendable {
    public init(bootstrapServers: String) {
        /// <BROKER_1>:<PORT_1>,<BROKER_2>:<PORT_2>,...
        self.bootstrapServers = bootstrapServers
    }

    public let bootstrapServers: String

    private enum CodingKeys: String, CodingKey {
        case bootstrapServers = "bootstrap.servers"
    }
}
