---
name: generate-transcript
description: Generate transcript from podcast audio using a transcription pipeline, while preserving Clean Architecture boundaries.
---

Use this skill when:
- transcript is not available from API
- transcript availability is unknown
- audio URL is available
- transcript must be generated from audio
- designing transcript fallback flow

This skill is for transcript-generation-oriented work, not simple metadata fetch.

---

## 1. Goal

Generate or retrieve transcript text for a selected podcast episode.

Preferred source order:
1. API transcript if available and valid
2. Generated transcript from audio if API transcript is unavailable or insufficient

---

## 2. Required Inputs

Before implementation, identify:
- episodeID
- audio URL availability
- transcript source availability
- transcript provider or mock strategy
- expected output shape in Domain

---

## 3. Pipeline Flow

Use this conceptual flow:

Episode
→ metadata lookup
→ transcript source check
→ if transcript exists, normalize it
→ otherwise send audio to transcription pipeline
→ normalize transcript result
→ map to Domain TranscriptResult

---

## 4. Domain Mapping

The final result should map into Domain.

Example:

```swift
TranscriptResult(
    episodeID: episodeID,
    content: transcriptText,
    status: .generated
)

```

Possible status mapping:
    •    API transcript exists → .available
    •    API transcript exists but incomplete → .partial
    •    API says transcript unavailable → .unavailable
    •    API gives no usable signal → .unknown
    •    Audio-based transcript created → .generated


## 5. Architecture Rules

Always follow these rules:
    •    View must NOT perform transcription logic
    •    ViewModel must NOT directly call provider-specific services
    •    UseCase should orchestrate transcript retrieval and fallback generation
    •    Repository may abstract transcript source resolution
    •    Provider-specific request/response models stay in Data layer
    •    Domain must remain provider-agnostic
    •    Export/share logic is separate from transcript generation logic


## 6. MVP Strategy

For MVP:
    •    Start with the simplest viable transcript-generation flow
    •    It is acceptable to begin with a mock or stub transcription provider
    •    Do not block the whole app on full production-grade transcription infrastructure
    •    Preserve the interface so real provider integration can replace mock later

Recommended MVP progression:
    1.    mock provider
    2.    provider-backed generation
    3.    retry / timeout improvement
    4.    background processing refinement


## 7. Error Handling

Explicitly handle:
    •    missing audio URL
    •    transcription provider failure
    •    timeout
    •    empty transcript result
    •    invalid transcript payload
    •    rate limit
    •    unsupported audio source

Map these into app-level errors and state transitions.

Do NOT expose raw provider errors directly to the UI unless normalized.


## 8. State Mapping Guidance

Transcript generation should map cleanly into ViewModel state.

Example guidance:
    •    transcript available → loaded
    •    partial transcript → partialTranscript
    •    explicit unavailable → noTranscriptAvailable
    •    generated transcript success → loaded
    •    provider failure → error
    •    generation in progress → loading or dedicated generation substate
    •    export action state should remain independent from transcript retrieval state where appropriate


## 9. Suggested Components

When relevant, propose the minimum necessary components such as:
    •    TranscriptionProvider protocol
    •    MockTranscriptionProvider
    •    GeneratedTranscriptRepository or provider-backed repository helper
    •    FetchTranscriptUseCase update
    •    Transcript normalization mapper
    •    DomainError mapping for generation failure

Only create what is necessary for the current step.


## 10. Validation Checklist

Before finishing, verify:
    •    transcript source order is explicit
    •    Domain contracts remain provider-agnostic
    •    no provider logic leaks into Presentation
    •    fallback path is clearly defined
    •    error handling is explicit
    •    transcript content is normalized before reaching Presentation
    •    generated transcript path is testable


## 11. Output Format

Always respond in this format:
    1.    pipeline summary
    2.    required files or components
    3.    implementation plan
    4.    code
    5.    validation checklist
    
