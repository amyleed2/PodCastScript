import Foundation

/// Decoded from the POST /v2/transcript response.
/// Only the fields needed to start polling are included.
struct AssemblyAISubmitResponseDTO: Decodable {
    let id: String
    let status: String
}
