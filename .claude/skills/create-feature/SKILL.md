---
name: create-feature
description: Create a new feature in the podcast transcript app using the project's Clean Architecture conventions.
---

Use this skill when creating a new feature such as:
- ChannelSearch
- EpisodeList
- TranscriptDetail
- FavoritesLibrary

Follow these steps:

---

## 1. Feature Summary

- Describe what the feature does in 2~4 bullet points
- Identify the main user interaction
- Identify whether the feature is async

---

## 2. Proposed Files

Only create the minimum required files.

Include:

### Presentation
- View (SwiftUI)
- ViewModel

### Domain
- UseCase
- Repository protocol (if needed)

### Data
- Repository implementation (if needed)
- DTO (if needed)

### Tests
- UseCase test (if applicable)
- ViewModel state test (if applicable)

---

## 3. State Modeling (IMPORTANT)

Always use a single enum for UI state instead of multiple booleans.

### Basic State Template

```swift
enum FeatureState: Equatable {
    case idle
    case loading
    case loaded([Item])
    case empty
    case error(String)
}
```

For transcript features, support:

```swift
enum TranscriptState: Equatable {
    case idle
    case loading
    case loaded(TranscriptViewData)
    case empty
    case error(String)
    case noTranscriptAvailable
    case partialTranscript(String)
}
```

## 4. ViewModel Template
Use a state-driven ObservableObject.


```swift
@MainActor
final class FeatureViewModel: ObservableObject {

    @Published private(set) var state: FeatureState = .idle

    private let useCase: FeatureUseCase

    init(useCase: FeatureUseCase) {
        self.useCase = useCase
    }

    func onAppear() async {
        await load()
    }

    func load() async {
        state = .loading

        do {
            let items = try await useCase.execute()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

Rules:
    •    Do NOT put business logic in View
    •    Do NOT mutate state outside ViewModel
    •    Keep state transitions explicit

## 5. SwiftUI View Template

Use state-driven rendering.

```swift
struct FeatureView: View {

    @StateObject private var viewModel: FeatureViewModel

    var body: some View {
        content
            .task {
                await viewModel.onAppear()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {

        case .idle, .loading:
            ProgressView()

        case .loaded(let items):
            List(items, id: \.id) { item in
                Text(item.title)
            }

        case .empty:
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass"
            )

        case .error(let message):
            VStack {
                Text("Something went wrong")
                Text(message)
            }
        }
    }
}
```

## 6. Navigation Rules
    •    Use NavigationStack
    •    Do NOT embed navigation logic deeply in child views
    •    Pass minimal data between screens (ID preferred over full model)
    
    


## 7. Architecture Rules
    •    View must NOT call network layer directly
    •    View must NOT access persistence layer
    •    Domain must NOT import SwiftUI, Moya, Alamofire, or SwiftData
    •    Data layer must implement Domain protocols
    •    DTO must stay inside Data layer
    
    

## 8. Error Handling
    •    Always map errors into user-friendly messages
    •    Do not expose raw networking errors to UI
    •    Distinguish between:
        •    network failure
        •    empty result
        •    unsupported transcript


## 9. Validation Checklist
Before finishing, verify:
    •    View has NO business logic
    •    ViewModel handles all state transitions
    •    Only ONE state enum is used
    •    Loading / Empty / Error states are handled
    •    Architecture boundaries are respected
    •    No unnecessary abstraction is introduced
    •    Naming is explicit and consistent
    
    
## 10. Output Format

Always respond in this format:
    1.    Feature summary
    2.    Proposed file structure
    3.    Implementation plan
    4.    Code
    5.    Validation checklist
