import SwiftUI
import SwiftData

struct MethodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: ContentView.Tab
    
    @Query(sort: \BrewTemplate.createdAt, order: .forward) private var templates: [BrewTemplate]
    @AppStorage(ProfilePreferences.Keys.experienceLevel) private var experienceLevelRaw = ProfileExperienceLevel.justStarting.rawValue
    @AppStorage(ProfilePreferences.Keys.guidanceMode) private var guidanceModeRaw = GuidanceMode.guided.rawValue
    @AppStorage(ProfilePreferences.Keys.methodsUsed) private var methodsUsedRaw = ""

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

    @State private var showTemplatesSheet = false
    @State private var presentedHelpTopic: HelpTopic?
    @State private var activeHintTopic: HelpTopic?
    @State private var saveErrorMessage: String?
    
    @State private var recipeName = AppConstants.Methods.Defaults.recipeName
    @State private var selectedMethod: BrewMethod = .v60
    
    @State private var beanWeight: Double = AppConstants.Methods.Defaults.beanWeight
    @State private var ratio: Double = AppConstants.Methods.Defaults.ratio
    @State private var waterVolume: Double = AppConstants.Methods.Defaults.waterVolume
    @State private var preInfusionDuration: Double = AppConstants.Methods.Defaults.bloomDuration
    @State private var steepDuration: Double = AppConstants.Methods.Defaults.frenchPressSteepDuration
    @State private var pressDuration: Double = AppConstants.Methods.Defaults.aeropressPressDuration
    @State private var targetTemperature: Double = AppConstants.Methods.Defaults.targetTemperature
    @State private var hapticFeedbackEnabled = true
    @State private var autoSyncEnabled = true
    @State private var hasAppliedProfileDefaults = false
    @State private var hintDismissTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            VideoWallpaperBackground(style: .quiet)

            ScrollView {
                VStack(spacing: AppConstants.Methods.Layout.sectionSpacing) {
                    Button {
                        showTemplatesSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(AppConstants.Methods.Text.recipesTitle)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.primaryCopper)
                                    .tracking(AppConstants.UI.eyebrowTracking)
                                
                                Text("\(templates.count) \(AppConstants.Methods.Text.savedTemplatesSuffix)")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.coffeeCream)
                                
                                Text(AppConstants.Methods.Text.recipesSubtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.primaryCopper)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                                .fill(Color.appPanel.opacity(AppConstants.UI.cardOpacity))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                                .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            sectionLabel(AppConstants.Text.selectMethod)
                            Spacer()
                            modeBadge(modeLabel)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: AppConstants.Methods.Layout.compactRowSpacing) {
                            ForEach(orderedMethods, id: \.self) { method in
                                Button {
                                    selectMethod(method)
                                } label: {
                                    methodPill(for: method)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    SectionCard("Dose & Yield") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                parameterLabel(AppConstants.Text.beanWeight, helpTopic: .beanWeight)
                                Spacer()
                                Text(String(format: "%.1f%@", beanWeight, AppConstants.Text.gramsUnit))
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundStyle(Color.primaryCopper)
                            }

                            SteppedWeightPicker(value: $beanWeight, onInteraction: {
                                registerInteraction(.beanWeight)
                            })

                            if shouldShowContextualHint(for: .beanWeight) {
                                contextualHint(beanWeightHelperText)
                            }
                        }

                        Divider().background(Color.white.opacity(0.08))

                        if isPourOverMethod {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    parameterLabel(AppConstants.Text.waterRatio, helpTopic: .waterRatio)
                                    Spacer()
                                    Text(String(format: "1:%.1f", ratio))
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(Color.primaryCopper)
                                }

                                PrecisionSlider(value: $ratio, range: AppConstants.Methods.Ranges.waterRatio, step: AppConstants.Methods.Steps.waterRatio, onInteraction: {
                                    registerInteraction(.waterRatio)
                                })

                                if shouldShowContextualHint(for: .waterRatio) {
                                    contextualHint(waterControlHelperText)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    parameterLabel(AppConstants.Text.targetWaterVolume, helpTopic: .waterVolume)
                                    Spacer()
                                    Text("\(Int(waterVolume))g")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(Color.primaryCopper)
                                }

                                PrecisionSlider(value: $waterVolume, range: AppConstants.Methods.Ranges.waterVolume, step: AppConstants.Methods.Steps.waterVolume, onInteraction: {
                                    registerInteraction(.waterVolume)
                                })

                                if shouldShowContextualHint(for: .waterVolume) {
                                    contextualHint(waterControlHelperText)
                                }
                            }
                        }
                    }

                    SectionCard("Time & Temperature") {
                        if isPourOverMethod {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    parameterLabel(AppConstants.Text.bloomDuration, helpTopic: .bloomDuration)
                                    Spacer()
                                    Text("\(Int(preInfusionDuration))\(AppConstants.Text.secondsUnit)")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(Color.primaryCopper)
                                }

                                PrecisionSlider(value: $preInfusionDuration, range: AppConstants.Methods.Ranges.bloomDuration, step: AppConstants.Methods.Steps.bloomDuration, onInteraction: {
                                    registerInteraction(.bloomDuration)
                                })

                                if shouldShowContextualHint(for: .bloomDuration) {
                                    contextualHint(bloomDurationHelperText)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    parameterLabel(AppConstants.Text.steepDuration, helpTopic: .steepDuration)
                                    Spacer()
                                    Text("\(Int(steepDuration))\(AppConstants.Text.secondsUnit)")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(Color.primaryCopper)
                                }

                                PrecisionSlider(value: $steepDuration, range: AppConstants.Methods.Ranges.steepDuration, step: AppConstants.Methods.Steps.steepDuration, onInteraction: {
                                    registerInteraction(.steepDuration)
                                })

                                if shouldShowContextualHint(for: .steepDuration) {
                                    contextualHint(steepDurationHelperText)
                                }

                                if selectedMethod == .aeropress {
                                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            parameterLabel(AppConstants.Text.pressDuration, helpTopic: .pressDuration)
                                            Spacer()
                                            Text("\(Int(pressDuration))\(AppConstants.Text.secondsUnit)")
                                                .font(.system(.headline, design: .monospaced))
                                                .foregroundStyle(Color.primaryCopper)
                                        }

                                        PrecisionSlider(value: $pressDuration, range: AppConstants.Methods.Ranges.pressDuration, step: AppConstants.Methods.Steps.pressDuration, onInteraction: {
                                            registerInteraction(.pressDuration)
                                        })

                                        if shouldShowContextualHint(for: .pressDuration) {
                                            contextualHint(pressDurationHelperText)
                                        }
                                    }
                                }
                            }
                        }

                        Divider().background(Color.white.opacity(0.08))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                parameterLabel(AppConstants.Text.targetTemperature, helpTopic: .temperature)
                                Spacer()
                                Text(String(format: "%.1f%@", targetTemperature, AppConstants.Text.celsiusUnit))
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundStyle(Color.primaryCopper)
                            }

                            RulerPicker(value: $targetTemperature, range: AppConstants.Methods.Ranges.temperature, step: AppConstants.Methods.Steps.temperature, onInteraction: {
                                registerInteraction(.temperature)
                            })
                            .padding(.vertical, 8)

                            if shouldShowContextualHint(for: .temperature) {
                                contextualHint(temperatureHelperText)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel(AppConstants.Text.recipeName)

                        TextField(AppConstants.Methods.Text.recipeNamePlaceholder, text: $recipeName)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.coffeeCream)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                            .fill(Color.appPanel.opacity(AppConstants.UI.cardOpacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                            .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Button {
                        saveTemplate()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.down.fill")
                            Text(AppConstants.Text.saveTemplate)
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .foregroundStyle(isSaveDisabled ? Color.white.opacity(0.3) : .black)
                        .padding(.vertical, 16)
                        .background(
                            isSaveDisabled ?
                            LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(
                                colors: [Color.primaryCopper, Color.brushedCopper],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(isSaveDisabled)
                    .padding(.horizontal)
                    .padding(.bottom, AppConstants.Methods.Layout.methodsBottomPadding)
                }
                .padding(.top, AppConstants.Methods.Layout.methodPickerTopPadding)
            }
            .sheet(isPresented: $showTemplatesSheet) {
                TemplatesListView()
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
    
    var isSaveDisabled: Bool {
        recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var isPourOverMethod: Bool {
        selectedMethod == .v60 || selectedMethod == .chemex
    }
    
    private func saveTemplate() {
        let finalPreInfusionActive = isPourOverMethod
        let finalPreInfusionDuration = isPourOverMethod ? preInfusionDuration : 0.0
        let finalSteepDuration = isPourOverMethod ? 0.0 : steepDuration
        let finalPressDuration = selectedMethod == .aeropress ? pressDuration : (selectedMethod == .frenchPress ? AppConstants.BrewTimer.frenchPressPlungeDuration : 0.0)
        
        let template = BrewTemplate(
            name: recipeName,
            method: selectedMethod,
            beanWeight: beanWeight,
            ratio: ratio,
            waterVolume: waterVolume,
            preInfusionActive: finalPreInfusionActive,
            preInfusionDuration: finalPreInfusionDuration,
            targetTemperature: targetTemperature,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            autoSyncEnabled: autoSyncEnabled,
            steepDuration: finalSteepDuration,
            pressDuration: finalPressDuration
        )
        
        modelContext.insert(template)
        do {
            try modelContext.save()

            withAnimation {
                selectedTab = .brew
            }
        } catch {
            modelContext.delete(template)
            saveErrorMessage = AppConstants.Methods.Text.saveFailedMessage
        }
    }

    private var experienceLevel: ProfileExperienceLevel {
        ProfileExperienceLevel(rawValue: experienceLevelRaw) ?? .justStarting
    }

    private var guidanceMode: GuidanceMode {
        GuidanceMode(rawValue: guidanceModeRaw) ?? .guided
    }

    private var preferredMethods: [BrewMethod] {
        let selectedMethods = ProfilePreferences.decode(methods: methodsUsedRaw)
        return BrewMethod.allCases.filter { selectedMethods.contains($0) }
    }

    private var orderedMethods: [BrewMethod] {
        let preferredSet = Set(preferredMethods)
        return preferredMethods + BrewMethod.allCases.filter { !preferredSet.contains($0) }
    }

    private var shouldShowParameterHelp: Bool {
        guidanceMode == .guided && experienceLevel == .justStarting
    }

    private var modeLabel: String {
        guidanceMode == .guided ? AppConstants.Methods.Text.guidedMode : AppConstants.Methods.Text.manualMode
    }

    private var beanWeightHelperText: String {
        switch selectedMethod {
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
        switch selectedMethod {
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
        switch selectedMethod {
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
        switch selectedMethod {
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
            .font(.footnote)
            .foregroundStyle(Color.coffeeCream.opacity(0.58))
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
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
        let isSelected = selectedMethod == method

        Text(method.rawValue)
            .font(.system(size: 11, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isSelected ? Color.black : Color.coffeeCream.opacity(0.8))
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.0 : AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func modeBadge(_ title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.primaryCopper.opacity(0.9))
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.coffeeCream.opacity(0.82))
        }
        .padding(.horizontal, AppConstants.Methods.Layout.pillHorizontalPadding)
        .padding(.vertical, AppConstants.Methods.Layout.pillVerticalPadding)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
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
        shouldShowParameterHelp && activeHintTopic == topic
    }

    private func registerInteraction(_ topic: HelpTopic) {
        guard shouldShowParameterHelp else { return }

        hintDismissTask?.cancel()

        withAnimation(.easeInOut(duration: 0.2)) {
            activeHintTopic = topic
        }

        hintDismissTask = Task {
            try? await Task.sleep(nanoseconds: AppConstants.Methods.Timing.contextualHintDismissNanoseconds)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if activeHintTopic == topic {
                    withAnimation(.easeOut(duration: 0.2)) {
                        activeHintTopic = nil
                    }
                }
            }
        }
    }

    private func helpContent(for topic: HelpTopic) -> HelpContent {
        switch topic {
        case .method:
            switch selectedMethod {
            case .v60:
                return HelpContent(
                    title: "V60",
                    summary: "V60 usually gives you a cleaner, brighter cup where the flavors feel a little more separated and vivid.",
                    startingPoint: "If you want a calm everyday pour-over, this is a lovely place to begin.",
                    note: "It rewards a steady pour more than force, so small adjustments show up clearly in the cup."
                )
            case .chemex:
                return HelpContent(
                    title: "Chemex",
                    summary: "Chemex leans elegant and tea-like, with more space, clarity, and softness in the finish.",
                    startingPoint: "It is a great pick when you want a larger cup that still feels light on its feet.",
                    note: "A slightly looser ratio usually keeps it open and polished instead of heavy."
                )
            case .frenchPress:
                return HelpContent(
                    title: "French Press",
                    summary: "French Press brings more body and texture, so the cup feels deeper, warmer, and a little more comforting.",
                    startingPoint: "Choose this when you want brewing to feel simple and the cup to feel fuller.",
                    note: "Steep time matters, but this brewer is usually more forgiving than it first looks."
                )
            case .aeropress:
                return HelpContent(
                    title: "Aeropress",
                    summary: "Aeropress is flexible and forgiving, so it can land anywhere from punchy and short to smooth and easy-going.",
                    startingPoint: "It is a great choice when you want a brewer that adapts quickly to your mood.",
                    note: "Steep time and press time work together here, so gentle changes go a long way."
                )
            }
        case .beanWeight:
            switch selectedMethod {
            case .v60:
                return HelpContent(
                    title: "Bean Weight",
                    summary: beanWeightHelperText,
                    startingPoint: "18g is an easy, balanced place to start for a single mug.",
                    note: "Once the cup feels right, you can scale the recipe up or down without changing its personality too much."
                )
            case .chemex:
                return HelpContent(
                    title: "Bean Weight",
                    summary: beanWeightHelperText,
                    startingPoint: "Start around 18-20g if you want a clean cup for one generous serving.",
                    note: "Chemex tends to shine when you think in servings and flow, not just precision on paper."
                )
            case .frenchPress:
                return HelpContent(
                    title: "Bean Weight",
                    summary: beanWeightHelperText,
                    startingPoint: "18-20g is a nice first stop if you like the cup round and comforting.",
                    note: "A touch more coffee adds weight quickly here, so small moves are enough."
                )
            case .aeropress:
                return HelpContent(
                    title: "Bean Weight",
                    summary: beanWeightHelperText,
                    startingPoint: "15-18g gives you room to go either lighter or stronger without fuss.",
                    note: "If the cup feels too quiet, this is often the first dial worth nudging."
                )
            }
        case .waterRatio:
            switch selectedMethod {
            case .v60:
                return HelpContent(
                    title: "Water Ratio",
                    summary: waterControlHelperText,
                    startingPoint: "Around 1:15 or 1:16 usually lands in a balanced, easy first cup.",
                    note: "Go tighter for more weight and a touch looser when you want the cup to feel brighter."
                )
            case .chemex:
                return HelpContent(
                    title: "Water Ratio",
                    summary: waterControlHelperText,
                    startingPoint: "1:15.5 to 1:16.5 is a comfortable window for keeping Chemex light and clean.",
                    note: "If the cup starts feeling heavy, easing the ratio open is usually kinder than chasing bigger changes elsewhere."
                )
            case .frenchPress, .aeropress:
                return HelpContent(
                    title: "Water Ratio",
                    summary: waterControlHelperText,
                    startingPoint: "Start near the middle and let taste decide whether you want more weight or more space.",
                    note: "This dial mainly decides how concentrated the final cup feels."
                )
            }
        case .waterVolume:
            return HelpContent(
                title: "Water Volume",
                summary: waterControlHelperText,
                startingPoint: "Pick the cup size you actually want first, then let the recipe meet you there.",
                note: "If you want a shorter, stronger cup, stay lower; if you want a longer one, stretch it gently."
            )
        case .bloomDuration:
            return HelpContent(
                title: "Bloom Duration",
                summary: bloomDurationHelperText,
                startingPoint: "45 seconds is a calm middle ground that works nicely most days.",
                note: "If the bed still looks lively, a little more time can help the main pour settle in more evenly."
            )
        case .steepDuration:
            switch selectedMethod {
            case .frenchPress:
                return HelpContent(
                    title: "Steep Duration",
                    summary: steepDurationHelperText,
                    startingPoint: "About 4 minutes is the classic easy start for French Press.",
                    note: "If the cup feels thin, go a little longer; if it feels too heavy, pull it back."
                )
            case .aeropress:
                return HelpContent(
                    title: "Steep Duration",
                    summary: steepDurationHelperText,
                    startingPoint: "Around 60 seconds keeps the cup friendly and easy to repeat.",
                    note: "You can use press time after this to fine-tune texture without overcomplicating things."
                )
            case .v60, .chemex:
                return HelpContent(
                    title: "Steep Duration",
                    summary: steepDurationHelperText,
                    startingPoint: "Keep it around the middle first and let the cup tell you if it wants more time.",
                    note: "Gentle changes are usually enough."
                )
            }
        case .pressDuration:
            return HelpContent(
                title: "Press Duration",
                summary: pressDurationHelperText,
                startingPoint: "Around 30 seconds is a nice, unhurried push.",
                note: "If you rush the press, the cup can feel a little rougher than it needs to."
            )
        case .temperature:
            switch selectedMethod {
            case .v60, .chemex:
                return HelpContent(
                    title: "Temperature",
                    summary: temperatureHelperText,
                    startingPoint: "93-94°C is a comfortable place to begin for most pour-overs.",
                    note: "If the cup feels sharp, lower it a touch; if it feels flat, let it climb a little."
                )
            case .frenchPress:
                return HelpContent(
                    title: "Temperature",
                    summary: temperatureHelperText,
                    startingPoint: "Start around 92-94°C to keep the cup full without getting too heavy.",
                    note: "This brewer usually responds better to small changes than dramatic ones."
                )
            case .aeropress:
                return HelpContent(
                    title: "Temperature",
                    summary: temperatureHelperText,
                    startingPoint: "Start near 90-92°C if you want a smooth, forgiving baseline.",
                    note: "Aeropress gives you plenty of room to experiment once the rest of the recipe feels steady."
                )
            }
        }
    }

    private func selectMethod(_ method: BrewMethod) {
        withAnimation {
            activeHintTopic = nil
            applyDefaults(for: method)
        }
        presentedHelpTopic = .method
    }

    private func applyDefaults(for method: BrewMethod) {
        selectedMethod = method

        if method == .v60 || method == .chemex {
            preInfusionDuration = AppConstants.Methods.Defaults.bloomDuration
        } else if method == .frenchPress {
            steepDuration = AppConstants.Methods.Defaults.frenchPressSteepDuration
        } else if method == .aeropress {
            steepDuration = AppConstants.Methods.Defaults.aeropressSteepDuration
            pressDuration = AppConstants.Methods.Defaults.aeropressPressDuration
        }
    }

    private func applyProfilePreferencesIfNeeded() {
        guard !hasAppliedProfileDefaults else { return }
        hasAppliedProfileDefaults = true

        guard let firstPreferredMethod = preferredMethods.first else { return }
        applyDefaults(for: firstPreferredMethod)
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

struct TemplatesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BrewTemplate.createdAt, order: .forward) private var templates: [BrewTemplate]
    @State private var deletionErrorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VideoWallpaperBackground(style: .quiet)
                
                if templates.isEmpty {
                    ContentUnavailableView {
                        Label(AppConstants.Methods.Text.noSavedRecipes, systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text(AppConstants.Methods.Text.emptyRecipesDescription)
                    }
                    .foregroundStyle(Color.coffeeCream)
                } else {
                    List {
                        ForEach(templates) { template in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(template.name)
                                            .font(.headline)
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
                                    .foregroundStyle(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
            .navigationTitle(AppConstants.Methods.Text.savedTemplatesSuffix)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppConstants.Methods.Text.done) {
                        dismiss()
                    }
                    .tint(Color.primaryCopper)
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

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionErrorMessage != nil },
            set: { if !$0 { deletionErrorMessage = nil } }
        )
    }

    private func deleteTemplate(_ template: BrewTemplate) {
        modelContext.delete(template)

        do {
            try modelContext.save()
        } catch {
            deletionErrorMessage = AppConstants.Methods.Text.deleteFailedMessage
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.primaryCopper)
                .tracking(1.5)
                .padding(.bottom, 4)
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

