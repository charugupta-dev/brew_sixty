import Foundation
import Observation

@Observable
@MainActor
final class BrewSessionStore {
    @ObservationIgnored private var persistentBrews: [UUID: HomeBrewViewModel] = [:]
    @ObservationIgnored private var pendingPersistentRefreshes: Set<UUID> = []
    private(set) var transientBrews: [HomeBrewViewModel] = []
    var pendingFocusBrewID: UUID?

    func brewViewModels(for templates: [BrewTemplate]) -> [HomeBrewViewModel] {
        syncPersistentBrews(with: templates)
        let savedBrews = templates.compactMap { persistentBrews[$0.id] }
        return transientBrews + savedBrews
    }

    func startTransientBrew(from draft: RecipeDraft) {
        let viewModel = HomeBrewViewModel(draft: draft)
        configureTransientCallbacks(for: viewModel)
        transientBrews.insert(viewModel, at: 0)
        start(viewModel)
    }

    func startSavedTemplate(_ template: BrewTemplate) {
        let viewModel = persistentBrewViewModel(for: template)
        start(viewModel)
    }

    func discardPersistentBrew(for templateID: UUID) {
        persistentBrews[templateID] = nil
    }

    func refreshPersistentBrew(from template: BrewTemplate) {
        guard let existing = persistentBrews[template.id] else { return }

        if !existing.isRunning, existing.elapsed == 0 {
            persistentBrews[template.id] = HomeBrewViewModel(template: template)
            pendingPersistentRefreshes.remove(template.id)
        } else {
            pendingPersistentRefreshes.insert(template.id)
        }
    }

    func consumePendingFocusBrewID() -> UUID? {
        let pendingID = pendingFocusBrewID
        pendingFocusBrewID = nil
        return pendingID
    }

    private func syncPersistentBrews(with templates: [BrewTemplate]) {
        let templateIDs = Set(templates.map(\.id))
        persistentBrews = persistentBrews.filter { templateIDs.contains($0.key) }
        pendingPersistentRefreshes = pendingPersistentRefreshes.filter { templateIDs.contains($0) }

        for template in templates {
            if persistentBrews[template.id] == nil {
                persistentBrews[template.id] = HomeBrewViewModel(template: template)
                continue
            }

            guard pendingPersistentRefreshes.contains(template.id), let existing = persistentBrews[template.id] else {
                continue
            }

            if !existing.isRunning, existing.elapsed == 0 {
                persistentBrews[template.id] = HomeBrewViewModel(template: template)
                pendingPersistentRefreshes.remove(template.id)
            }
        }
    }

    private func persistentBrewViewModel(for template: BrewTemplate) -> HomeBrewViewModel {
        if let existing = persistentBrews[template.id] {
            return existing
        }

        let viewModel = HomeBrewViewModel(template: template)
        persistentBrews[template.id] = viewModel
        return viewModel
    }

    private func configureTransientCallbacks(for viewModel: HomeBrewViewModel) {
        let viewModelID = viewModel.id
        viewModel.onReset = { [weak self] in
            self?.removeTransientBrew(withID: viewModelID)
        }
    }

    private func start(_ viewModel: HomeBrewViewModel) {
        viewModel.resetTimer(notifyObservers: false)
        viewModel.toggleTimer()
        pendingFocusBrewID = viewModel.id
    }

    private func removeTransientBrew(withID viewModelID: UUID) {
        transientBrews.removeAll { $0.id == viewModelID }
        if pendingFocusBrewID == viewModelID {
            pendingFocusBrewID = nil
        }
    }
}
