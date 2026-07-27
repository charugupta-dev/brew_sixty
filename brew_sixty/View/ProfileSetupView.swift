import SwiftUI

struct ProfileSetupView: View {
    enum Mode {
        case onboarding
        case edit
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss

    @AppStorage(ProfilePreferences.Keys.hasCompletedProfile) private var hasCompletedProfile = false
    @AppStorage(ProfilePreferences.Keys.name) private var storedName = ""
    @AppStorage(ProfilePreferences.Keys.experienceLevel) private var storedExperienceLevel = ProfileExperienceLevel.justStarting.rawValue
    @AppStorage(ProfilePreferences.Keys.methodsUsed) private var storedMethodsUsed = ""

    @State private var name = ""
    @State private var experienceLevel: ProfileExperienceLevel = .justStarting
    @State private var selectedMethods: Set<BrewMethod> = []
    @State private var isShowingMethodGuide = false

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedMethods.isEmpty
    }

    private var titleText: String {
        mode == .onboarding ? "Set up your brew profile" : "Profile & preferences"
    }

    private var subtitleText: String {
        mode == .onboarding
            ? "Make the app feel personal and easier to use from the very first brew."
            : "Update how the app greets you and which brewers you want front and center."
    }

    private var ctaText: String {
        mode == .onboarding ? "Continue" : "Save Changes"
    }

    private var methodsSectionTitle: String {
        mode == .onboarding ? "WHICH BREWER DO YOU HAVE?" : "METHODS YOU USE"
    }

    private var methodsSectionSubtitle: String {
        mode == .onboarding ? "Choose the one you have now or the one you want to start with" : "Select all that apply"
    }

    private var siriExamples: [String] {
        switch experienceLevel {
        case .justStarting:
            return [
                "Start a V60 brew",
                "Create a 2 cup Chemex",
                "Show my recipes"
            ]
        case .someExperience:
            return [
                "Start my Aeropress brew",
                "Create a lighter V60",
                "Show my recipes"
            ]
        case .enthusiast:
            return [
                "Start Morning Ritual",
                "Create a Chemex recipe",
                "Show my recipes"
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VideoWallpaperBackground(style: .onboarding)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(titleText)
                                .font(.system(.title, design: .serif))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.coffeeCream)

                            Text(subtitleText)
                                .font(.subheadline)
                                .foregroundStyle(Color.coffeeCream.opacity(0.72))
                        }
                        .padding(.top, 12)

                        profileCard {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("NAME")

                                TextField("What should we call you?", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.94, green: 0.92, blue: 0.89), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
                                    )
                                    .foregroundStyle(Color.coffeeCream)
                            }
                        }

                        profileCard {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("EXPERIENCE LEVEL")

                                VStack(spacing: 10) {
                                    ForEach(ProfileExperienceLevel.allCases) { level in
                                        selectionRow(
                                            title: level.title,
                                            subtitle: level.subtitle,
                                            isSelected: experienceLevel == level
                                        ) {
                                            experienceLevel = level
                                        }
                                    }
                                }
                            }
                        }

                        profileCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    sectionLabel(methodsSectionTitle)
                                    Spacer()
                                    Button {
                                        isShowingMethodGuide = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.coffeeCream.opacity(0.68))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Text(methodsSectionSubtitle)
                                    .font(.footnote)
                                    .foregroundStyle(Color.coffeeCream.opacity(0.58))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                                    ForEach(BrewMethod.allCases, id: \.self) { method in
                                        let isSelected = selectedMethods.contains(method)

                                        Button {
                                            toggle(method)
                                        } label: {
                                            Text(method.rawValue)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(isSelected ? .white : Color.coffeeCream.opacity(0.82))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    Capsule(style: .continuous)
                                                        .fill(isSelected ? Color.primaryCopper : Color(red: 0.94, green: 0.92, blue: 0.89))
                                                )
                                                .overlay(
                                                    Capsule(style: .continuous)
                                                        .stroke(isSelected ? Color.clear : Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        profileCard {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionLabel("USE WITH SIRI")

                                Text("Say one command to Siri or run the shortcut from Shortcuts. Brew Sixty will open in the right screen and keep the rest of the flow inside the app.")
                                    .font(.footnote)
                                    .foregroundStyle(Color.coffeeCream.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(spacing: 10) {
                                    ForEach(siriExamples, id: \.self) { example in
                                        siriExampleRow(example)
                                    }
                                }

                                if let shortcutsURL = URL(string: "shortcuts://") {
                                    Link(destination: shortcutsURL) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "waveform.badge.mic")
                                                .font(.system(size: 13, weight: .semibold))

                                            Text("Open Shortcuts")
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundStyle(Color.deepRoastInk)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(Color.primaryCopper)
                                        )
                                    }
                                }
                            }
                        }

                        Button(action: saveProfile) {
                            HStack {
                                Spacer()
                                Text(ctaText)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.primaryCopper, Color.brushedCopper],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(28)
                            .opacity(isSaveDisabled ? 0.45 : 1.0)
                        }
                        .disabled(isSaveDisabled)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .interactiveDismissDisabled(mode == .onboarding)
            .sheet(isPresented: $isShowingMethodGuide) {
                MethodEducationLibrarySheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                if mode == .edit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.coffeeCream.opacity(0.84))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear(perform: loadStoredValues)
        }
    }

    @ViewBuilder
    private func profileCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.97, blue: 0.96))
            )
            .liquidGlassBorder(cornerRadius: AppConstants.UI.cardCornerRadius)
    }

    @ViewBuilder
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.bold)
            .tracking(1.2)
            .foregroundStyle(Color.coffeeCream.opacity(0.68))
    }

    @ViewBuilder
    private func selectionRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.coffeeCream.opacity(isSelected ? 1.0 : 0.6))

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.coffeeCream.opacity(isSelected ? 0.72 : 0.42))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Circle()
                    .stroke(isSelected ? Color.primaryCopper : Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle()
                            .fill(Color.primaryCopper)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color(red: 0.94, green: 0.92, blue: 0.89) : Color(red: 0.98, green: 0.97, blue: 0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.primaryCopper.opacity(0.32) : Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func siriExampleRow(_ example: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primaryCopper)
                .frame(width: 20)

            Text("“\(example)”")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.coffeeCream.opacity(0.82))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
        )
    }

    private func loadStoredValues() {
        if name.isEmpty {
            name = storedName
        }

        experienceLevel = ProfileExperienceLevel(rawValue: storedExperienceLevel) ?? .justStarting
        selectedMethods = ProfilePreferences.decode(methods: storedMethodsUsed)
    }

    private func toggle(_ method: BrewMethod) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }

    private func saveProfile() {
        storedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        storedExperienceLevel = experienceLevel.rawValue
        storedMethodsUsed = ProfilePreferences.encode(methods: selectedMethods)
        hasCompletedProfile = true

        dismiss()
    }
}

#Preview {
    ProfileSetupView(mode: .onboarding)
}

private struct MethodEducationLibrarySheet: View {
    @State private var expandedMethod: BrewMethod? = .v60

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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Your Brew Method")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.coffeeCream)

                    Text("See how each brewer feels in the cup before you decide which ones you want to use most.")
                        .font(.subheadline)
                        .foregroundStyle(Color.coffeeCream.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 12) {
                        ForEach(BrewMethod.allCases, id: \.self) { method in
                            MethodEducationCard(
                                method: method,
                                isExpanded: expandedMethod == method
                            ) {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    expandedMethod = expandedMethod == method ? nil : method
                                }
                            }
                        }
                    }
                }
                .padding(.top, 26)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct MethodEducationCard: View {
    let method: BrewMethod
    let isExpanded: Bool
    let action: () -> Void

    private var content: MethodGuideContent {
        method.guideContent
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.coffeeCream)

                        Text(content.startingPoint)
                            .font(.footnote)
                            .foregroundStyle(Color.coffeeCream.opacity(0.62))
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryCopper)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(content.summary)
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeCream.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .overlay(Color(red: 0.86, green: 0.84, blue: 0.81))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Good place to start")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(1.2)
                                .foregroundStyle(Color.primaryCopper)

                            Text(content.startingPoint)
                                .font(.subheadline)
                                .foregroundStyle(Color.coffeeCream.opacity(0.80))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why it matters")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(1.2)
                                .foregroundStyle(Color.primaryCopper)

                            Text(content.note)
                                .font(.subheadline)
                                .foregroundStyle(Color.coffeeCream.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isExpanded ? Color(red: 0.94, green: 0.92, blue: 0.89) : Color(red: 0.98, green: 0.97, blue: 0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isExpanded ? Color.primaryCopper.opacity(0.24) : Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
