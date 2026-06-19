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
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello Charu")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.coffeeCream)
            Text("Your brew lab is ready.")
                .font(.subheadline)
                .foregroundStyle(Color.coffeeCream.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bean Usage History (g)")
                .font(.subheadline)
                .foregroundStyle(Color.coffeeCream.opacity(0.6))
                .fontWeight(.semibold)
            
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
                        .foregroundStyle(Color.coffeeAccent)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .animation(.easeOut(duration: 1.5), value: animateChart)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation {
                animateChart = true
            }
        }
    }
    
    private var brewLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Brews")
                .font(.headline)
                .foregroundStyle(Color.coffeeCream)
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
            VStack(alignment: .leading) {
                Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.coffeeCream)
                Text("1:\(Int(log.ratio)) Ratio")
                    .font(.caption)
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.1f", log.beanWeightGram))g")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.coffeeCream)
                Text("\(String(format: "%.0f", log.totalWaterWeight))g water")
                    .font(.caption)
                    .foregroundStyle(Color.coffeeCream.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var fab: some View {
        Button {
            showingBrewForm = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.primary)
                .clipShape(Circle())
                .shadow(radius: 10, y: 5)
        }
        .padding(24)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
