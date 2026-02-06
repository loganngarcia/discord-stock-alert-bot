//
//  Stock.swift
//  Stockup
//
//  Created by Assistant
//

import Foundation

struct Stock: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let companyName: String
    let currentPrice: Double
    let percentChange: Double
    let analystTarget: Double
    let twelveMonthAvg: Double
    let marketCap: Double
    let logoURL: URL?
    
    // Computed property for sorting by Diff
    var diffPercentage: Double {
        return ((analystTarget - currentPrice) / currentPrice) * 100
    }
    
    init(symbol: String, companyName: String, currentPrice: Double, percentChange: Double, analystTarget: Double, twelveMonthAvg: Double, marketCap: Double, logoURL: URL?) {
        self.id = UUID()
        self.symbol = symbol
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.percentChange = percentChange
        self.analystTarget = analystTarget
        self.twelveMonthAvg = twelveMonthAvg
        self.marketCap = marketCap
        self.logoURL = logoURL
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol, companyName, currentPrice, percentChange, analystTarget, twelveMonthAvg, marketCap, logoURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.companyName = try container.decode(String.self, forKey: .companyName)
        self.currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        self.percentChange = try container.decode(Double.self, forKey: .percentChange)
        self.analystTarget = try container.decode(Double.self, forKey: .analystTarget)
        self.twelveMonthAvg = try container.decode(Double.self, forKey: .twelveMonthAvg)
        self.marketCap = try container.decode(Double.self, forKey: .marketCap)
        self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
    }
}
