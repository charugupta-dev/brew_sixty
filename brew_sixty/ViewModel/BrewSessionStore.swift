import Foundation
import Observation
import SwiftData

struct PendingRecipeComposerRequest {
    let draft: RecipeDraft?
}

struct IntentHandoffBanner: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
}

@Observable
@MainActor
final class BrewSessionStore {
    @ObservationIgnored private var persistentBrews: [UUID: HomeBrewViewModel] = [:]
    @ObservationIgnored private var pendingPersistentRefreshes: Set<UUID> = []
    @ObservationIgnored private var bannerDismissTask: Task<Void, Never>?
    private(set) var transientBrews: [HomeBrewViewModel] = []
    var pendingFocusBrewID: UUID?
    var pendingRecipeComposerRequest: PendingRecipeComposerRequest?
    var intentHandoffBanner: IntentHandoffBanner?
    var activeEditingDraft: RecipeDraft?
    var onInsertLog: ((Double, Double) -> Void)? = nil

    func addBrewLog(beanWeight: Double, ratio: Double, thought: String?, context: ModelContext) {
        let log = BrewLog(timestamp: Date(), beanWeightGram: beanWeight, ratio: ratio, thought: thought)
        context.insert(log)
        try? context.save()
    }

    func brewViewModels(for templates: [BrewTemplate]) -> [HomeBrewViewModel] {
        syncPersistentBrews(with: templates)
        let savedBrews = templates.compactMap { persistentBrews[$0.id] }
        return transientBrews + savedBrews
    }

    func startTransientBrew(from draft: RecipeDraft) {
        let viewModel = HomeBrewViewModel(draft: draft)
        configureCallbacks(for: viewModel)
        transientBrews.insert(viewModel, at: 0)
        start(viewModel)
    }

    func prepareTransientBrew(from draft: RecipeDraft) {
        let viewModel = HomeBrewViewModel(draft: draft)
        configureCallbacks(for: viewModel)
        transientBrews.insert(viewModel, at: 0)
        prepare(viewModel)
    }

    func startSavedTemplate(_ template: BrewTemplate) {
        let viewModel = persistentBrewViewModel(for: template)
        start(viewModel)
    }

    func prepareSavedTemplate(_ template: BrewTemplate) {
        let viewModel = persistentBrewViewModel(for: template)
        prepare(viewModel)
    }

    func discardPersistentBrew(for templateID: UUID) {
        persistentBrews[templateID] = nil
    }

    func refreshPersistentBrew(from template: BrewTemplate) {
        guard let existing = persistentBrews[template.id] else { return }

        if !existing.isRunning, !existing.isCountingDown, existing.elapsed == 0 {
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

    func requestRecipeComposer(with draft: RecipeDraft? = nil) {
        pendingRecipeComposerRequest = PendingRecipeComposerRequest(draft: draft)
    }

    func consumeRecipeComposerRequest() -> PendingRecipeComposerRequest? {
        let request = pendingRecipeComposerRequest
        pendingRecipeComposerRequest = nil
        return request
    }

    func presentIntentHandoff(title: String, subtitle: String? = nil) {
        bannerDismissTask?.cancel()
        intentHandoffBanner = IntentHandoffBanner(title: title, subtitle: subtitle)

        bannerDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.intentHandoffBanner = nil
            }
        }
    }

    private func syncPersistentBrews(with templates: [BrewTemplate]) {
        let templateIDs = Set(templates.map(\.id))
        persistentBrews = persistentBrews.filter { templateIDs.contains($0.key) }
        pendingPersistentRefreshes = pendingPersistentRefreshes.filter { templateIDs.contains($0) }

        for template in templates {
            if persistentBrews[template.id] == nil {
                let viewModel = HomeBrewViewModel(template: template)
                configureCallbacks(for: viewModel)
                persistentBrews[template.id] = viewModel
                continue
            }

            guard pendingPersistentRefreshes.contains(template.id), let existing = persistentBrews[template.id] else {
                continue
            }

            if !existing.isRunning, !existing.isCountingDown, existing.elapsed == 0 {
                let viewModel = HomeBrewViewModel(template: template)
                configureCallbacks(for: viewModel)
                persistentBrews[template.id] = viewModel
                pendingPersistentRefreshes.remove(template.id)
            }
        }
    }

    private func persistentBrewViewModel(for template: BrewTemplate) -> HomeBrewViewModel {
        if let existing = persistentBrews[template.id] {
            return existing
        }

        let viewModel = HomeBrewViewModel(template: template)
        configureCallbacks(for: viewModel)
        persistentBrews[template.id] = viewModel
        return viewModel
    }

    private func configureCallbacks(for viewModel: HomeBrewViewModel) {
        let viewModelID = viewModel.id
        viewModel.onReset = { [weak self] in
            self?.removeTransientBrew(withID: viewModelID)
        }
        viewModel.onBrewComplete = { [weak self] dose, ratio in
            self?.onInsertLog?(dose, ratio)
        }
    }

    private func start(_ viewModel: HomeBrewViewModel) {
        viewModel.resetTimer(notifyObservers: false)
        viewModel.toggleTimer()
        pendingFocusBrewID = viewModel.id
    }

    private func prepare(_ viewModel: HomeBrewViewModel) {
        viewModel.resetTimer(notifyObservers: false)
        pendingFocusBrewID = viewModel.id
    }

    private func removeTransientBrew(withID viewModelID: UUID) {
        transientBrews.removeAll { $0.id == viewModelID }
        if pendingFocusBrewID == viewModelID {
            pendingFocusBrewID = nil
        }
    }
}
