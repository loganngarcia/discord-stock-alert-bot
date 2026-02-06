//
//  ContentView.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI

enum TimePeriod: String, CaseIterable {
    case fiveMinutes = "5MINS"
    case oneHour = "1H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case ytd = "YTD"
    case oneYear = "1YR"
    case fiveYears = "5YR"
    case max = "MAX"
}

enum SortColumn: String, CaseIterable {
    case percentChange = "% Chng"
    case diff = "Diff"
    case price = "Price"
    case analyst = "Analyst"
    case marketCap = "Mkt Cap"
}

struct ContentView: View {
    @StateObject private var viewModel = StockViewModel()
    @AppStorage("thresholdPercentage") private var thresholdPercentage: Double = 0.0
    @AppStorage("selectedTimePeriod") private var selectedTimePeriod: String = TimePeriod.oneDay.rawValue
    @State private var sortOrder = [KeyPathComparator(\Stock.percentChange, order: .reverse)]
    
    private func sortedFilteredStocks(threshold: Double) -> [Stock] {
        let filtered = viewModel.filteredStocks(threshold: threshold)
        var sorted = filtered
        sorted.sort(using: sortOrder)
        return sorted
    }
    
    var body: some View {
        ZStack {
            // Liquid glass background - using native macOS visual effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Stock list - Table format
                if viewModel.stocks.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading stocks...")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    let filtered = viewModel.filteredStocks(threshold: thresholdPercentage)
                    if filtered.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No stocks meet the \(Int(thresholdPercentage))%+ threshold")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text("Try lowering the threshold")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                            Text("(Showing \(viewModel.stocks.count) total stocks)")
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        Table(sortedFilteredStocks(threshold: thresholdPercentage), sortOrder: $sortOrder) {
                            TableColumn("") { stock in
                                // Logo
                                if let logoURL = stock.logoURL {
                                    AsyncImage(url: logoURL) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .scaleEffect(0.6)
                                                .frame(width: 24, height: 24)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 24, height: 24)
                                                .clipShape(Circle())
                                        case .failure(_):
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 24, height: 24)
                                        @unknown default:
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                } else {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .width(40)
                            
                            TableColumn("Name/Symbol") { stock in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stock.companyName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(stock.symbol)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .width(min: 120, ideal: 150)
                            
                            TableColumn("Diff", value: \.diffPercentage) { stock in
                                let diffPercent = ((stock.analystTarget - stock.currentPrice) / stock.currentPrice) * 100
                                Text("\(diffPercent >= 0 ? "+" : "")\(diffPercent, specifier: "%.2f")%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(diffPercent >= 0 ? .green : .red)
                            }
                            .width(100)
                            
                            TableColumn("Price", value: \.currentPrice) { stock in
                                Text("$\(stock.currentPrice, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .width(100)
                            
                            TableColumn("Analyst", value: \.analystTarget) { stock in
                                Text("$\(stock.analystTarget, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .width(100)
                            
                            TableColumn("Mkt Cap", value: \.marketCap) { stock in
                                Text(formatMarketCap(stock.marketCap))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .width(120)
                            
                            TableColumn("% Chng", value: \.percentChange) { stock in
                                Text("\(stock.percentChange >= 0 ? "+" : "")\(stock.percentChange, specifier: "%.2f")%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .width(100)
                        }
                        .tableStyle(.inset(alternatesRowBackgrounds: false))
                        .padding(.top, 50)
                    }
                }
            }
            
            // Floating segmented control at top - truly floating, no container
            VStack {
                Picker("", selection: $selectedTimePeriod) {
                    ForEach(TimePeriod.allCases, id: \.rawValue) { period in
                        Text(period.rawValue).tag(period.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 600) // Fixed width, not full width
                .padding(.top, 12)
                .onChange(of: selectedTimePeriod) { newValue in
                    if let period = TimePeriod.allCases.first(where: { $0.rawValue == newValue }) {
                        viewModel.updateTimePeriod(period)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Floating threshold slider pill at bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("\(Int(thresholdPercentage))%+")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        Slider(value: $thresholdPercentage, in: 0...20, step: 1)
                            .frame(width: 200)
                            .onChange(of: thresholdPercentage) { newValue in
                                viewModel.updateThreshold(newValue)
                            }
                            .onAppear {
                                viewModel.updateThreshold(thresholdPercentage)
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .task {
            await viewModel.loadStocks()
        }
    }
    
    // Helper function for market cap formatting
    private func formatMarketCap(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.2fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// Native macOS visual effect view for liquid glass
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
