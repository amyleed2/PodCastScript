enum DomainError: Error, Equatable {

    /// Device has no network connection.
    case networkUnavailable

    /// Server returned a non-success response (5xx, unexpected 4xx).
    case serverError

    /// API key is missing, invalid, or expired (401/403).
    case unauthorized

    /// Response could not be decoded into expected types.
    case decodingFailed

    /// Requested resource does not exist (404).
    case notFound

    /// Local persistence operation failed.
    case persistenceFailed(underlying: Error)

    /// API rate limit exceeded — Listen Notes 429.
    case rateLimitExceeded

    /// Transcript generation from audio failed (provider error, empty result, etc.).
    case transcriptionFailed(underlying: Error?)

    /// Transcript generation exceeded the maximum polling wait time.
    case transcriptionTimeout

    /// An unexpected error with an underlying cause.
    case unknown(underlying: Error)

    // MARK: - Equatable

    static func == (lhs: DomainError, rhs: DomainError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.serverError, .serverError),
             (.unauthorized, .unauthorized),
             (.decodingFailed, .decodingFailed),
             (.notFound, .notFound),
             (.rateLimitExceeded, .rateLimitExceeded):
            return true
        case (.persistenceFailed, .persistenceFailed):
            // Underlying errors are not Equatable; compare by case only.
            return true
        case (.transcriptionFailed, .transcriptionFailed):
            return true
        case (.transcriptionTimeout, .transcriptionTimeout):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
