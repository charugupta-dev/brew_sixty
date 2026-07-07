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
    @AppStorage(ProfilePreferences.Keys.guidanceMode) private var storedGuidanceMode = GuidanceMode.guided.rawValue

    @State private var name = ""
    @State private var experienceLevel: ProfileExperienceLevel = .justStarting
    @State private var selectedMethods: Set<BrewMethod> = []
    @State private var guidanceMode: GuidanceMode = .guided

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedMethods.isEmpty
    }

    private var titleText: String {
        mode == .onboarding ? "Set up your brew profile" : "Profile & preferences"
    }

    private var subtitleText: String {
        mode == .onboarding
            ? "Make the app feel personal and easier to use from the very first brew."
            : "Update how the app greets you and how much guidance it should give."
    }

    private var ctaText: String {
        mode == .onboarding ? "Continue" : "Save Changes"
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
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
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
                                sectionLabel("METHODS YOU USE")
                                
                                Text("Select all that apply")
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
                                                .foregroundStyle(isSelected ? Color.black : Color.coffeeCream.opacity(0.82))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    Capsule(style: .continuous)
                                                        .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.05))
                                                )
                                                .overlay(
                                                    Capsule(style: .continuous)
                                                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        profileCard {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("GUIDANCE MODE")

                                VStack(spacing: 10) {
                                    ForEach(GuidanceMode.allCases) { mode in
                                        selectionRow(
                                            title: mode.title,
                                            subtitle: mode.subtitle,
                                            isSelected: guidanceMode == mode
                                        ) {
                                            guidanceMode = mode
                                        }
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
                            .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.08))
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
            .toolbar {
                if mode == .edit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.coffeeCream)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.06), in: Circle())
                        }
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
                    .fill(Color(red: 0.10, green: 0.09, blue: 0.09).opacity(AppConstants.UI.cardOpacity))
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
                    .stroke(isSelected ? Color.primaryCopper : Color.white.opacity(0.18), lineWidth: 1.5)
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
                    .fill(isSelected ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.primaryCopper.opacity(0.32) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadStoredValues() {
        if name.isEmpty {
            name = storedName
        }

        experienceLevel = ProfileExperienceLevel(rawValue: storedExperienceLevel) ?? .justStarting
        guidanceMode = GuidanceMode(rawValue: storedGuidanceMode) ?? .guided
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
        storedGuidanceMode = guidanceMode.rawValue
        storedMethodsUsed = ProfilePreferences.encode(methods: selectedMethods)
        hasCompletedProfile = true

        dismiss()
    }
}

#Preview {
    ProfileSetupView(mode: .onboarding)
}
