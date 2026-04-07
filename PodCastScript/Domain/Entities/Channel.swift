import Foundation

struct Channel: Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let publisher: String
    let artworkURL: URL?
    let description: String
}
