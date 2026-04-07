import Foundation
import Moya

final class ChannelRepositoryImpl: ChannelRepository {
    private let provider: MoyaProvider<ListenNotesTarget>

    /// Production init — common logging + API key are applied via NetworkPluginFactory.
    init(apiKey: String) {
        provider = MoyaProvider<ListenNotesTarget>(
            plugins: NetworkPluginFactory.plugins(apiKey: apiKey)
        )
    }

    /// Testability init — accepts a pre-configured provider (e.g. with StubbingBehavior).
    init(provider: MoyaProvider<ListenNotesTarget>) {
        self.provider = provider
    }

    func searchChannels(query: String) async throws -> [Channel] {
        do {
            let response = try await provider.request(.searchChannels(query: query))
            // Throws MoyaError.statusCode for any non-2xx response (401, 404, 429, 5xx…)
            // before attempting JSON decoding, ensuring errors map to the correct DomainError.
            let validated = try response.filterSuccessfulStatusCodes()
            let dto = try JSONDecoder().decode(ChannelSearchResponseDTO.self, from: validated.data)
            return dto.results.map(ChannelMapper.map)
        } catch let moyaError as MoyaError {
            throw MoyaErrorMapper.toDomainError(moyaError)
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[ChannelRepositoryImpl] ✗ DecodingError: \(decodingError)")
            #endif
            throw DomainError.decodingFailed
        } catch let domainError as DomainError {
            throw domainError
        } catch {
            throw DomainError.unknown(underlying: error)
        }
    }
}
