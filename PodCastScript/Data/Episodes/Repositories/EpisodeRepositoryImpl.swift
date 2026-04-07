import Foundation
import Moya

final class EpisodeRepositoryImpl: EpisodeRepository {
    private let provider: MoyaProvider<ListenNotesTarget>

    init(apiKey: String) {
        provider = MoyaProvider<ListenNotesTarget>(
            plugins: NetworkPluginFactory.plugins(apiKey: apiKey)
        )
    }

    /// Testability init — accepts a pre-configured provider (e.g. with StubbingBehavior).
    init(provider: MoyaProvider<ListenNotesTarget>) {
        self.provider = provider
    }

    func fetchEpisodes(channelID: String, nextPublishDate: Int?) async throws -> EpisodePage {
        do {
            let response = try await provider.request(
                .fetchEpisodes(channelID: channelID, nextPublishDate: nextPublishDate)
            )
            let validated = try response.filterSuccessfulStatusCodes()
            let dto = try JSONDecoder().decode(EpisodeResponseDTO.self, from: validated.data)
            let episodes = dto.episodes.map { EpisodeMapper.map($0, channelID: channelID) }
            return EpisodePage(episodes: episodes, nextPublishDate: dto.nextEpisodePubDate)
        } catch let moyaError as MoyaError {
            throw MoyaErrorMapper.toDomainError(moyaError)
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[EpisodeRepositoryImpl] ✗ DecodingError: \(decodingError)")
            #endif
            throw DomainError.decodingFailed
        } catch let domainError as DomainError {
            throw domainError
        } catch {
            throw DomainError.unknown(underlying: error)
        }
    }
}
