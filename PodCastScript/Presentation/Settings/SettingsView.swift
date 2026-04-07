import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingClearConfirmation = false

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            transcriptCacheSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCacheInfo()
        }
        .confirmationDialog(
            "Clear Transcript Cache?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                Task { await viewModel.clearCache() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All locally cached transcripts will be deleted. They will be regenerated the next time you open each episode.")
        }
    }

    // MARK: - Sections

    private var transcriptCacheSection: some View {
        Section {
            cacheStatusRow
            clearCacheButton
        } header: {
            Text("Transcript Cache")
        } footer: {
            Text("Transcripts are cached locally for \(CachePolicy.ttlDays) days. Expired or manually cleared transcripts will be regenerated on next access.")
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private var cacheStatusRow: some View {
        switch viewModel.state {
        case .loading:
            HStack {
                Text("Cached Transcripts")
                Spacer()
                ProgressView()
                    .controlSize(.small)
            }
        case .loaded(let count):
            HStack {
                Text("Cached Transcripts")
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        case .error:
            HStack {
                Text("Cached Transcripts")
                Spacer()
                Text("Unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var clearCacheButton: some View {
        Button(role: .destructive) {
            showingClearConfirmation = true
        } label: {
            HStack {
                Text("Clear Transcript Cache")
                Spacer()
                if viewModel.isClearing {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .disabled(viewModel.isClearing || isCacheEmpty)
    }

    private var isCacheEmpty: Bool {
        if case .loaded(let count) = viewModel.state { return count == 0 }
        return true
    }
}
