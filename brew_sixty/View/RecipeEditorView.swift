import SwiftUI
import SwiftData

@MainActor
struct RecipeEditorView: View {
    enum Mode: Identifiable {
        case create
        case edit(BrewTemplate)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let template):
                return template.id.uuidString
            }
        }
    }

    private enum HelpTopic: String, Identifiable {
        case method
        case beanWeight
        case waterRatio
        case waterVolume
        case bloomDuration
        case steepDuration
        case pressDuration
        case temperature

        var id: String { rawValue }
    }

    private struct HelpContent {
        let title: String
        let summary: String
        let startingPoint: String
        let note: String
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedTab: ContentView.Tab
    let brewSessionStore: BrewSessionStore
    let mode: Mode

    @AppStorage(ProfilePreferences.Keys.experienceLevel) private var experienceLevelRaw = ProfileExperienceLevel.justStarting.rawValue
    @AppStorage(ProfilePreferences.Keys.methodsUsed) private var methodsUsedRaw = ""

    @State private var draft: RecipeDraft
    @State private var presentedHelpTopic: HelpTopic?
    @State private var activeHintTopic: HelpTopic?
    @State private var saveErrorMessage: String?
    @State private var hasAppliedProfileDefaults = false
    @State private var hintDismissTask: Task<Void, Never>?
    @State private var starterServingSize: FirstCupServingSize = .oneCup

    init(mode: Mode, selectedTab: Binding<ContentView.Tab>, brewSessionStore: BrewSessionStore) {
        self.mode = mode
        _selectedTab = selectedTab
        self.brewSessionStore = brewSessionStore

        switch mode {
        case .create:
            _draft = State(initialValue: RecipeDraft())
        case .edit(let template):
            _draft = State(initialValue: RecipeDraft(template: template))
        }
    }

    var body: some View {
        ZStack {
            VideoWallpaperBackground(style: .quiet)

            ScrollView {
                VStack(spacing: AppConstants.Methods.Layout.sectionSpacing) {
                    methodSelectionSection
                    doseAndYieldSection
                    timingAndTemperatureSection
                    recipeNameSection
                    actionButtons
                }
                .padding(.top, AppConstants.Methods.Layout.methodPickerTopPadding)
                .padding(.bottom, AppConstants.Methods.Layout.methodsBottomPadding)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppConstants.Methods.Text.cancel) {
                    dismiss()
                }
                .tint(Color.primaryCopper)
            }
        }
        .sheet(item: $presentedHelpTopic) { topic in
            let content = helpContent(for: topic)

            MethodsHelpSheet(
                title: content.title,
                summary: content.summary,
                startingPoint: content.startingPoint,
                note: content.note
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(AppConstants.Methods.Text.errorTitle, isPresented: saveErrorBinding) {
            Button(AppConstants.Methods.Text.done, role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? AppConstants.Methods.Text.saveFailedMessage)
        }
        .onAppear(perform: applyProfilePreferencesIfNeeded)
        .onDisappear {
            hintDismissTask?.cancel()
        }
    }

    private var methodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Brewer")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.coffeeCream)

                    Text("Start with the brewer you want to make right now.")
                        .font(.footnote)
                        .foregroundStyle(Color.coffeeCream.opacity(0.66))
                }

                Spacer()
                helpButton(for: .method)
            }

            LazyVGrid(columns: methodColumns, spacing: 10) {
                ForEach(orderedMethods, id: \.self) { method in
                    Button {
                        selectMethod(method)
                    } label: {
                        methodPill(for: method)
                    }
                    .buttonStyle(.plain)
                }
            }

            if shouldShowStarterProfiles {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("CUP SIZE")

                    HStack(spacing: AppConstants.Methods.Layout.compactRowSpacing) {
                        ForEach(FirstCupServingSize.allCases) { servingSize in
                            Button {
                                applyStarterServingSize(servingSize)
                            } label: {
                                starterServingSizePill(for: servingSize)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("TASTE STYLE")

                    HStack(spacing: AppConstants.Methods.Layout.compactRowSpacing) {
                        ForEach(FirstCupProfile.allCases) { profile in
                            Button {
                                applyStarterProfile(profile)
                            } label: {
                                starterProfilePill(for: profile)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    contextualHint(starterProfileSummaryText)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
        .liquidGlassBorder(cornerRadius: 16)
        .padding(.horizontal, 16)
    }

    private var doseAndYieldSection: some View {
        SectionCard(experienceLevel == .enthusiast ? "Dose & Yield" : "Coffee & Water") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    parameterLabel(labelText(for: .beanWeight), helpTopic: .beanWeight)
                    Spacer()
                    Text("\(Int(draft.beanWeight.rounded()))\(AppConstants.Text.gramsUnit)")
                        .font(.system(size: 19, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.primaryCopper)
                }

                SteppedWeightPicker(value: $draft.beanWeight, onInteraction: {
                    registerInteraction(.beanWeight)
                })

                if shouldShowContextualHint(for: .beanWeight) {
                    contextualHint(contextualHintText(for: .beanWeight))
                }
            }

            Divider().overlay(Color.white.opacity(AppConstants.UI.subtleBorderOpacity))

            if draft.isPourOverMethod {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        parameterLabel(labelText(for: .waterRatio), helpTopic: .waterRatio)
                        Spacer()
                        Text("1:\(Int(draft.ratio.rounded()))")
                            .font(.system(size: 19, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.primaryCopper)
                    }

                    PrecisionSlider(value: $draft.ratio, range: AppConstants.Methods.Ranges.waterRatio, step: AppConstants.Methods.Steps.waterRatio, onInteraction: {
                        registerInteraction(.waterRatio)
                    })

                    if shouldShowContextualHint(for: .waterRatio) {
                        contextualHint(contextualHintText(for: .waterRatio))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        parameterLabel(labelText(for: .waterVolume), helpTopic: .waterVolume)
                        Spacer()
                        Text("\(Int(draft.waterVolume))\(AppConstants.Text.gramsUnit)")
                            .font(.system(size: 19, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.primaryCopper)
                    }

                    PrecisionSlider(value: $draft.waterVolume, range: AppConstants.Methods.Ranges.waterVolume, step: AppConstants.Methods.Steps.waterVolume, onInteraction: {
                        registerInteraction(.waterVolume)
                    })

                    if shouldShowContextualHint(for: .waterVolume) {
                        contextualHint(contextualHintText(for: .waterVolume))
                    }
                }
            }
        }
    }

    private var timingAndTemperatureSection: some View {
        SectionCard("Time & Temperature") {
            if draft.isPourOverMethod {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        parameterLabel(labelText(for: .bloomDuration), helpTopic: .bloomDuration)
                        Spacer()
                        Text("\(Int(draft.preInfusionDuration))\(AppConstants.Text.secondsUnit)")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.primaryCopper)
                    }

                    PrecisionSlider(value: $draft.preInfusionDuration, range: AppConstants.Methods.Ranges.bloomDuration, step: AppConstants.Methods.Steps.bloomDuration, onInteraction: {
                        registerInteraction(.bloomDuration)
                    })

                    if shouldShowContextualHint(for: .bloomDuration) {
                        contextualHint(contextualHintText(for: .bloomDuration))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        parameterLabel(labelText(for: .steepDuration), helpTopic: .steepDuration)
                        Spacer()
                        Text("\(Int(draft.steepDuration))\(AppConstants.Text.secondsUnit)")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.primaryCopper)
                    }

                    PrecisionSlider(value: $draft.steepDuration, range: AppConstants.Methods.Ranges.steepDuration, step: AppConstants.Methods.Steps.steepDuration, onInteraction: {
                        registerInteraction(.steepDuration)
                    })

                    if shouldShowContextualHint(for: .steepDuration) {
                        contextualHint(contextualHintText(for: .steepDuration))
                    }

                    if draft.method == .aeropress {
                        Divider().overlay(Color.white.opacity(AppConstants.UI.strongBorderOpacity))
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                parameterLabel(labelText(for: .pressDuration), helpTopic: .pressDuration)
                                Spacer()
                                Text("\(Int(draft.pressDuration))\(AppConstants.Text.secondsUnit)")
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.primaryCopper)
                            }

                            PrecisionSlider(value: $draft.pressDuration, range: AppConstants.Methods.Ranges.pressDuration, step: AppConstants.Methods.Steps.pressDuration, onInteraction: {
                                registerInteraction(.pressDuration)
                            })

                            if shouldShowContextualHint(for: .pressDuration) {
                                contextualHint(contextualHintText(for: .pressDuration))
                            }
                        }
                    }
                }
            }

            Divider().overlay(Color.white.opacity(AppConstants.UI.subtleBorderOpacity))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    parameterLabel(labelText(for: .temperature), helpTopic: .temperature)
                    Spacer()
                    Text("\(Int(draft.targetTemperature.rounded()))\(AppConstants.Text.celsiusUnit)")
                        .font(.system(size: 19, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.primaryCopper)
                }

                RulerPicker(value: $draft.targetTemperature, range: AppConstants.Methods.Ranges.temperature, step: AppConstants.Methods.Steps.temperature, onInteraction: {
                    registerInteraction(.temperature)
                })
                .padding(.vertical, 8)

                if shouldShowContextualHint(for: .temperature) {
                    contextualHint(contextualHintText(for: .temperature))
                }
            }
        }
    }

    private var recipeNameSection: some View {
        SectionCard(AppConstants.Text.recipeName) {
            TextField(AppConstants.Methods.Text.recipeNamePlaceholder, text: $draft.name)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(Color.coffeeCream)
                .textFieldStyle(.plain)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                startBrew()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                    Text(AppConstants.Methods.Text.startBrew)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(Color.deepRoastInk)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.primaryCopper, Color.brushedCopper],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(28)
            }

            Button {
                saveDraft()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: saveButtonSystemImage)
                    Text(saveButtonTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .foregroundStyle(isSaveDisabled ? Color.white.opacity(0.3) : Color.coffeeCream)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
                )
            }
            .disabled(isSaveDisabled)
        }
        .padding(.horizontal)
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return AppConstants.Methods.Text.createRecipeNavigationTitle
        case .edit:
            return AppConstants.Methods.Text.editRecipeNavigationTitle
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .create:
            return AppConstants.Methods.Text.saveAsPreset
        case .edit:
            return AppConstants.Methods.Text.saveChanges
        }
    }

    private var saveButtonSystemImage: String {
        switch mode {
        case .create:
            return "square.and.arrow.down.fill"
        case .edit:
            return "checkmark.circle.fill"
        }
    }

    private var isSaveDisabled: Bool {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var experienceLevel: ProfileExperienceLevel {
        ProfileExperienceLevel(rawValue: experienceLevelRaw) ?? .justStarting
    }

    private var preferredMethods: [BrewMethod] {
        let selectedMethods = ProfilePreferences.decode(methods: methodsUsedRaw)
        return BrewMethod.allCases.filter { selectedMethods.contains($0) }
    }

    private var methodColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    private var orderedMethods: [BrewMethod] {
        let preferredSet = Set(preferredMethods)
        return preferredMethods + BrewMethod.allCases.filter { !preferredSet.contains($0) }
    }

    private var shouldShowStarterProfiles: Bool {
        experienceLevel == .justStarting
    }

    private var shouldShowTasteHints: Bool {
        experienceLevel != .enthusiast
    }

    private var currentStarterProfile: FirstCupProfile? {
        FirstCupProfile.allCases.first { draft.matchesStarterProfile($0, servingSize: starterServingSize) }
    }

    private var starterProfileSummaryText: String {
        if let profile = currentStarterProfile {
            return "\(starterServingSize.summary) • \(profile.summary)"
        }

        return "Tuned manually • \(overallTasteSummaryText)"
    }

    private var fallbackStarterProfile: FirstCupProfile {
        switch brewStrengthDirection {
        case .stronger:
            return .stronger
        case .balanced:
            return .balanced
        case .lighter:
            return .lighter
        }
    }

    private var overallTasteSummaryText: String {
        switch brewStrengthDirection {
        case .stronger:
            return draft.isPourOverMethod ? "Stronger • Fuller" : "Stronger • Shorter cup"
        case .balanced:
            return "Balanced everyday cup"
        case .lighter:
            return draft.isPourOverMethod ? "Lighter • Brighter" : "Lighter • Longer cup"
        }
    }

    private var brewStrengthDirection: BrewStrengthDirection {
        if draft.isPourOverMethod {
            switch draft.ratio {
            case ..<15.5:
                return .stronger
            case 16.5...:
                return .lighter
            default:
                return .balanced
            }
        }

        let concentration = draft.waterVolume / max(draft.beanWeight, 1)
        switch concentration {
        case ..<14.5:
            return .stronger
        case 16.5...:
            return .lighter
        default:
            return .balanced
        }
    }

    private var beanWeightHelperText: String {
        switch draft.method {
        case .v60:
            return "For V60, this is the dose the whole pour will orbit around — start with the cup size you actually want to drink."
        case .chemex:
            return "For Chemex, this dose sets the tone for a cleaner, bigger cup, so think in servings more than precision right now."
        case .frenchPress:
            return "For French Press, this is where body begins — a little more coffee makes the cup feel deeper and rounder."
        case .aeropress:
            return "For Aeropress, this dose is your first strength dial — the press will shape the texture after that."
        }
    }

    private var waterControlHelperText: String {
        switch draft.method {
        case .v60:
            return "A tighter ratio feels richer; a looser one keeps the cup brighter and easier to sip."
        case .chemex:
            return "Chemex usually likes a touch more openness, so a lighter ratio keeps the cup clean instead of heavy."
        case .frenchPress:
            return "This is simply how long of a cup you want — more water stretches it out, less water keeps it punchier."
        case .aeropress:
            return "Think of this as choosing between short and intense or longer and easier-going — both can taste great."
        }
    }

    private var bloomDurationHelperText: String {
        "A bloom is always part of these brewers here — you're just choosing how much breathing room the coffee gets before the main pour takes over."
    }

    private var steepDurationHelperText: String {
        switch draft.method {
        case .frenchPress:
            return "Steep time changes body more than drama here — the middle usually lands you in a warm, balanced place."
        case .aeropress:
            return "This is where the cup starts finding its shape — keep it gentle first, then nudge longer if you want more depth."
        case .v60, .chemex:
            return bloomDurationHelperText
        }
    }

    private var pressDurationHelperText: String {
        "The press should feel smooth, not like a workout — a calm push usually tastes cleaner in the cup."
    }

    private var temperatureHelperText: String {
        switch draft.method {
        case .v60, .chemex:
            return "If the cup feels a little sharp or a little hollow, temperature is often the quiet dial that brings it back into balance."
        case .frenchPress:
            return "Hotter water pulls more from immersion brews, but staying near the middle usually keeps the cup fuller without turning heavy."
        case .aeropress:
            return "Aeropress is forgiving here — staying around the middle is a calm place to start before you chase finer tweaks."
        }
    }

    @ViewBuilder
    private func contextualHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color.coffeeCream.opacity(0.58))
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(Color.coffeeCream)
            .tracking(AppConstants.UI.captionEmphasisTracking)
    }

    @ViewBuilder
    private func parameterLabel(_ title: String, helpTopic: HelpTopic) -> some View {
        HStack(spacing: 6) {
            sectionLabel(title)
            helpButton(for: helpTopic)
        }
    }

    @ViewBuilder
    private func methodPill(for method: BrewMethod) -> some View {
        let isSelected = draft.method == method

        Text(method.rawValue)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .foregroundStyle(isSelected ? Color.black : Color.coffeeCream.opacity(0.84))
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.0 : AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func starterProfilePill(for profile: FirstCupProfile) -> some View {
        let isSelected = currentStarterProfile == profile

        Text(profile.title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isSelected ? Color.black : Color.coffeeCream.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.0 : AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func starterServingSizePill(for servingSize: FirstCupServingSize) -> some View {
        let isSelected = starterServingSize == servingSize

        Text(servingSize.title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(isSelected ? Color.black : Color.coffeeCream.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.0 : AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func helpButton(for topic: HelpTopic) -> some View {
        Button {
            presentedHelpTopic = topic
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.coffeeCream.opacity(0.62))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shouldShowContextualHint(for topic: HelpTopic) -> Bool {
        shouldShowTasteHints && activeHintTopic == topic
    }

    private func registerInteraction(_ topic: HelpTopic) {
        syncDraftMathIfNeeded(for: topic)

        guard shouldShowTasteHints else { return }

        hintDismissTask?.cancel()

        withAnimation(.easeInOut(duration: AppConstants.Methods.Timing.methodSheetAnimationDuration)) {
            activeHintTopic = topic
        }

        hintDismissTask = Task {
            try? await Task.sleep(nanoseconds: AppConstants.Methods.Timing.contextualHintDismissNanoseconds)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if activeHintTopic == topic {
                    withAnimation(.easeOut(duration: AppConstants.Methods.Timing.methodSheetAnimationDuration)) {
                        activeHintTopic = nil
                    }
                }
            }
        }
    }

    private func syncDraftMathIfNeeded(for topic: HelpTopic) {
        switch topic {
        case .beanWeight, .waterRatio, .waterVolume:
            draft.syncBrewingMath()
        case .bloomDuration, .steepDuration, .pressDuration, .temperature, .method:
            break
        }
    }

    private func contextualHintText(for topic: HelpTopic) -> String {
        switch topic {
        case .beanWeight:
            switch brewStrengthDirection {
            case .stronger:
                return "More coffee • fuller body"
            case .balanced:
                return "Balanced body • easy place to start"
            case .lighter:
                return "Gentler body • lighter feel"
            }
        case .waterRatio:
            switch brewStrengthDirection {
            case .stronger:
                return "Stronger • Fuller"
            case .balanced:
                return "Balanced • Smooth"
            case .lighter:
                return "Lighter • Brighter"
            }
        case .waterVolume:
            switch brewStrengthDirection {
            case .stronger:
                return "Shorter cup • stronger feel"
            case .balanced:
                return "Balanced cup size"
            case .lighter:
                return "Longer cup • lighter feel"
            }
        case .bloomDuration:
            if draft.preInfusionDuration < 40 {
                return "Quicker start • brighter feel"
            } else if draft.preInfusionDuration > 47 {
                return "More settling time • rounder cup"
            }
            return "Balanced bloom time"
        case .steepDuration:
            if draft.steepDuration < 90 {
                return "Cleaner • lighter"
            } else if draft.steepDuration > 210 {
                return "Deeper • fuller"
            }
            return "Balanced • round"
        case .pressDuration:
            if draft.pressDuration < 28 {
                return "Quicker press • more direct finish"
            } else if draft.pressDuration > 32 {
                return "Slower press • cleaner finish"
            }
            return "Balanced press feel"
        case .temperature:
            if draft.targetTemperature < 91 {
                return "Softer • smoother"
            } else if draft.targetTemperature > 94 {
                return "Bolder • brighter"
            }
            return "Balanced sweetness"
        case .method:
            return starterProfileSummaryText
        }
    }

    private func helpContent(for topic: HelpTopic) -> HelpContent {
        switch topic {
        case .method:
            let content = draft.method.guideContent
            return HelpContent(title: content.title, summary: content.summary, startingPoint: content.startingPoint, note: content.note)
        case .beanWeight:
            switch draft.method {
            case .v60:
                return HelpContent(title: helpTitle(for: .beanWeight), summary: beanWeightHelperText, startingPoint: "18g is an easy, balanced place to start for a single mug.", note: "Once the cup feels right, you can scale the recipe up or down without changing its personality too much.")
            case .chemex:
                return HelpContent(title: helpTitle(for: .beanWeight), summary: beanWeightHelperText, startingPoint: "Start around 18-20g if you want a clean cup for one generous serving.", note: "Chemex tends to shine when you think in servings and flow, not just precision on paper.")
            case .frenchPress:
                return HelpContent(title: helpTitle(for: .beanWeight), summary: beanWeightHelperText, startingPoint: "18-20g is a nice first stop if you like the cup round and comforting.", note: "A touch more coffee adds weight quickly here, so small moves are enough.")
            case .aeropress:
                return HelpContent(title: helpTitle(for: .beanWeight), summary: beanWeightHelperText, startingPoint: "15-18g gives you room to go either lighter or stronger without fuss.", note: "If the cup feels too quiet, this is often the first dial worth nudging.")
            }
        case .waterRatio:
            switch draft.method {
            case .v60:
                return HelpContent(title: helpTitle(for: .waterRatio), summary: waterControlHelperText, startingPoint: "Around 1:15 or 1:16 usually lands in a balanced, easy first cup.", note: "Go tighter for more weight and a touch looser when you want the cup to feel brighter.")
            case .chemex:
                return HelpContent(title: helpTitle(for: .waterRatio), summary: waterControlHelperText, startingPoint: "1:16 to 1:17 is a comfortable window for keeping Chemex light and clean.", note: "If the cup starts feeling heavy, easing the ratio open is usually kinder than chasing bigger changes elsewhere.")
            case .frenchPress, .aeropress:
                return HelpContent(title: helpTitle(for: .waterRatio), summary: waterControlHelperText, startingPoint: "Start near the middle and let taste decide whether you want more weight or more space.", note: "This dial mainly decides how concentrated the final cup feels.")
            }
        case .waterVolume:
            return HelpContent(title: helpTitle(for: .waterVolume), summary: waterControlHelperText, startingPoint: "Pick the cup size you actually want first, then let the recipe meet you there.", note: "If you want a shorter, stronger cup, stay lower; if you want a longer one, stretch it gently.")
        case .bloomDuration:
            return HelpContent(title: helpTitle(for: .bloomDuration), summary: bloomDurationHelperText, startingPoint: "45 seconds is a calm middle ground that works nicely most days.", note: "If the bed still looks lively, a little more time can help the main pour settle in more evenly.")
        case .steepDuration:
            switch draft.method {
            case .frenchPress:
                return HelpContent(title: helpTitle(for: .steepDuration), summary: steepDurationHelperText, startingPoint: "About 4 minutes is the classic easy start for French Press.", note: "If the cup feels thin, go a little longer; if it feels too heavy, pull it back.")
            case .aeropress:
                return HelpContent(title: helpTitle(for: .steepDuration), summary: steepDurationHelperText, startingPoint: "Around 60 seconds keeps the cup friendly and easy to repeat.", note: "You can use press time after this to fine-tune texture without overcomplicating things.")
            case .v60, .chemex:
                return HelpContent(title: helpTitle(for: .steepDuration), summary: steepDurationHelperText, startingPoint: "Keep it around the middle first and let the cup tell you if it wants more time.", note: "Gentle changes are usually enough.")
            }
        case .pressDuration:
            return HelpContent(title: helpTitle(for: .pressDuration), summary: pressDurationHelperText, startingPoint: "Around 30 seconds is a nice, unhurried push.", note: "If you rush the press, the cup can feel a little rougher than it needs to.")
        case .temperature:
            switch draft.method {
            case .v60, .chemex:
                return HelpContent(title: helpTitle(for: .temperature), summary: temperatureHelperText, startingPoint: "93-94°C is a comfortable place to begin for most pour-overs.", note: "If the cup feels sharp, lower it a touch; if it feels flat, let it climb a little.")
            case .frenchPress:
                return HelpContent(title: helpTitle(for: .temperature), summary: temperatureHelperText, startingPoint: "Start around 92-94°C to keep the cup full without getting too heavy.", note: "This brewer usually responds better to small changes than dramatic ones.")
            case .aeropress:
                return HelpContent(title: helpTitle(for: .temperature), summary: temperatureHelperText, startingPoint: "Start near 90-92°C if you want a smooth, forgiving baseline.", note: "Aeropress gives you plenty of room to experiment once the rest of the recipe feels steady.")
            }
        }
    }

    private func labelText(for topic: HelpTopic) -> String {
        guard experienceLevel != .enthusiast else {
            switch topic {
            case .beanWeight:
                return AppConstants.Text.beanWeight
            case .waterRatio:
                return AppConstants.Text.waterRatio
            case .waterVolume:
                return AppConstants.Text.targetWaterVolume
            case .bloomDuration:
                return AppConstants.Text.bloomDuration
            case .steepDuration:
                return AppConstants.Text.steepDuration
            case .pressDuration:
                return AppConstants.Text.pressDuration
            case .temperature:
                return AppConstants.Text.targetTemperature
            case .method:
                return AppConstants.Text.selectMethod
            }
        }

        switch topic {
        case .beanWeight:
            return "COFFEE AMOUNT"
        case .waterRatio:
            return "COFFEE TO WATER"
        case .waterVolume:
            return "WATER AMOUNT"
        case .bloomDuration:
            return "BLOOM TIME"
        case .steepDuration:
            return "STEEP TIME"
        case .pressDuration:
            return "PRESS TIME"
        case .temperature:
            return "WATER TEMPERATURE"
        case .method:
            return AppConstants.Text.selectMethod
        }
    }

    private func helpTitle(for topic: HelpTopic) -> String {
        guard experienceLevel != .enthusiast else {
            switch topic {
            case .beanWeight:
                return "Coffee Dose"
            case .waterRatio:
                return "Water Ratio"
            case .waterVolume:
                return "Water Yield"
            case .bloomDuration:
                return "Bloom Duration"
            case .steepDuration:
                return "Steep Duration"
            case .pressDuration:
                return "Press Duration"
            case .temperature:
                return "Temperature"
            case .method:
                return draft.method.rawValue
            }
        }

        switch topic {
        case .beanWeight:
            return "Coffee Amount"
        case .waterRatio:
            return "Coffee to Water Ratio"
        case .waterVolume:
            return "Water Amount"
        case .bloomDuration:
            return "Bloom Time"
        case .steepDuration:
            return "Steep Time"
        case .pressDuration:
            return "Press Time"
        case .temperature:
            return "Water Temperature"
        case .method:
            return draft.method.rawValue
        }
    }

    private func selectMethod(_ method: BrewMethod) {
        let selectedProfile = shouldShowStarterProfiles ? currentStarterProfile : nil

        withAnimation {
            activeHintTopic = nil

            if let selectedProfile {
                draft.applyStarterProfile(selectedProfile, for: method, servingSize: starterServingSize)
            } else {
                draft.applyDefaults(for: method)
            }
        }
    }

    private func applyStarterProfile(_ profile: FirstCupProfile) {
        withAnimation {
            activeHintTopic = nil
            draft.applyStarterProfile(profile, servingSize: starterServingSize)
        }
    }

    private func applyStarterServingSize(_ servingSize: FirstCupServingSize) {
        let profile = currentStarterProfile ?? fallbackStarterProfile

        withAnimation {
            activeHintTopic = nil
            starterServingSize = servingSize
            draft.applyStarterProfile(profile, servingSize: servingSize)
        }
    }

    private func inferredStarterServingSize() -> FirstCupServingSize {
        if FirstCupProfile.allCases.contains(where: { draft.matchesStarterProfile($0, servingSize: .twoCups) }) {
            return .twoCups
        }

        return .oneCup
    }

    private func applyProfilePreferencesIfNeeded() {
        guard !hasAppliedProfileDefaults else { return }
        hasAppliedProfileDefaults = true

        if case .create = mode {
            let firstPreferredMethod = preferredMethods.first ?? draft.method

            if shouldShowStarterProfiles {
                starterServingSize = .oneCup
                draft.applyStarterProfile(.balanced, for: firstPreferredMethod, servingSize: starterServingSize)
            } else {
                draft.applyDefaults(for: firstPreferredMethod)
            }
        }

        starterServingSize = inferredStarterServingSize()
    }

    private func startBrew() {
        draft.syncBrewingMath()
        brewSessionStore.startTransientBrew(from: draft)
        selectedTab = .brew
        dismiss()
    }

    private func saveDraft() {
        guard !isSaveDisabled else { return }
        draft.syncBrewingMath()

        do {
            switch mode {
            case .create:
                modelContext.insert(draft.makeTemplate())
            case .edit(let template):
                draft.apply(to: template)
                brewSessionStore.refreshPersistentBrew(from: template)
            }

            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = AppConstants.Methods.Text.saveFailedMessage
        }
    }
}

private extension RecipeEditorView {
    enum BrewStrengthDirection {
        case stronger
        case balanced
        case lighter
    }
}

private struct MethodsHelpSheet: View {
    let title: String
    let summary: String
    let startingPoint: String
    let note: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appSheetTop,
                    Color.appSheetBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppConstants.Methods.HelpSheet.verticalSpacing) {
                    Text(title)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.coffeeCream)

                    Text(summary)
                        .font(.body)
                        .foregroundStyle(Color.coffeeCream.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .overlay(Color.white.opacity(AppConstants.UI.subtleBorderOpacity))

                    VStack(alignment: .leading, spacing: AppConstants.Methods.HelpSheet.sectionSpacing) {
                        Text(AppConstants.Methods.HelpSheet.goodPlaceToStart)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.2)
                            .foregroundStyle(Color.primaryCopper)

                        Text(startingPoint)
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeCream.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: AppConstants.Methods.HelpSheet.sectionSpacing) {
                        Text(AppConstants.Methods.HelpSheet.whyItMatters)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.2)
                            .foregroundStyle(Color.primaryCopper)

                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeCream.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, AppConstants.Methods.HelpSheet.topPadding)
                .padding(.horizontal, AppConstants.Methods.HelpSheet.horizontalPadding)
                .padding(.bottom, AppConstants.Methods.HelpSheet.bottomPadding)
            }
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.localizedUppercase)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primaryCopper)
                .tracking(AppConstants.UI.eyebrowTracking)
                .padding(.bottom, 4)

            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
        .liquidGlassBorder(cornerRadius: 16)
        .padding(.horizontal, 16)
    }
}
