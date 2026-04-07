import Moya

/// Builds the common Moya plugin stack shared across all Listen Notes API providers.
///
/// Adding a new repository for Episodes or Transcripts?
/// Call `NetworkPluginFactory.plugins(apiKey:)` in its init — logging and auth
/// are automatically included without any per-repository configuration.
enum NetworkPluginFactory {
    static func plugins(apiKey: String) -> [PluginType] {
        var plugins: [PluginType] = [
            APIKeyPlugin(headerField: "X-ListenAPI-Key", key: apiKey)
        ]
        #if DEBUG
        let loggerConfig = NetworkLoggerPlugin.Configuration(logOptions: .verbose)
        plugins.append(NetworkLoggerPlugin(configuration: loggerConfig))
        #endif
        return plugins
    }
}
