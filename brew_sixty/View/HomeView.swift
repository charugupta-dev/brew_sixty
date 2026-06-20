//
//  HomeView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI
import Charts
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\BrewLog.timestamp, order: .reverse)]) private var logs: [BrewLog]
    @State private var showingBrewForm = false
    @State private var animateChart = false
    
    private var todayLogs: [BrewLog] {
        logs.filter { Calendar.current.isDateInToday($0.timestamp) }.reversed()
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                RadialGradient.coffeeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        graphSection
                        brewLogSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
                
                fab
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingBrewForm) {
                BrewFormView()
                    .presentationDetents([.fraction(0.65)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(uiColor: .systemBackground))
            }
        }
    }
}


extension HomeView {
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello Charu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Your brew lab is ready.")
                    .font(.subheadline)
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
            }
            
            Spacer()
            
            Button {
                // Placeholder action
            } label: {
                Image(systemName: "coffeeholder")
                    .foregroundStyle(Color.coffeeCream)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEAN USAGE HISTORY (G)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.coffeeCream.opacity(0.5))
                .tracking(1.0)
            
            if todayLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer")
                        .font(.title)
                        .foregroundStyle(Color.coffeeCream.opacity(0.3))
                    Text("No brews recorded today yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.coffeeCream.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart {
                    ForEach(todayLogs) { log in
                        BarMark(x: .value("Time", log.timestamp.formatted(date: .omitted, time: .shortened)),
                                y: .value("Beans (g)", animateChart ? log.beanWeightGram : 0.0))
                        .foregroundStyle(Color.coffeePeach)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .animation(.easeOut(duration: 1.5), value: animateChart)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.10, green: 0.08, blue: 0.08))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation {
                animateChart = true
            }
        }
    }
    
    private var brewLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Brews")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeCream)
                
                Spacer()
                
                Button {
                    // Placeholder action
                } label: {
                    Text("VIEW ALL")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.coffeePeach)
                }
            }
            
            if logs.isEmpty {
                Text("No logs yet, tap '+' to brew")
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(logs) { log in
                        logRow(for: log)
                    }
                }
            }
        }
    }
    
    private func logRow(for log: BrewLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(String(format: "1:%d Ratio • %@", Int(log.ratio), log.timestamp.formatted(Date.FormatStyle().month(.abbreviated).day(.defaultDigits))))
                    .font(.caption)
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1fg", log.beanWeightGram))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeePeach)
                
                Text(String(format: "%.0fg water", log.totalWaterWeight))
                    .font(.caption)
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(log)
                try? modelContext.save()
            } label: {
                Label("Delete Log", systemImage: "trash")
            }
        }
    }
    
    private var fab: some View {
        Button {
            showingBrewForm = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.10, green: 0.08, blue: 0.09))
                .frame(width: 60, height: 60)
                .background(Color.coffeePeach)
                .clipShape(Circle())
                .shadow(radius: 50, y: 5)
        }
        .padding(24)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
