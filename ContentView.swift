//
//  ContentView.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI
import AppKit

enum TimePeriod: String, CaseIterable {
    case live = "LIVE"
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
    @AppStorage("selectedTimePeriod") private var selectedTimePeriod: String = TimePeriod.oneDay.rawValue
    @State private var sortOrder = [KeyPathComparator(\Stock.percentChange, order: .reverse)]
    @State private var isChatOpen = false
    @State private var chatInitialMessage = ""
    @State private var chatInputText = ""
    @State private var liveUpdateTimer: Timer?
    
    private func sortedStocks() -> [Stock] {
        var sorted = viewModel.stocks
        sorted.sort(using: sortOrder)
        return sorted
    }
    
    var body: some View {
        ZStack {
            // Dark background color #1E1E1E
            Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0)
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
                    Table(sortedStocks(), sortOrder: $sortOrder) {
                            TableColumn("Name/Symbol") { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    HStack(spacing: 8) {
                                        // Logo - robust multi-API fetching
                                        RobustLogoView(symbol: stock.symbol, companyName: stock.companyName)
                                        
                                        // Name and Symbol
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
                                }
                                .buttonStyle(.plain)
                            }
                            .width(min: 160, ideal: 190)
                            
                            TableColumn("Diff", value: \.diffPercentage) { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    let diffPercent = ((stock.analystTarget - stock.currentPrice) / stock.currentPrice) * 100
                                    Text("\(diffPercent >= 0 ? "+" : "")\(diffPercent, specifier: "%.2f")%")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(diffPercent >= 0 ? .green : .red)
                                }
                                .buttonStyle(.plain)
                            }
                            .width(100)
                            
                            TableColumn("Price", value: \.currentPrice) { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    Text("$\(stock.currentPrice, specifier: "%.2f")")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .width(100)
                            
                            TableColumn("Analyst", value: \.analystTarget) { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    Text("$\(stock.analystTarget, specifier: "%.2f")")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .width(100)
                            
                            TableColumn("Mkt Cap", value: \.marketCap) { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    Text(formatMarketCap(stock.marketCap))
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .width(120)
                            
                            TableColumn("% Chng", value: \.percentChange) { stock in
                                Button(action: {
                                    addStockMention(stock.symbol)
                                }) {
                                    Text("\(stock.percentChange >= 0 ? "+" : "")\(stock.percentChange, specifier: "%.2f")%")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .width(100)
                    }
                    .tableStyle(.inset(alternatesRowBackgrounds: false))
                    .scrollContentBackground(.hidden) // Hide default table background
                    .background(Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0))
                }
            }
            
            // Floating chat bar at bottom center (only visible when overlay is closed)
            if !isChatOpen {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingChatBar(isChatOpen: $isChatOpen, initialMessage: $chatInitialMessage, inputText: $chatInputText)
                            .padding(.horizontal, 20) // Margins for mobile-friendly layout
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .overlay {
            if isChatOpen {
                ZStack {
                    // Fullscreen chat overlay
                    ChatOverlayView(
                        isPresented: $isChatOpen,
                        stockViewModel: viewModel,
                        initialMessage: chatInitialMessage,
                        chatInputText: $chatInputText,
                        chatInitialMessage: $chatInitialMessage
                    )
                    
                    // Floating chat bar on top when overlay is open (higher z-index)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingChatBar(isChatOpen: $isChatOpen, initialMessage: $chatInitialMessage, inputText: $chatInputText)
                                .padding(.horizontal, 20) // Margins for mobile-friendly layout
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    .zIndex(1001) // Higher than overlay
                }
                .zIndex(1000)
                .onAppear {
                    // Clear initial message after opening to prevent resending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        chatInitialMessage = ""
                    }
                }
            }
        }
        .onAppear {
            // Use NSWindow to add title bar accessory view
            setupTitleBarControls()
        }
        .onChange(of: chatInitialMessage) {
            // Handle messages sent from FloatingChatBar when overlay is open
            if isChatOpen && !chatInitialMessage.isEmpty {
                // This will be handled by ChatOverlayView's onChange
            }
        }
        .onChange(of: selectedTimePeriod) {
            // Start/stop live updates when period changes
            if selectedTimePeriod == TimePeriod.live.rawValue {
                startLiveUpdates()
            } else {
                stopLiveUpdates()
            }
        }
        .task {
            await viewModel.loadStocks()
            // Start live updates if LIVE is selected
            if selectedTimePeriod == TimePeriod.live.rawValue {
                startLiveUpdates()
            }
        }
        .onDisappear {
            stopLiveUpdates()
        }
    }
    
    private func startLiveUpdates() {
        stopLiveUpdates() // Stop any existing timer
        
        // Update immediately
        Task {
            await viewModel.loadStocks()
        }
        
        // Then update every 60 seconds
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                await viewModel.loadStocks()
            }
        }
    }
    
    private func stopLiveUpdates() {
        liveUpdateTimer?.invalidate()
        liveUpdateTimer = nil
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
    
    // Add stock mention to chat input
    private func addStockMention(_ symbol: String) {
        let mention = "@\(symbol)"
        if chatInputText.isEmpty {
            chatInputText = mention
        } else {
            // Add space if needed and append mention
            if !chatInputText.hasSuffix(" ") {
                chatInputText += " "
            }
            chatInputText += mention
        }
    }
    
    // Setup title bar controls using NSTitlebarAccessoryViewController
    private func setupTitleBarControls() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else {
                // Retry if window not ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setupTitleBarControls()
                }
                return
            }
            
            // Remove window title
            window.title = ""
            
            // Remove any existing accessory views
            while window.titlebarAccessoryViewControllers.count > 0 {
                window.removeTitlebarAccessoryViewController(at: 0)
            }
            
            // Create SwiftUI view for time period selector
            let timePeriodView = TitleBarTimePeriodSelector(
                selectedTimePeriod: Binding(
                    get: { self.selectedTimePeriod },
                    set: { newValue in
                        self.selectedTimePeriod = newValue
                        if let period = TimePeriod.allCases.first(where: { $0.rawValue == newValue }) {
                            self.viewModel.updateTimePeriod(period)
                            if period == .live {
                                self.startLiveUpdates()
                            } else {
                                self.stopLiveUpdates()
                            }
                        }
                    }
                ),
                onPeriodChange: { period in
                    self.viewModel.updateTimePeriod(period)
                    if period == .live {
                        self.startLiveUpdates()
                    } else {
                        self.stopLiveUpdates()
                    }
                }
            )
            
            let hostingView = NSHostingView(rootView: timePeriodView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 22)
            
            let accessoryViewController = NSTitlebarAccessoryViewController()
            accessoryViewController.view = hostingView
            accessoryViewController.layoutAttribute = .leading // Position next to traffic lights
            accessoryViewController.fullScreenMinHeight = 0
            
            window.addTitlebarAccessoryViewController(accessoryViewController)
        }
    }
}

// Removed VisualEffectView - using native .glassEffect() modifier for macOS 26

// Robust logo view that tries multiple APIs sequentially with local caching
struct RobustLogoView: View {
    let symbol: String
    let companyName: String
    @State private var currentURLIndex = 0
    @State private var cachedImageURL: URL?
    @State private var isLoading = true
    
    private var logoURLs: [URL] {
        let upperSymbol = symbol.uppercased()
        var urls: [URL] = []
        
        // Generate all possible logo URLs from multiple APIs
        // Strategy 1: IEX Cloud (most reliable)
        if let url = URL(string: "https://storage.googleapis.com/iex/api/logos/\(upperSymbol).png") {
            urls.append(url)
        }
        
        // Strategy 2: EOD Historical Data
        if let url = URL(string: "https://eodhistoricaldata.com/img/logos/US/\(upperSymbol).png") {
            urls.append(url)
        }
        
        // Strategy 3: LogoKit
        if let url = URL(string: "https://img.logokit.com/ticker/\(upperSymbol).png") {
            urls.append(url)
        }
        if let url = URL(string: "https://img.logokit.com/ticker/\(upperSymbol)") {
            urls.append(url)
        }
        
        // Strategy 4: Clearbit with smart domain extraction
        if let domain = extractDomainFromCompanyName(companyName, symbol: upperSymbol) {
            if let url = URL(string: "https://logo.clearbit.com/\(domain)") {
                urls.append(url)
            }
        }
        
        // Strategy 5: Try variations of company name for Clearbit
        let nameVariations = generateDomainVariations(companyName)
        for domain in nameVariations {
            if let url = URL(string: "https://logo.clearbit.com/\(domain)") {
                urls.append(url)
            }
        }
        
        // Strategy 6: Parqet API
        if let url = URL(string: "https://www.parqet.com/api/logos/\(upperSymbol).png") {
            urls.append(url)
        }
        
        return urls
    }
    
    var body: some View {
        Group {
            // First, try cached logo
            if let cachedURL = cachedImageURL {
                AsyncImage(url: cachedURL) { phase in
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
                        // Cache failed, try APIs
                        tryAPIs()
                    @unknown default:
                        tryAPIs()
                    }
                }
            } else if isLoading {
                // Try APIs
                tryAPIs()
            } else {
                // All failed
                Image(systemName: "building.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
        }
        .onAppear {
            loadCachedLogo()
        }
    }
    
    @ViewBuilder
    private func tryAPIs() -> some View {
        if currentURLIndex < logoURLs.count {
            AsyncImage(url: logoURLs[currentURLIndex]) { phase in
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
                        .onAppear {
                            // Cache the successful logo
                            cacheLogo(from: logoURLs[currentURLIndex])
                        }
                case .failure(_):
                    // Try next URL after a short delay
                    if currentURLIndex + 1 < logoURLs.count {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 24, height: 24)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    currentURLIndex += 1
                                }
                            }
                    } else {
                        // All URLs failed
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .onAppear {
                                isLoading = false
                            }
                    }
                @unknown default:
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .onAppear {
                            isLoading = false
                        }
                }
            }
            .id(currentURLIndex) // Force re-render when index changes
        } else {
            Image(systemName: "building.2.fill")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
        }
    }
    
    private func loadCachedLogo() {
        let cacheDir = getLogoCacheDirectory()
        let cachedFileURL = cacheDir.appendingPathComponent("\(symbol.uppercased()).png")
        
        if FileManager.default.fileExists(atPath: cachedFileURL.path) {
            cachedImageURL = cachedFileURL
            isLoading = false
        } else {
            isLoading = true
        }
    }
    
    private func cacheLogo(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = NSImage(data: data) {
                    // Resize to tiny version (48x48 is enough for 24x24 display)
                    let resizedImage = resizeImage(image, to: NSSize(width: 48, height: 48))
                    if let pngData = resizedImage.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }) {
                        let cacheDir = getLogoCacheDirectory()
                        let cachedFileURL = cacheDir.appendingPathComponent("\(symbol.uppercased()).png")
                        try pngData.write(to: cachedFileURL)
                        await MainActor.run {
                            cachedImageURL = cachedFileURL
                        }
                    }
                }
            } catch {
                // Silent fail - just don't cache
            }
        }
    }
    
    private func getLogoCacheDirectory() -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let logoCacheDir = cacheDir.appendingPathComponent("com.stockup.app/logos")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: logoCacheDir, withIntermediateDirectories: true)
        
        return logoCacheDir
    }
    
    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver,
                   fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }
    
    private func extractDomainFromCompanyName(_ companyName: String, symbol: String) -> String? {
        // Remove common corporate suffixes
        var cleaned = companyName
            .replacingOccurrences(of: ", Inc.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Inc.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Inc", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", Corp.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Corp.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Corporation", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", LLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " LLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", Ltd.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Ltd.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", L.P.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " L.P.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", LP", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " LP", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", PLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " PLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", AG", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " AG", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", SA", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " SA", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", NV", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " NV", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        // Convert to domain format
        let domain = cleaned
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "&", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
        
        if domain.count > 2 && domain.allSatisfy({ $0.isLetter || $0.isNumber }) {
            return "\(domain).com"
        }
        
        // Symbol-based fallbacks for known companies
        let symbolDomains: [String: String] = [
            "RBLX": "roblox.com",
            "OKLO": "oklo.com",
            "COREWEAVE": "coreweave.com",
            "DWAVE": "dwavesys.com",
            "QBTS": "quantumcomputing.com", // D-Wave Quantum ticker
            "PONY": "pony.ai"
        ]
        return symbolDomains[symbol]
    }
    
    private func generateDomainVariations(_ companyName: String) -> [String] {
        var variations: [String] = []
        
        // Remove suffixes and clean
        let cleaned = companyName
            .replacingOccurrences(of: ", Inc.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Inc.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", Corp.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Corp.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Corporation", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", LLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " LLC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ", Ltd.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Ltd.", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        // Try full name
        let fullDomain = cleaned.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "&", with: "")
            .replacingOccurrences(of: "-", with: "")
        if fullDomain.count > 2 {
            variations.append("\(fullDomain).com")
        }
        
        // Try first word only
        if let firstWord = cleaned.components(separatedBy: " ").first?.lowercased(),
           firstWord.count > 2 {
            variations.append("\(firstWord).com")
        }
        
        // Try without common words
        let words = cleaned.components(separatedBy: " ")
            .filter { !["the", "and", "of", "for", "in", "on", "at", "to", "a", "an"].contains($0.lowercased()) }
        if let mainWord = words.first?.lowercased(), mainWord.count > 2 {
            variations.append("\(mainWord).com")
        }
        
        return variations
    }
}

// Title bar time period selector view with liquid glass effect
struct TitleBarTimePeriodSelector: View {
    @Binding var selectedTimePeriod: String
    let onPeriodChange: (TimePeriod) -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimePeriod.allCases, id: \.rawValue) { period in
                Button(action: {
                    selectedTimePeriod = period.rawValue
                    onPeriodChange(period)
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 11, weight: selectedTimePeriod == period.rawValue ? .semibold : .regular))
                        .foregroundStyle(selectedTimePeriod == period.rawValue ? .white : Color(white: 0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Group {
                                if selectedTimePeriod == period.rawValue {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 24, height: 24)
                                        .glassEffect(in: .circle)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.clear)
        .glassEffect(in: .capsule)
        .padding(.leading, 8)
    }
}

#Preview {
    ContentView()
}
