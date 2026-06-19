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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        if !logs.isEmpty {
                            graphSection
                        }
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
            Text("Your brew lab is ready.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bean Usage History (g)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(logs) { log in
                    BarMark(x: .value("Time", log.timestamp),
                            y: .value("Beans (g)", animateChart ? log.beanWeightGram : 0.0))
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .animation(.interactiveSpring(response: 0.8, dampingFraction: 0.7, blendDuration: 0), value: animateChart)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            if logs.isEmpty {
                Text("No logs yet, tap '+' to brew")
                    .foregroundStyle(.secondary)
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
                Text("1:\(Int(log.ratio)) Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.1f", log.beanWeightGram))g")
                    .fontWeight(.semibold)
                Text("\(String(format: "%.0f", log.totalWaterWeight))g water")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
