# Podcast Transcript App

## Project Goal
Build a SwiftUI-based Apple platform application that allows users to:
- search podcast channels
- browse episodes in a selected channel
- open a transcript detail screen for a selected episode
- save favorite channels and episodes
- copy, share, or export transcript text

This app must prioritize transcript access as its core value.

If a transcript is not directly available from an API, the app should support generating a transcript from episode audio through a transcription pipeline.

## Platforms
- Primary target: iOS
- Optional expansion: macOS
- Prefer shared SwiftUI code when reasonable
- Avoid platform-specific branching unless clearly needed

## Tech Stack
- SwiftUI
- Moya + Alamofire for metadata networking
- SwiftData for favorites persistence
- UserDefaults only for lightweight settings
- XCTest for unit tests

## Architecture
Use Clean Architecture with lightweight feature grouping.

Layers:
- Presentation
- Domain
- Data
- Shared

Rules:
- Presentation must not call Moya or Alamofire directly
- Domain must not import SwiftUI, Moya, Alamofire, or SwiftData
- Data implements repository protocols declared in Domain
- DTOs stay only in Data layer
- Domain entities must remain framework-agnostic
- Views should remain lightweight and declarative
- Business logic should not live inside SwiftUI Views

## Feature Breakdown
Main features:
- Channel Search
- Episode List
- Transcript Detail
- Favorites Library
- Transcript Copy / Share / Export

## UI State Modeling
Every async screen should explicitly model:
- idle
- loading
- loaded
- empty
- error

Transcript Detail should also support:
- noTranscriptAvailable
- partialTranscript
- exportInProgress
- exportFailed

Avoid using many loose booleans where one explicit state enum is clearer.

## Networking
- All HTTP requests for podcast metadata go through Moya targets
- Alamofire is used under Moya
- Map transport, decoding, and API errors into app-level domain errors
- Avoid leaking transport-layer concerns into Presentation
- Do not parse raw JSON in Views or ViewModels

## Persistence
- Favorites for channels and episodes should use SwiftData
- UserDefaults should store only lightweight preferences
  - recent search keyword
  - preferred sort option
  - transcript text appearance preferences if needed
- Do not store structured feature models in UserDefaults

## Transcript Strategy (IMPORTANT)
This app does NOT rely solely on API-provided transcripts.

Transcript may come from:
1. API transcript, if available
2. Generated transcript from episode audio, if API transcript is unavailable

Priority:
- Use API transcript if it is available and valid
- Otherwise generate transcript from audio through a transcription pipeline

Important:
- Transcript availability is not guaranteed by metadata APIs
- The app must be designed so transcript generation can be added or improved without breaking Presentation or Domain boundaries
- Transcript generation is part of the core product value, not an optional enhancement

## Transcription Pipeline
Transcript generation flow:

Episode
→ audio URL
→ transcription service or transcription provider
→ transcript text
→ TranscriptResult

Rules:
- Transcript is NOT guaranteed from API
- Transcript generation may be async and time-consuming
- Failures must be handled explicitly
- Transcription logic must not live in View
- UseCase layer should orchestrate transcript retrieval and generation
- Repository layer may combine multiple transcript sources

## Domain Model Rules
TranscriptResult should contain:
- episodeID
- content
- status

Transcript content should never be exposed to Presentation as invalid raw provider output if it can be normalized earlier.

TranscriptStatus may include:
- available
- partial
- unavailable
- unknown
- generated

Meaning:
- available: transcript exists from API or another trusted source
- partial: transcript exists but is incomplete
- unavailable: transcript is explicitly not available
- unknown: transcript presence cannot be determined
- generated: transcript was created from audio through transcription pipeline

## Transcript Retrieval Rules
- TranscriptRepository may combine:
  - API transcript
  - generated transcript
- FetchTranscriptUseCase may:
  1. request transcript from API-backed repository
  2. if unavailable or unknown, attempt generation from audio
  3. return normalized TranscriptResult

Do not hard-code the assumption that transcript always comes from a remote metadata API.

## Testing
- New use cases require unit tests
- New stateful presentation logic requires tests
- Repository implementations should be testable with stubs or mocks
- Important empty/error/loading states must be covered
- Transcription pipeline behavior should be testable with mock providers
- Avoid fragile tests coupled to UI layout details unless truly needed

## Naming
- Favor explicit names over short clever names
- Suffix DTO types with DTO
- Prefer feature-based naming in Presentation
- Prefer provider-specific names only in Data layer
- Keep Domain names provider-agnostic

## Working Style for Claude
- For non-trivial changes, propose a short plan first
- Keep changes small and reviewable
- Preserve current folder and naming conventions
- Suggest validation steps after code changes
- Prefer minimal necessary abstraction
- Do not introduce generic abstractions without a confirmed second use case
- When transcript logic is involved, clearly separate:
  - metadata fetch
  - transcript fetch
  - transcript generation
  - export or share actions

## Git Workflow
- Work feature by feature
- Keep commits small and focused
- Before large refactors, provide a plan first
- Do not rename many files unless necessary

## Current MVP Scope
MVP includes:
- channel search
- episode list
- transcript detail
- favorites save/remove
- transcript copy/share/export
- transcript generation fallback strategy at architecture level

MVP may start with a mock or simplified transcription provider if real transcription integration is not yet implemented.

Out of scope unless explicitly requested:
- login
- cloud sync
- full offline caching of generated transcript history
- analytics platform integration
- complex modular tooling
- advanced background transcription orchestration

## Do Not
- Put networking logic in SwiftUI Views
- Put persistence framework models in Domain
- Put transcription orchestration in Views
- Use singleton-heavy design for core app logic
- Over-engineer the navigation layer
- Add third-party dependencies without explaining why
- Change architecture style without explaining the tradeoff
- Assume transcript is always returned by the metadata API

## Preferred Output Style
When implementing features, provide:
1. short plan
2. files to create or edit
3. implementation
4. validation checklist
