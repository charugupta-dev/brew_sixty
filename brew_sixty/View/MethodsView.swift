import SwiftUI
import SwiftData

struct MethodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: ContentView.Tab
    
    @Query(sort: \BrewTemplate.createdAt, order: .forward) private var templates: [BrewTemplate]
    @State private var showTemplatesSheet = false
    
    @State private var recipeName = "Morning Ritual"
    @State private var selectedMethod: BrewMethod = .v60
    
    // Parameter values
    @State private var beanWeight: Double = 18.0
    @State private var ratio: Double = 15.0
    @State private var waterVolume: Double = 270.0
    @State private var preInfusionActive = true
    @State private var preInfusionDuration: Double = 45.0
    @State private var steepDuration: Double = 240.0
    @State private var pressDuration: Double = 30.0
    @State private var targetTemperature: Double = 93.5
    @State private var hapticFeedbackEnabled = true
    @State private var autoSyncEnabled = true
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Header Card (Saved Templates / Interactive Button Card)
                    Button {
                        showTemplatesSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("YOUR RECIPES")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.primaryCopper)
                                    .tracking(1.5)
                                
                                Text("\(templates.count) Saved Templates")
                                    .font(.system(.title2, design: .serif))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("Tap to view or delete your recipes")
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
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                        )
                        .liquidGlassBorder(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // 2. Select Method Buttons
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SELECT METHOD")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.0)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(BrewMethod.allCases, id: \.self) { method in
                                    Button {
                                        withAnimation {
                                            selectedMethod = method
                                            if method == .v60 || method == .chemex {
                                                preInfusionDuration = 45.0
                                                preInfusionActive = true
                                            } else if method == .frenchPress {
                                                preInfusionDuration = 240.0
                                                preInfusionActive = false
                                            } else if method == .aeropress {
                                                preInfusionDuration = 60.0
                                                preInfusionActive = false
                                            }
                                        }
                                    } label: {
                                        Text(method.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(selectedMethod == method ? Color.primaryCopper : Color.white.opacity(0.04))
                                            )
                                            .foregroundStyle(selectedMethod == method ? Color.black : Color.white.opacity(0.8))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(selectedMethod == method ? 0.0 : 0.08), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 3. Bean Weight (Horizontal scrolling Ruler Dialer)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("BEAN WEIGHT (GRAMS)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(1.0)
                            Spacer()
                            Text(String(format: "%.1fg", beanWeight))
                                .font(.headline)
                                .foregroundStyle(Color.primaryCopper)
                        }
                        
                        RulerPicker(value: $beanWeight, range: 5.0...40.0, step: 0.5)
                            .padding(.vertical, 8)
                    }
                    .padding()
                    //.premiumCardBackground(cornerRadius: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                    )
                    .liquidGlassBorder(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // 4. Dynamic Water Ratio / Weight Card
                    VStack(alignment: .leading, spacing: 14) {
                        if selectedMethod == .v60 || selectedMethod == .chemex {
                            HStack {
                                Text("WATER RATIO")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .tracking(1.0)
                                Spacer()
                                Text(String(format: "1:%.1f", ratio))
                                    .font(.headline)
                                    .foregroundStyle(Color.primaryCopper)
                            }
                            
                            Slider(value: $ratio, in: 12.0...20.0, step: 0.5)
                                .tint(Color.primaryCopper)
                            
                            HStack {
                                Text("1:12")
                                Spacer()
                                Text("1:20")
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                        } else {
                            HStack {
                                Text("TARGET WATER VOLUME")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .tracking(1.0)
                                Spacer()
                                Text("\(Int(waterVolume))g")
                                    .font(.headline)
                                    .foregroundStyle(Color.primaryCopper)
                            }
                            
                            Slider(value: $waterVolume, in: 100.0...600.0, step: 10.0)
                                .tint(Color.primaryCopper)
                            
                            HStack {
                                Text("100g")
                                Spacer()
                                Text("600g")
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding()
                   // .premiumCardBackground(cornerRadius: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                    )
                    .liquidGlassBorder(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // 5. Target Temperature (Horizontal scrolling Ruler)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("TARGET TEMPERATURE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(1.0)
                            Spacer()
                            Text(String(format: "%.1f°C", targetTemperature))
                                .font(.headline)
                                .foregroundStyle(Color.primaryCopper)
                        }
                        
                        RulerPicker(value: $targetTemperature, range: 75.0...100.0, step: 0.5)
                            .padding(.vertical, 8)
                    }
                    .padding()
                  //  .premiumCardBackground(cornerRadius: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                    )
                    .liquidGlassBorder(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // 6. Dynamic Pre-infusion / Steep Options Card
                    VStack(alignment: .leading, spacing: 14) {
                        if selectedMethod == .v60 || selectedMethod == .chemex {
                            Toggle(isOn: $preInfusionActive) {
                                Text("Pre-infusion Timer")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .tint(Color.primaryCopper)
                            
                            if preInfusionActive {
                                HStack {
                                    Text("BLOOM DURATION")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.4))
                                    Spacer()
                                    Text("\(Int(preInfusionDuration))s")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primaryCopper)
                                }
                                
                                Slider(value: $preInfusionDuration, in: 30.0...60.0, step: 5.0)
                                    .tint(Color.primaryCopper)
                            }
                        } else {
                            HStack {
                                Text("STEEP DURATION")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .tracking(1.0)
                                Spacer()
                                Text("\(Int(steepDuration))s")
                                    .font(.headline)
                                    .foregroundStyle(Color.primaryCopper)
                            }
                            
                            Slider(value: $steepDuration, in: 10.0...480.0, step: 5.0)
                                .tint(Color.primaryCopper)
                            
                            HStack {
                                Text("10s")
                                Spacer()
                                Text("8m")
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                            
                            if selectedMethod == .aeropress {
                                Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)
                                
                                HStack {
                                    Text("PRESS DURATION")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.0)
                                    Spacer()
                                    Text("\(Int(pressDuration))s")
                                        .font(.headline)
                                        .foregroundStyle(Color.primaryCopper)
                                }
                                
                                Slider(value: $pressDuration, in: 10.0...60.0, step: 5.0)
                                    .tint(Color.primaryCopper)
                                
                                HStack {
                                    Text("10s")
                                    Spacer()
                                    Text("60s")
                                }
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }
                    .padding()
                //    .premiumCardBackground(cornerRadius: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                    )
                    .liquidGlassBorder(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // 7. General Settings
      //              VStack(spacing: 16) {
//                        Toggle(isOn: $hapticFeedbackEnabled) {
//                            HStack(spacing: 12) {
//                                Image(systemName: "iphone.radiowaves.left.and.right")
//                                    .foregroundStyle(Color.primaryCopper)
//                                Text("Haptic Feedback")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.white)
//                            }
//                        }
//                        .tint(Color.primaryCopper)
//                        
//                        Divider().background(Color.white.opacity(0.1))
//                        
//                        Toggle(isOn: $autoSyncEnabled) {
//                            HStack(spacing: 12) {
//                                Image(systemName: "icloud.and.arrow.up")
//                                    .foregroundStyle(Color.primaryCopper)
//                                Text("Auto-sync History")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.white)
//                            }
//                        }
//                        .tint(Color.primaryCopper)
//                    }
//                    .padding()
//                //    .premiumCardBackground(cornerRadius: 16)
//                    .background(
//                        RoundedRectangle(cornerRadius: 16)
//                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
//                    )
//                    .padding(.horizontal)
                    
                    // Recipe Name Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RECIPE NAME")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.0)
                        
                        TextField("Recipe Name", text: $recipeName)
                            .font(.system(.title2, design: .serif))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                    )
                    .liquidGlassBorder(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // 8. Save Button
                    Button {
                        saveTemplate()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("SAVE TEMPLATE")
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
                    .padding(.bottom, 40)
                }
                .padding(.top)
                .premiumCardBackground(cornerRadius: 16)
            }
            .sheet(isPresented: $showTemplatesSheet) {
                TemplatesListView()
            }
        }
    }
    
    var isSaveDisabled: Bool {
        recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTemplate() {
        let isV60OrChemex = (selectedMethod == .v60 || selectedMethod == .chemex)
        
        let finalPreInfusionActive = isV60OrChemex ? preInfusionActive : false
        let finalPreInfusionDuration = isV60OrChemex ? preInfusionDuration : 0.0
        let finalSteepDuration = isV60OrChemex ? 0.0 : steepDuration
        let finalPressDuration = selectedMethod == .aeropress ? pressDuration : (selectedMethod == .frenchPress ? 15.0 : 0.0)
        
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
        try? modelContext.save()
        
        // Navigate back to the Home tab
        withAnimation {
            selectedTab = .brew
        }
    }
}

struct TemplatesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BrewTemplate.createdAt, order: .forward) private var templates: [BrewTemplate]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08)
                    .ignoresSafeArea()
                
                if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Recipes", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text("Your saved recipe templates will appear here.")
                    }
                    .foregroundStyle(.white)
                } else {
                    List {
                        ForEach(templates) { template in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        
                                        Text(template.method.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.08))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.primaryCopper)
                                            )
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Label(String(format: "%.1fg", template.beanWeight), systemImage: "scalemass.fill")
                                        
                                        if template.method == .v60 || template.method == .chemex {
                                            Label(String(format: "1:%.1f", template.ratio), systemImage: "drop.fill")
                                        } else {
                                            Label("\(Int(template.waterVolume))g", systemImage: "drop.fill")
                                        }
                                        
                                        Label(String(format: "%.1f°C", template.targetTemperature), systemImage: "thermometer.medium")
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
                                    modelContext.delete(template)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(Color.primaryCopper)
                }
            }
        }
    }
}
