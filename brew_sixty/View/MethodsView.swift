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

    var body: some View {
        NavigationStack {
            ZStack {
                VideoWallpaperBackground(style: .quiet)

                if templates.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(templates) { template in
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
            .navigationTitle(AppConstants.Methods.Text.recipesNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorMode = .create
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                    }
                    .tint(Color.primaryCopper)
                    .accessibilityLabel(AppConstants.Methods.Text.newRecipe)
                }
            }
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

            Button {
                editorMode = .create
            } label: {
                Text(AppConstants.Methods.Text.createFirstRecipe)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.deepRoastInk)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(28)
            }
        }
        .padding(.horizontal, 24)
    }

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionErrorMessage != nil },
            set: { if !$0 { deletionErrorMessage = nil } }
        )
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
                Label(String(format: "%.1f%@", template.beanWeight, AppConstants.Text.gramsUnit), systemImage: "scalemass.fill")

                if template.method == .v60 || template.method == .chemex {
                    Label(String(format: "1:%.1f", template.ratio), systemImage: "drop.fill")
                } else {
                    Label("\(Int(template.waterVolume))\(AppConstants.Text.gramsUnit)", systemImage: "drop.fill")
                }

                Label(String(format: "%.1f%@", template.targetTemperature, AppConstants.Text.celsiusUnit), systemImage: "thermometer.medium")
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
