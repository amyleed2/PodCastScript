import Foundation

/// Concrete `TranscriptionProvider` that submits an audio URL to AssemblyAI
/// and polls until the transcript is ready.
///
/// Polling strategy:
/// - Interval: 5 seconds
/// - Maximum attempts: 60 (5 minutes total)
/// - Cancellation: honours Swift structured concurrency — cancelling the parent
///   Task will stop polling immediately via `Task.checkCancellation()`.
final class AssemblyAITranscriptionProvider: TranscriptionProvider {

    // MARK: - Constants

    private enum API {
        static let baseURL = URL(string: "https://api.assemblyai.com/v2")!
        static let pollInterval: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds
        static let maxPollAttempts = 60
    }

    // MARK: - Dependencies

    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - TranscriptionProvider

    func generateTranscript(from audioURL: URL) async throws -> String {
        #if DEBUG
        print("[AssemblyAI] Starting transcript generation")
        print("[AssemblyAI] Audio URL: \(audioURL.absoluteString)")
        #endif
        let jobID = try await submitJob(audioURL: audioURL)
        return try await pollUntilDone(jobID: jobID)
    }

    // MARK: - Submit

    private func submitJob(audioURL: URL) async throws -> String {
        let endpoint = API.baseURL.appendingPathComponent("transcript")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["audio_url": audioURL.absoluteString,
                                                                       "speech_models": ["universal-2"]])

        #if DEBUG
        print("[AssemblyAI] Submit → POST \(endpoint.absoluteString)")
        #endif

        let (data, response) = try await session.data(for: request)

        #if DEBUG
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
        print("[AssemblyAI] Submit ← HTTP \(statusCode)")
        print("[AssemblyAI] Submit ← Body: \(rawBody)")
        #endif

        try validate(response: response, data: data, context: "submit")

        let dto = try decode(AssemblyAISubmitResponseDTO.self, from: data, context: "submit")

        #if DEBUG
        print("[AssemblyAI] Job created — id: \(dto.id), initial status: \(dto.status)")
        #endif

        return dto.id
    }

    // MARK: - Poll

    private func pollUntilDone(jobID: String) async throws -> String {
        let endpoint = API.baseURL.appendingPathComponent("transcript/\(jobID)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        for attempt in 1...API.maxPollAttempts {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: API.pollInterval)

            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data, context: "poll attempt \(attempt)")

            let dto = try decode(AssemblyAIStatusResponseDTO.self, from: data, context: "poll attempt \(attempt)")

            #if DEBUG
            print("[AssemblyAI] Poll #\(attempt) — id: \(dto.id), status: \(dto.status)", terminator: "")
            if let errorMsg = dto.error { print(", error: \(errorMsg)", terminator: "") }
            print(", text present: \(dto.text != nil)")
            #endif

            switch dto.status {
            case "completed":
                guard let text = dto.text, !text.isEmpty else {
                    #if DEBUG
                    print("[AssemblyAI] Job completed but text is nil or empty — treating as failure")
                    #endif
                    throw DomainError.transcriptionFailed(underlying: nil)
                }
                #if DEBUG
                print("[AssemblyAI] Transcript ready — \(text.count) characters")
                #endif
                return text

            case "error":
                let message = dto.error ?? "AssemblyAI reported an error with no details."
                #if DEBUG
                print("[AssemblyAI] Job failed — \(message)")
                #endif
                throw DomainError.transcriptionFailed(
                    underlying: AssemblyAIError.jobFailed(message)
                )

            default:
                // "queued" or "processing" — continue polling
                continue
            }
        }

        #if DEBUG
        print("[AssemblyAI] Polling timed out after \(API.maxPollAttempts) attempts")
        #endif
        throw DomainError.transcriptionTimeout
    }

    // MARK: - Helpers

    private func validate(response: URLResponse, data: Data, context: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DomainError.transcriptionFailed(underlying: AssemblyAIError.invalidResponse(context))
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            // Capture the response body so callers can inspect the server's error message.
            let body = String(data: data, encoding: .utf8)
            throw DomainError.transcriptionFailed(
                underlying: AssemblyAIError.httpError(
                    statusCode: httpResponse.statusCode,
                    context: context,
                    body: body
                )
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, context: String) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            #if DEBUG
            let raw = String(data: data, encoding: .utf8) ?? "<non-UTF8>"
            print("[AssemblyAI] Decoding failed during \(context). Raw body: \(raw)")
            #endif
            throw DomainError.transcriptionFailed(
                underlying: AssemblyAIError.decodingFailed(context: context, underlying: error)
            )
        }
    }
}

// MARK: - Provider-local errors

/// Internal errors produced by `AssemblyAITranscriptionProvider`.
/// These are always wrapped in `DomainError.transcriptionFailed` before crossing
/// the Data→Domain boundary.
private enum AssemblyAIError: LocalizedError {
    case invalidResponse(String)
    /// HTTP non-2xx. `body` carries the raw response text for diagnostics.
    case httpError(statusCode: Int, context: String, body: String?)
    case decodingFailed(context: String, underlying: Error)
    case jobFailed(String)
    case timeout(attempts: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let ctx):
            return "Invalid response during \(ctx)."
        case .httpError(let code, let ctx, let body):
            var message = "HTTP \(code) during \(ctx)."
            if let body, !body.isEmpty { message += " Response: \(body)" }
            return message
        case .decodingFailed(let ctx, let err):
            return "Decoding failed during \(ctx): \(err.localizedDescription)"
        case .jobFailed(let msg):
            return "AssemblyAI job failed: \(msg)"
        case .timeout(let attempts):
            return "Transcript generation timed out after \(attempts) polling attempts."
        }
    }
}
