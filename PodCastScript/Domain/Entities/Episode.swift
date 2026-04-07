import Foundation

struct Episode: Equatable, Hashable, Identifiable {
    let id: String
    let channelID: String
    let title: String
    let description: String
    let audioURL: URL?
    let publishedAt: Date
}
