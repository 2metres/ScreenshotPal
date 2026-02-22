import Sparkle
import SwiftUI

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

private final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private var observation: NSKeyValueObservation?

    init(updater: SPUUpdater) {
        observation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            DispatchQueue.main.async {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }
}
