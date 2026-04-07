import Foundation
import Moya
import Alamofire

enum ListenNotesTarget {
    case searchChannels(query: String)
    case fetchEpisodes(channelID: String, nextPublishDate: Int?)
}

extension ListenNotesTarget: TargetType {
    var baseURL: URL {
        // Force-unwrap is acceptable for a static compile-time constant URL.
        URL(string: "https://listen-api.listennotes.com/api/v2")!
    }

    var path: String {
        switch self {
        case .searchChannels:
            return "/search"
        case .fetchEpisodes(let channelID, _):
            return "/podcasts/\(channelID)"
        }
    }

    var method: Moya.Method { .get }

    var task: Task {
        switch self {
        case .searchChannels(let query):
            return .requestParameters(
                parameters: ["q": query, "type": "podcast"],
                encoding: URLEncoding.queryString
            )
        case .fetchEpisodes(_, let nextPublishDate):
            var params: [String: Any] = [:]
            if let cursor = nextPublishDate {
                params["next_episode_pub_date"] = cursor
            }
            return params.isEmpty
                ? .requestPlain
                : .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }

    /// The API key header is injected by APIKeyPlugin at provider construction.
    /// This target does not reference AppConfig directly.
    var headers: [String: String]? { nil }
}
