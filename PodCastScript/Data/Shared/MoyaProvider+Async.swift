import Moya

extension MoyaProvider {
    /// Wraps Moya's callback-based request in Swift Concurrency.
    /// The Cancellable token is retained inside the closure until the continuation resumes,
    /// preventing silent request cancellation under memory pressure.
    func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: Cancellable?
            cancellable = self.request(target) { result in
                _ = cancellable // retain until completion
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
