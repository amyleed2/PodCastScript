import Moya
import Foundation

enum MoyaErrorMapper {
    static func toDomainError(_ error: MoyaError) -> DomainError {
        switch error {
        case .underlying(let underlyingError, _):
            let nsError = underlyingError as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorDataNotAllowed:
                    return .networkUnavailable
                default:
                    break
                }
            }
            return .unknown(underlying: underlyingError)

        case .statusCode(let response):
            switch response.statusCode {
            case 401, 403: return .unauthorized
            case 404:      return .notFound
            case 429:      return .rateLimitExceeded
            case 500...:   return .serverError
            default:       return .unknown(underlying: error)
            }

        case .jsonMapping, .stringMapping, .objectMapping, .encodableMapping:
            return .decodingFailed

        default:
            return .unknown(underlying: error)
        }
    }
}
