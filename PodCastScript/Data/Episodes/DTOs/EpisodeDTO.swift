import Foundation

struct EpisodeDTO: Decodable {
    let id: String
    let title: String?
    let description: String?
    /// Publication date in Unix milliseconds.
    let pubDateMs: Int?
    let audio: String?
    let maybeAudioInvalid: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case pubDateMs = "pub_date_ms"
        case audio
        case maybeAudioInvalid = "maybe_audio_invalid"
    }
}
