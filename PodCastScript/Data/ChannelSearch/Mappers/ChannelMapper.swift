import Foundation

enum ChannelMapper {
    static func map(_ dto: ChannelDTO) -> Channel {
        // image takes precedence over thumbnail; both may be absent.
        let artworkURLString = dto.image ?? dto.thumbnail
        return Channel(
            id: dto.id,
            name: dto.titleOriginal,
            publisher: dto.publisherOriginal ?? "",
            artworkURL: artworkURLString.flatMap { URL(string: $0) },
            description: dto.descriptionOriginal ?? ""
        )
    }
}
