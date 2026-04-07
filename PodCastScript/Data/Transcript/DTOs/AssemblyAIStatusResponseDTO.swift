import Foundation

/// Decoded from the GET /v2/transcript/{id} polling response.
///
/// - `status`: One of `"queued"`, `"processing"`, `"completed"`, `"error"`.
/// - `text`: Non-nil when `status == "completed"`.
/// - `error`: Non-nil when `status == "error"`. Contains a human-readable message.
struct AssemblyAIStatusResponseDTO: Decodable {
    let id: String
    let status: String
    let text: String?
    let error: String?
}
