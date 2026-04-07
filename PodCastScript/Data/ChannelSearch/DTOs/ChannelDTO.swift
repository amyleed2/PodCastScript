import Foundation

struct ChannelDTO: Decodable {
    let id: String
    let titleOriginal: String
    // Listen Notes returns null or omits these fields for some podcasts.
    let publisherOriginal: String?
    let image: String?
    let thumbnail: String?
    let descriptionOriginal: String?

    enum CodingKeys: String, CodingKey {
        case id
        case titleOriginal = "title_original"
        case publisherOriginal = "publisher_original"
        case image
        case thumbnail
        case descriptionOriginal = "description_original"
    }
}
