import SwiftData
import Foundation

/// SwiftData-backed implementation of `FavoritesRepository`.
///
/// All operations run synchronously on the `ModelContext` provided at init.
/// Because SwiftData's `mainContext` is bound to the main actor, this class
/// is `@MainActor`. The `async throws` protocol signatures are satisfied by
/// Swift's ability to implement async requirements with synchronous bodies.
@MainActor
final class FavoritesRepositoryImpl: FavoritesRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Episodes

    func saveEpisode(_ episode: Episode) throws {
        if let existing = try fetchEpisodeModel(id: episode.id) {
            // Upsert: refresh the snapshot with current data.
            existing.title = episode.title
            existing.episodeDescription = episode.description
            existing.audioURLString = episode.audioURL?.absoluteString
            existing.publishedAt = episode.publishedAt
            existing.savedAt = .now
        } else {
            context.insert(FavoriteEpisode(from: episode))
        }
        try context.save()
    }

    func removeEpisode(id: String) throws {
        guard let model = try fetchEpisodeModel(id: id) else { return }
        context.delete(model)
        try context.save()
    }

    func fetchEpisodes() throws -> [Episode] {
        var descriptor = FetchDescriptor<FavoriteEpisode>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func isFavoriteEpisode(id: String) throws -> Bool {
        return try fetchEpisodeModel(id: id) != nil
    }

    // MARK: - Channels

    func saveChannel(_ channel: Channel) throws {
        if let existing = try fetchChannelModel(id: channel.id) {
            existing.name = channel.name
            existing.publisher = channel.publisher
            existing.artworkURLString = channel.artworkURL?.absoluteString
            existing.channelDescription = channel.description
            existing.savedAt = .now
        } else {
            context.insert(FavoriteChannel(from: channel))
        }
        try context.save()
    }

    func removeChannel(id: String) throws {
        guard let model = try fetchChannelModel(id: id) else { return }
        context.delete(model)
        try context.save()
    }

    func fetchChannels() throws -> [Channel] {
        var descriptor = FetchDescriptor<FavoriteChannel>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func isFavoriteChannel(id: String) throws -> Bool {
        return try fetchChannelModel(id: id) != nil
    }

    // MARK: - Private helpers

    private func fetchEpisodeModel(id: String) throws -> FavoriteEpisode? {
        let predicate = #Predicate<FavoriteEpisode> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchChannelModel(id: String) throws -> FavoriteChannel? {
        let predicate = #Predicate<FavoriteChannel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
