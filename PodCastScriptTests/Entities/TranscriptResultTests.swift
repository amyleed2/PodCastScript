import Testing
@testable import PodCastScript

// MARK: - Feature under test
// TranscriptResult.source — verifies the source field correctly captures
// the origin of a transcript (generated vs cached vs nil when unavailable).
//
// Test case list:
//   1.  source is nil when status is .unavailable
//   2.  source is .generated when set to .generated
//   3.  source is .cached when set to .cached
//   4.  two results with identical source are Equatable (==)
//   5.  two results differing only in source are not equal (!=)
//
// Regression checklist:
//   [ ] TranscriptResult with .unavailable status never has a non-nil source
//   [ ] .generated and .cached produce distinct Equatable values
//   [ ] changing only source breaks equality (source is part of identity)

struct TranscriptResultTests {

    // MARK: - source field presence

    @Test("source is nil when status is unavailable")
    func source_unavailableStatus_isNil() {
        let result = TranscriptResult(
            episodeID: "ep-1",
            content: nil,
            status: .unavailable,
            source: nil
        )
        #expect(result.source == nil)
    }

    @Test("source is .generated when transcript was produced by the pipeline")
    func source_generatedPipeline_isGenerated() {
        let result = TranscriptResult(
            episodeID: "ep-1",
            content: "Transcript text.",
            status: .generated,
            source: .generated
        )
        #expect(result.source == .generated)
    }

    @Test("source is .cached when transcript was retrieved from local cache")
    func source_localCache_isCached() {
        let result = TranscriptResult(
            episodeID: "ep-1",
            content: "Transcript text.",
            status: .generated,
            source: .cached
        )
        #expect(result.source == .cached)
    }

    // MARK: - Equatable

    @Test("two results with the same source are equal")
    func equatable_sameSource_areEqual() {
        let a = TranscriptResult(episodeID: "ep-1", content: "text", status: .generated, source: .generated)
        let b = TranscriptResult(episodeID: "ep-1", content: "text", status: .generated, source: .generated)
        #expect(a == b)
    }

    @Test("two results differing only in source are not equal")
    func equatable_differentSource_areNotEqual() {
        let generated = TranscriptResult(episodeID: "ep-1", content: "text", status: .generated, source: .generated)
        let cached    = TranscriptResult(episodeID: "ep-1", content: "text", status: .generated, source: .cached)
        #expect(generated != cached)
    }
}
