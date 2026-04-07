import Foundation
import Moya

/// Injects a fixed API key into every request as a custom header field.
/// Use this instead of AccessTokenPlugin when the header name is not "Authorization".
struct APIKeyPlugin: PluginType {
    let headerField: String
    let key: String

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.setValue(key, forHTTPHeaderField: headerField)
        return request
    }
}
