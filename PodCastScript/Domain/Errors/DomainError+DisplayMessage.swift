import Foundation

extension DomainError {
    /// A user-facing message suitable for display in UI error states.
    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .serverError:
            return "The server is having trouble. Please try again later."
        case .unauthorized:
            return "Access denied. Please check your API credentials."
        case .decodingFailed:
            return "Received an unexpected response from the server."
        case .notFound:
            return "The requested content could not be found."
        case .persistenceFailed:
            return "Failed to save data locally. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment before searching again."
        case .transcriptionFailed(let underlying):
            #if DEBUG
            if let err = underlying {
                return "Transcription failed: \(err.localizedDescription)"
            }
            return "Transcription failed: provider returned no content."
            #else
            return "Could not generate a transcript for this episode. Please try again."
            #endif
        case .transcriptionTimeout:
            return "Transcript generation timed out. The episode may be too long or the service is busy. Please try again later."
        case .unknown(let underlying):
            #if DEBUG
            return "Unexpected error: \(underlying.localizedDescription)"
            #else
            return "Something went wrong. Please try again."
            #endif
        }
    }
}
