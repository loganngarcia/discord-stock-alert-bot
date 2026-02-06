//
//  StockRowView.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI

struct StockRowView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row 1: Logo + Company Name & Ticker
            HStack(alignment: .center, spacing: 12) {
                // Brand logo (36x36px circle with grey bg)
                // Using IEX Cloud Logo API (free, no API key needed)
                if let logoURL = stock.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 36, height: 36)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(Color(white: 0.5, opacity: 0.1), lineWidth: 0.5)
                                }
                                .background {
                                    Circle()
                                        .fill(Color(white: 0.5, opacity: 0.05))
                                }
                        case .failure(_):
                            // Fallback icon if logo fails to load
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle()
                                        .fill(Color(white: 0.5, opacity: 0.2))
                                }
                        @unknown default:
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle()
                                        .fill(Color(white: 0.5, opacity: 0.2))
                                }
                        }
                    }
                } else {
                    // No logo URL available
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(Color(white: 0.5, opacity: 0.2))
                        }
                }
                
                // Company name and ticker
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.companyName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(stock.symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Row 2: CHANGE | DIFF | ANALYST | PRICE | MKT CAP (all in one row)
            HStack(spacing: 16) {
                // CHANGE
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHANGE")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("\(stock.percentChange >= 0 ? "+" : "")\(stock.percentChange, specifier: "%.1f")%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(stock.percentChange >= 0 ? .green : .red)
                }
                
                // DIFF
                VStack(alignment: .leading, spacing: 2) {
                    Text("DIFF")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    let diffPercent = ((stock.analystTarget - stock.currentPrice) / stock.currentPrice) * 100
                    Text("\(diffPercent >= 0 ? "+" : "")\(diffPercent, specifier: "%.1f")%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(diffPercent >= 0 ? .green : .red)
                }
                
                // ANALYST
                VStack(alignment: .leading, spacing: 2) {
                    Text("ANALYST")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("$\(stock.analystTarget, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // PRICE
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRICE")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("$\(stock.currentPrice, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // MKT CAP
                VStack(alignment: .leading, spacing: 2) {
                    Text("MKT CAP")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(formatMarketCap(stock.marketCap))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
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

#Preview {
    StockRowView(stock: Stock(
        symbol: "AAPL",
        companyName: "Apple Inc.",
        currentPrice: 175.50,
        percentChange: 2.5,
        analystTarget: 180.00,
        twelveMonthAvg: 170.00,
        marketCap: 2_800_000_000_000,
        logoURL: URL(string: "https://logo.clearbit.com/apple.com")
    ))
    .padding()
}
