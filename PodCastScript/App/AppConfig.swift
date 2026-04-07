import Foundation

/// Reads compile-time build settings injected into Info.plist via Secrets.xcconfig.
/// This type belongs in the App layer and must not be imported by Domain or Data targets.
enum AppConfig {
    static var listenNotesAPIKey: String {
        guard
            let key = Bundle.main.infoDictionary?["LISTEN_NOTES_API_KEY"] as? String,
            !key.isEmpty,
            key != "$(LISTEN_NOTES_API_KEY)"
        else {
            fatalError(
                "LISTEN_NOTES_API_KEY is missing or not expanded. " +
                "Ensure Secrets.xcconfig is assigned to the active build configuration."
            )
        }
        return key
    }

    /// Returns the AssemblyAI API key if it has been configured in Secrets.xcconfig.
    ///
    /// When non-nil, `AppCompositionRoot` uses `AssemblyAITranscriptionProvider`.
    /// When nil (key not set or left blank), it falls back to `StubTranscriptionProvider`.
    static var assemblyAIAPIKey: String? {
        guard
            let key = Bundle.main.infoDictionary?["ASSEMBLYAI_API_KEY"] as? String,
            !key.isEmpty,
            key != "$(ASSEMBLYAI_API_KEY)"
        else { return nil }
        return key
    }
}
