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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {

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
            .navigationBarHidden(true)
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
        } .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Chart {
                ForEach(logs) { log in
                    BarMark(x: .value("Time", log.timestamp, unit: .day),
                            y: .value("Beans (g)", log.beanWeightGram))
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var brewLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Brews")
                .font(.headline)
            if(logs.isEmpty) {
                Text("No logs yet, tap '+' to brew")
                    .foregroundStyle(.secondary)
                    .padding(.vertical,20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(logs) {log in
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
