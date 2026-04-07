import SwiftUI

struct TranscriptDetailView: View {
    @StateObject private var viewModel: TranscriptDetailViewModel

    /// Holds the exported file URL to present the share sheet.
    @State private var exportedFileURL: ExportedFile?

    init(viewModel: TranscriptDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await viewModel.loadFavoriteStatus() }
                    group.addTask { await viewModel.loadTranscript() }
                }
            }
            .toolbar { toolbarContent }
            .onChange(of: viewModel.exportState) { _, newState in
                if case .done(let url) = newState {
                    exportedFileURL = ExportedFile(url: url)
                }
            }
            .sheet(item: $exportedFileURL, onDismiss: { viewModel.resetExportState() }) { file in
                ShareSheet(activityItems: [file.url])
            }
            .alert("Export Failed", isPresented: exportFailedBinding) {
                Button("OK", role: .cancel) { viewModel.resetExportState() }
            } message: {
                if case .failed(let message) = viewModel.exportState {
                    Text(message)
                }
            }
    }

    // MARK: - State rendering

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .generating:
            generatingView
        case .loaded(let text, let source):
            transcriptBody(text: text, source: source)
        case .noTranscriptAvailable:
            ContentUnavailableView(
                "No Transcript",
                systemImage: "text.bubble",
                description: Text("A transcript is not available for this episode.")
            )
        case .error(let loadError):
            errorView(loadError)
        }
    }

    // MARK: - Generating view

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .padding(.bottom, 4)

            Text("Generating Transcript")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Transcribing episode audio via AssemblyAI.\nThis usually takes 1–3 minutes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.generatingElapsedSeconds > 0 {
                Text(elapsedLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var elapsedLabel: String {
        let s = viewModel.generatingElapsedSeconds
        if s < 60 {
            return "Elapsed: \(s)s"
        } else {
            return "Elapsed: \(s / 60)m \(s % 60)s"
        }
    }

    // MARK: - Error view

    private func errorView(_ loadError: TranscriptDetailViewModel.TranscriptLoadError) -> some View {
        VStack(spacing: 24) {
            ContentUnavailableView(
                errorTitle(loadError),
                systemImage: errorSystemImage(loadError),
                description: Text(errorDescription(loadError))
            )

            if loadError != .networkUnavailable {
                Button("Try Again") {
                    Task { await viewModel.retryTranscript() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Try Again") {
                    Task { await viewModel.retryTranscript() }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func errorTitle(
        _ loadError: TranscriptDetailViewModel.TranscriptLoadError
    ) -> String {
        switch loadError {
        case .networkUnavailable:  return "No Internet Connection"
        case .timeout:             return "Generation Timed Out"
        case .transcriptionFailed: return "Transcription Failed"
        case .unknown:             return "Something Went Wrong"
        }
    }

    private func errorSystemImage(
        _ loadError: TranscriptDetailViewModel.TranscriptLoadError
    ) -> String {
        switch loadError {
        case .networkUnavailable:  return "wifi.slash"
        case .timeout:             return "clock.badge.xmark"
        case .transcriptionFailed: return "waveform.slash"
        case .unknown:             return "exclamationmark.triangle"
        }
    }

    private func errorDescription(
        _ loadError: TranscriptDetailViewModel.TranscriptLoadError
    ) -> String {
        switch loadError {
        case .networkUnavailable:
            return "Please check your network connection and try again."
        case .timeout:
            return "The episode may be too long or the service is currently busy. Please try again later."
        case .transcriptionFailed(let message):
            return message
        case .unknown(let message):
            return message
        }
    }

    // MARK: - Transcript body

    private func transcriptBody(text: String, source: TranscriptSource) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if source == .cached {
                    cachedBadge
                }
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }

    private var cachedBadge: some View {
        Label("Cached", systemImage: "externaldrive.fill")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Episode favorite toggle
            Button {
                Task { await viewModel.toggleEpisodeFavorite() }
            } label: {
                Image(systemName: viewModel.isFavoriteEpisode ? "heart.fill" : "heart")
                    .foregroundStyle(viewModel.isFavoriteEpisode ? .red : .primary)
            }

            Button {
                copyToClipboard()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(!viewModel.actionsEnabled)

            if let text = viewModel.transcriptText {
                ShareLink(item: text) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(!viewModel.actionsEnabled)
            }

            Button {
                Task { await viewModel.exportTranscript() }
            } label: {
                if viewModel.exportState == .exporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.down.doc")
                }
            }
            .disabled(!viewModel.actionsEnabled || viewModel.exportState == .exporting)
        }
    }

    // MARK: - Actions

    private func copyToClipboard() {
        guard let text = viewModel.transcriptText else { return }
        UIPasteboard.general.string = text
    }

    private var exportFailedBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failed = viewModel.exportState { return true }
                return false
            },
            set: { _ in }
        )
    }
}

// MARK: - Helpers

/// Identifiable wrapper so sheet(item:) can present the exported file.
private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// UIKit share sheet bridge.
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
