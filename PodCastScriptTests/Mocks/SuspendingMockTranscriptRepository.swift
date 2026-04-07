import Foundation
@testable import PodCastScript

/// A `TranscriptRepository` that suspends indefinitely until `resume(with:)` is called.
///
/// Use this mock when you need to capture the ViewModel's intermediate state
/// (e.g. `.generating`) while the repository call is still in-flight.
///
/// Usage:
/// ```swift
/// let mock = SuspendingMockTranscriptRepository()
/// let task = Task { await sut.loadTranscript() }
/// await Task.yield()  // let loadTranscript() reach the suspension point
/// // assert intermediate state here
/// mock.resume(with: .success(someResult))
/// await task.value
/// ```
final class SuspendingMockTranscriptRepository: TranscriptRepository {
    private var continuation: CheckedContinuation<TranscriptResult, Error>?

    func fetchTranscript(for episode: Episode) async throws -> TranscriptResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with result: Result<TranscriptResult, Error>) {
        switch result {
        case .success(let value):
            continuation?.resume(returning: value)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
}
