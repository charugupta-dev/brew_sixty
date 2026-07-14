import SwiftUI
import SwiftData

@MainActor
struct MethodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrewTemplate.createdAt, order: .reverse) private var templates: [BrewTemplate]

    @Binding var selectedTab: ContentView.Tab
    let brewSessionStore: BrewSessionStore

    @State private var editorMode: RecipeEditorView.Mode?
    @State private var deletionErrorMessage: String?
    @State private var hasAppliedReadmeCaptureState = false
    @AppStorage(Phase1IntentActionStore.key) private var pendingActionData: Data?
    @State private var methodFilter: BrewMethod? = nil

    private var filteredTemplates: [BrewTemplate] {
        templates.filter { template in
            guard let filter = methodFilter else { return true }
            return template.method == filter
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VideoWallpaperBackground(style: .quiet)

                VStack(spacing: 0) {
                    if let filter = methodFilter {
                        HStack(spacing: 8) {
                            Text("Filter: \(filter.rawValue)")
                                .font(.system(.footnote, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primaryCopper)
                            
                            Button {
                                methodFilter = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(.footnote, weight: .bold))
                                    .foregroundStyle(Color.primaryCopper.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.primaryCopper.opacity(0.12))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.primaryCopper.opacity(0.24), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if templates.isEmpty {
                        emptyState
                    } else if filteredTemplates.isEmpty {
                        filteredEmptyState
                    } else {
                        List {
                            ForEach(filteredTemplates) { template in
                                RecipeTemplateCard(
                                    template: template,
                                    onBrew: { startTemplate(template) },
                                    onEdit: { editorMode = .edit(template) }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTemplate(template)
                                    } label: {
                                        Label(AppConstants.Methods.Text.delete, systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }

                floatingAddButton
            }
            .navigationTitle(AppConstants.Methods.Text.recipesNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editorMode) { mode in
                NavigationStack {
                    RecipeEditorView(mode: mode, selectedTab: $selectedTab, brewSessionStore: brewSessionStore)
                }
            }
            .alert(AppConstants.Methods.Text.errorTitle, isPresented: deletionErrorBinding) {
                Button(AppConstants.Methods.Text.done, role: .cancel) {
                    deletionErrorMessage = nil
                }
            } message: {
                Text(deletionErrorMessage ?? AppConstants.Methods.Text.deleteFailedMessage)
            }
            .onAppear {
                applyReadmeCaptureStateIfNeeded()
                applyPendingCreateStateIfNeeded()
                applyPendingIntentActionIfNeeded()
            }
            .onChange(of: selectedTab) { _, tab in
                guard tab == .recipes else { return }
                applyPendingCreateStateIfNeeded()
                applyPendingIntentActionIfNeeded()
            }
            .onChange(of: pendingActionData) { _, _ in
                guard selectedTab == .recipes else { return }
                applyPendingIntentActionIfNeeded()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ContentUnavailableView {
                Label(AppConstants.Methods.Text.noSavedRecipes, systemImage: "square.stack.3d.up.slash.fill")
            } description: {
                Text(AppConstants.Methods.Text.emptyRecipesDescription)
            }
            .foregroundStyle(Color.coffeeCream)
        }
        .padding(.horizontal, 24)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 18) {
            ContentUnavailableView {
                Label("No recipes for this brewer", systemImage: "magnifyingglass")
            } description: {
                Text("Try adjusting the filter or add a new recipe.")
            }
            .foregroundStyle(Color.coffeeCream)
        }
        .padding(.horizontal, 24)
    }

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionErrorMessage != nil },
            set: { if !$0 { deletionErrorMessage = nil } }
        )
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    editorMode = .create
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.deepRoastInk)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.primaryCopper, Color.brushedCopper],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
                }
                .accessibilityLabel(AppConstants.Methods.Text.newRecipe)
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func startTemplate(_ template: BrewTemplate) {
        brewSessionStore.startSavedTemplate(template)
        selectedTab = .brew
    }

    private func deleteTemplate(_ template: BrewTemplate) {
        modelContext.delete(template)

        do {
            try modelContext.save()
            brewSessionStore.discardPersistentBrew(for: template.id)
        } catch {
            deletionErrorMessage = AppConstants.Methods.Text.deleteFailedMessage
        }
    }

    private func applyReadmeCaptureStateIfNeeded() {
        guard ReadmeCaptureConfiguration.shouldPresentRecipeEditor,
              !hasAppliedReadmeCaptureState else {
            return
        }

        hasAppliedReadmeCaptureState = true

        DispatchQueue.main.async {
            editorMode = .create
        }
    }

    private func applyPendingCreateStateIfNeeded() {
        guard let request = brewSessionStore.consumeRecipeComposerRequest() else { return }
        editorMode = request.draft.map { .createDraft($0) } ?? .create
    }

    private func applyPendingIntentActionIfNeeded() {
        guard selectedTab == .recipes, let data = pendingActionData else { return }
        guard let action = try? JSONDecoder().decode(Phase1IntentAction.self, from: data) else {
            pendingActionData = nil // Clear corrupt action
            return
        }
        guard action.destination == .recipes else { return }
        if case .adjustRecipe = action {
            return // Handled globally by ContentView, do not consume here
        }

        pendingActionData = nil // Consume action

        switch action {
        case .openRecipeComposer(let draft, let bannerTitle, let bannerSubtitle):
            editorMode = .createDraft(draft)
            brewSessionStore.presentIntentHandoff(title: bannerTitle, subtitle: bannerSubtitle)
        case .openRecipes(let filter, let bannerTitle, let bannerSubtitle):
            self.methodFilter = filter
            brewSessionStore.presentIntentHandoff(title: bannerTitle, subtitle: bannerSubtitle)
        case .adjustRecipe, .prepareSavedTemplate, .prepareTransientBrew:
            break
        }
    }
}

private struct RecipeTemplateCard: View {
    let template: BrewTemplate
    let onBrew: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.coffeeCream)

                    Text(template.method.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.deepRoastInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryCopper)
                        )
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Label("\(Int(template.beanWeight.rounded()))\(AppConstants.Text.gramsUnit)", systemImage: "scalemass.fill")

                if template.method == .v60 || template.method == .chemex {
                    Label("1:\(Int(template.ratio.rounded()))", systemImage: "drop.fill")
                } else {
                    Label("\(Int(template.waterVolume))\(AppConstants.Text.gramsUnit)", systemImage: "drop.fill")
                }

                Label("\(Int(template.targetTemperature.rounded()))\(AppConstants.Text.celsiusUnit)", systemImage: "thermometer.medium")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.64))

            HStack(spacing: 12) {
                Button(action: onBrew) {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text(AppConstants.Methods.Text.brew)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .foregroundStyle(Color.deepRoastInk)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                }
                .buttonStyle(.borderless)

                Button(action: onEdit) {
                    HStack {
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                        Text(AppConstants.Methods.Text.edit)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(Color.coffeeCream)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
                    )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                .fill(Color.appPanel.opacity(AppConstants.UI.cardOpacity))
        )
        .liquidGlassBorder(cornerRadius: AppConstants.UI.cardCornerRadius)
    }
}
