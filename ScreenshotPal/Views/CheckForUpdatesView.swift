import Sparkle
import SwiftUI

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    init(updater: SPUUpdater) {
        checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") {
            checkForUpdatesViewModel.updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    let updater: SPUUpdater
    private var observation: NSKeyValueObservation?

    init(updater: SPUUpdater) {
        self.updater = updater
        observation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            DispatchQueue.main.async {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }
}
