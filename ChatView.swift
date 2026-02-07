//
//  ChatView.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI
import FoundationModels
import Speech
import AppKit
import AVFoundation
import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    
    // Reference to stock data for contextual responses
    weak var stockViewModel: StockViewModel?
    
    // Apple Foundation Models session
    private var languageModelSession: LanguageModelSession?
    
    init(stockViewModel: StockViewModel? = nil) {
        self.stockViewModel = stockViewModel
        
        // Initialize Foundation Models session with stock-focused instructions
        if #available(macOS 26.0, *) {
            let instructions = """
            You are an expert stock market assistant for Stockup, a real-time stock monitoring app.
            
            Your primary role is to provide:
            1. **Stock Comparisons**: Compare multiple stocks (@SYMBOL mentions) on metrics like price, growth, market cap, analyst targets, and risk. Highlight key differences and similarities.
            
            2. **Price Analysis & Guidance**: Explain price movements, trends, and whether current prices represent good entry/exit points. Consider analyst targets vs current prices.
            
            3. **Investment Guidance**: Provide thoughtful, balanced advice on buying, selling, or holding stocks. Always mention risks and never give financial advice without disclaimers.
            
            4. **Market Insights**: Analyze sector trends, market conditions, and how individual stocks fit into broader market movements.
            
            5. **Analyst Interpretation**: Explain what analyst targets mean, whether they're realistic, and how they compare to current prices.
            
            6. **Portfolio Context**: Help users understand how stocks complement each other, diversification benefits, and portfolio balance.
            
            Guidelines:
            - When users mention stocks with @SYMBOL format, use that exact symbol and reference the stock data available in the app
            - Be concise but informative - users want actionable insights, not essays
            - Always format numbers clearly: $1,234.56, 5.2%, 1.2B market cap
            - Compare stocks side-by-side when multiple are mentioned
            - Highlight both opportunities and risks
            - Use the context provided about top movers and current market data
            - If you don't have specific data, provide general guidance based on market knowledge
            - Be friendly and conversational, but professional
            - Never guarantee returns or make absolute predictions
            """
            self.languageModelSession = LanguageModelSession(instructions: instructions)
        }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let currentInput = inputText
        inputText = ""
        isProcessing = true
        
        Task {
            await processMessage(currentInput)
        }
    }
    
    private func processMessage(_ input: String) async {
        if #available(macOS 26.0, *) {
            // Check if Foundation Models is available
            guard let session = languageModelSession else {
                await generateIntelligentResponse(input)
                return
            }
            
            // Enhance prompt with stock context if available
            var enhancedPrompt = input
            if let stocks = stockViewModel?.stocks, !stocks.isEmpty {
                let topMovers = stocks.sorted { $0.percentChange > $1.percentChange }.prefix(5)
                let moverInfo = topMovers.map { "\($0.symbol): $\(String(format: "%.2f", $0.currentPrice)) (\(String(format: "%.2f", $0.percentChange))%)" }.joined(separator: ", ")
                enhancedPrompt += "\n\nContext: Current top movers are \(moverInfo). Use this context when relevant."
            }
            
            do {
                // Use Foundation Models for AI response with streaming
                let responseStream = session.streamResponse(to: enhancedPrompt)
                var fullResponse = ""
                
                // Stream the response incrementally
                for try await snapshot in responseStream {
                    // Get the current text from the snapshot
                    // Snapshot contains the full response so far
                    fullResponse = snapshot.content
                    
                    // Update the last message with streaming content
                    await MainActor.run {
                        if let lastMessage = messages.last, !lastMessage.isUser {
                            // Update existing AI message
                            messages[messages.count - 1] = ChatMessage(
                                content: fullResponse,
                                isUser: false,
                                timestamp: lastMessage.timestamp
                            )
                        } else {
                            // Create new AI message
                            messages.append(ChatMessage(
                                content: fullResponse,
                                isUser: false,
                                timestamp: Date()
                            ))
                        }
                    }
                }
                
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                print("Foundation Models error: \(error)")
                // Fallback to intelligent response
                await generateIntelligentResponse(input)
            }
        } else {
            // Fallback for older macOS versions
            await generateIntelligentResponse(input)
        }
    }
    
    private func generateIntelligentResponse(_ input: String) async {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespaces)
        var response = ""
        
        // Simulate thinking delay for natural feel
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Get stock data for contextual responses
        let stocks = stockViewModel?.stocks ?? []
        
        // Greeting responses
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            response = "Hello! 👋 I'm here to help you understand stocks and market trends.\n\nI can help you:\n• Analyze stock performance\n• Find top movers\n• Understand price trends\n• Compare analyst targets\n\nWhat would you like to know?"
        }
        // Stock-specific queries
        else if lowercased.contains("top") && (lowercased.contains("mover") || lowercased.contains("gain") || lowercased.contains("stock")) {
            let topMovers = stocks.sorted { $0.percentChange > $1.percentChange }.prefix(5)
            if topMovers.isEmpty {
                response = "I'm still loading stock data. Check back in a moment!"
            } else {
                var moverList = "Here are the top movers:\n\n"
                for (index, stock) in topMovers.enumerated() {
                    moverList += "\(index + 1). **\(stock.symbol)** - \(String(format: "%.2f", stock.percentChange))%\n"
                    moverList += "   Price: $\(String(format: "%.2f", stock.currentPrice))\n"
                    moverList += "   Analyst Target: $\(String(format: "%.2f", stock.analystTarget))\n\n"
                }
                response = moverList
            }
        }
        // Price queries
        else if lowercased.contains("price") || lowercased.contains("cost") {
            // Try to extract stock symbol
            let words = lowercased.components(separatedBy: .whitespaces)
            if let symbolWord = words.first(where: { $0.count <= 5 && $0.allSatisfy { $0.isLetter } }),
               let stock = stocks.first(where: { $0.symbol.uppercased() == symbolWord.uppercased() }) {
                response = "**\(stock.symbol)** (\(stock.companyName))\n\n"
                response += "Current Price: $\(String(format: "%.2f", stock.currentPrice))\n"
                response += "Daily Change: \(String(format: "%.2f", stock.percentChange))%\n"
                response += "Analyst Target: $\(String(format: "%.2f", stock.analystTarget))\n"
                response += "Market Cap: \(formatMarketCap(stock.marketCap))\n"
                let diff = ((stock.analystTarget - stock.currentPrice) / stock.currentPrice) * 100
                response += "Upside Potential: \(String(format: "%.1f", diff))%"
            } else {
                response = "I can help you find stock prices! Try asking:\n• \"What's the price of AAPL?\"\n• \"Show me TSLA price\"\n• Or check the table for all current prices"
            }
        }
        // Market cap queries
        else if lowercased.contains("market cap") || lowercased.contains("marketcap") {
            let sortedByCap = stocks.sorted { $0.marketCap > $1.marketCap }.prefix(5)
            if sortedByCap.isEmpty {
                response = "Loading market data..."
            } else {
                var capList = "Largest by Market Cap:\n\n"
                for (index, stock) in sortedByCap.enumerated() {
                    capList += "\(index + 1). **\(stock.symbol)** - \(formatMarketCap(stock.marketCap))\n"
                }
                response = capList
            }
        }
        // Analyst target queries
        else if lowercased.contains("analyst") || lowercased.contains("target") {
            let sortedByDiff = stocks.sorted { 
                abs(($0.analystTarget - $0.currentPrice) / $0.currentPrice) > abs(($1.analystTarget - $1.currentPrice) / $1.currentPrice)
            }.prefix(5)
            if sortedByDiff.isEmpty {
                response = "Loading analyst data..."
            } else {
                var diffList = "Stocks with biggest analyst upside:\n\n"
                for stock in sortedByDiff {
                    let diff = ((stock.analystTarget - stock.currentPrice) / stock.currentPrice) * 100
                    diffList += "**\(stock.symbol)**: \(String(format: "%.1f", diff))% potential\n"
                    diffList += "Current: $\(String(format: "%.2f", stock.currentPrice)) → Target: $\(String(format: "%.2f", stock.analystTarget))\n\n"
                }
                response = diffList
            }
        }
        // Help queries
        else if lowercased.contains("help") || lowercased.contains("what can") {
            response = "I can help you with:\n\n"
            response += "📈 **Top Movers** - \"Show top movers\"\n"
            response += "💰 **Stock Prices** - \"What's the price of AAPL?\"\n"
            response += "📊 **Market Cap** - \"Show largest market caps\"\n"
            response += "🎯 **Analyst Targets** - \"Show analyst targets\"\n"
            response += "📉 **Price Trends** - Ask about specific stocks\n\n"
            response += "You can also browse the table above for all current data!"
        }
        // General stock questions
        else if lowercased.contains("stock") || lowercased.contains("market") || lowercased.contains("invest") {
            response = "I can help you analyze stocks! Here's what I can do:\n\n"
            response += "• Find top gainers and movers\n"
            response += "• Look up specific stock prices\n"
            response += "• Compare analyst targets vs current prices\n"
            response += "• Show market cap rankings\n\n"
            response += "Try asking:\n• \"Show top movers\"\n• \"What's AAPL price?\"\n• \"Show analyst targets\""
        }
        // Default intelligent response
        else {
            response = "I understand you're asking about \"\(input)\".\n\n"
            response += "I'm specialized in helping with stock market questions. I can:\n"
            response += "• Find top movers and gainers\n"
            response += "• Look up stock prices\n"
            response += "• Show analyst targets\n"
            response += "• Compare market caps\n\n"
            response += "Try asking: \"Show top movers\" or \"What's the price of AAPL?\""
        }
        
        // Add streaming effect for natural feel
        await streamResponse(response)
    }
    
    private func streamResponse(_ fullResponse: String) async {
        let words = fullResponse.components(separatedBy: .whitespaces)
        var currentText = ""
        
        for word in words {
            currentText += (currentText.isEmpty ? "" : " ") + word
            await MainActor.run {
                if let lastMessage = messages.last, !lastMessage.isUser {
                    messages[messages.count - 1] = ChatMessage(
                        content: currentText,
                        isUser: false,
                        timestamp: lastMessage.timestamp
                    )
                } else {
                    messages.append(ChatMessage(
                        content: currentText,
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
            // Small delay between words for streaming effect
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms per word
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    private func formatMarketCap(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.2fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else {
            return String(format: "$%.2f", value)
        }
    }
}

struct ChatOverlayView: View {
    @Binding var isPresented: Bool
    @ObservedObject var stockViewModel: StockViewModel
    @StateObject private var chatViewModel: ChatViewModel
    var initialMessage: String
    @Binding var chatInputText: String
    @Binding var chatInitialMessage: String
    
    init(isPresented: Binding<Bool>, stockViewModel: StockViewModel, initialMessage: String = "", chatInputText: Binding<String>, chatInitialMessage: Binding<String>) {
        self._isPresented = isPresented
        self.stockViewModel = stockViewModel
        self.initialMessage = initialMessage
        self._chatInputText = chatInputText
        self._chatInitialMessage = chatInitialMessage
        self._chatViewModel = StateObject(wrappedValue: ChatViewModel(stockViewModel: stockViewModel))
    }
    
    var body: some View {
        ZStack {
            // Background overlay with app background color
            Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0)
                .opacity(0.95)
                .ignoresSafeArea()
            
            // Chat overlay content
            
            VStack(spacing: 0) {
                // Header with new chat and close buttons
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // New chat button (compose icon) - native Liquid Glass button
                        Button(action: {
                            chatViewModel.messages = []
                            chatInputText = ""
                            chatInitialMessage = ""
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                        .buttonStyle(.glass) // Native Liquid Glass button style
                        
                        // Close button - native Liquid Glass button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                        .buttonStyle(.glass) // Native Liquid Glass button style
                    }
                }
                .padding(20)
                .glassEffect(in: .rect(cornerRadius: 0)) // Native Liquid Glass for header
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chatViewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if chatViewModel.isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 20)
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: chatViewModel.messages.count) {
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input bar - will be replaced by FloatingChatBar when overlay is open
                Spacer()
                    .frame(height: 60)
            }
            .background(Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0)) // Dark background for chat overlay
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .onAppear {
            // Send initial message if provided
            if !initialMessage.isEmpty {
                chatViewModel.inputText = initialMessage
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    chatViewModel.sendMessage()
                }
            }
        }
        .onChange(of: chatInitialMessage) {
            // Handle new messages from FloatingChatBar when overlay is already open
            if isPresented && !chatInitialMessage.isEmpty {
                chatViewModel.inputText = chatInitialMessage
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    chatViewModel.sendMessage()
                    chatInitialMessage = ""
                }
            }
        }
    }
}

// Removed ChatVisualEffectView - using native .glassEffect() modifier for macOS 26

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        if message.isUser {
            // User messages: right-aligned with blue bubble
            HStack {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    formatMessage(message.content, isUser: true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Color.blue,
                            in: RoundedRectangle(cornerRadius: 20) // macOS 26 increased corner radius
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        } else {
            // AI messages: full width, no bubble, no background, max 768px
            VStack(alignment: .leading, spacing: 4) {
                formatMessage(message.content, isUser: false)
                    .frame(maxWidth: 768)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private func formatMessage(_ text: String, isUser: Bool) -> some View {
        if isUser {
            // User messages: simple formatting with mentions
            formatUserMessage(text)
        } else {
            // AI messages: full markdown support
            formatAIMessage(text)
        }
    }
    
    @ViewBuilder
    private func formatUserMessage(_ text: String) -> some View {
        // User messages: format mentions only
        let parts = parseMentions(text)
        HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if part.isMention {
                    Text(part.text)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(part.text)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    @ViewBuilder
    private func formatAIMessage(_ text: String) -> some View {
        // AI messages: full markdown support with mentions and tables
        VStack(alignment: .leading, spacing: 8) {
            // Split content into blocks (text, tables, lists)
            let blocks = parseMarkdownBlocks(text)
            
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                switch block {
                case .text(let content):
                    if let attributedString = parseMarkdownWithMentions(content) {
                        Text(attributedString)
                            .textSelection(.enabled)
                    } else {
                        Text(content)
                            .foregroundStyle(.primary)
                    }
                case .table(let rows):
                    renderTable(rows)
                case .list(let items, let ordered):
                    renderList(items, ordered: ordered)
                }
            }
        }
    }
    
    private enum MarkdownBlock {
        case text(String)
        case table([[String]])
        case list([String], ordered: Bool)
    }
    
    private func parseMarkdownBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentText = ""
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // Check for table (starts with |)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                // Flush current text
                if !currentText.isEmpty {
                    blocks.append(.text(currentText.trimmingCharacters(in: .whitespaces)))
                    currentText = ""
                }
                
                // Parse table
                var tableRows: [[String]] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    let row = lines[i].split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                    if !row.isEmpty {
                        tableRows.append(Array(row))
                    }
                    i += 1
                }
                if !tableRows.isEmpty {
                    blocks.append(.table(tableRows))
                }
                continue
            }
            
            // Check for ordered list (starts with number.)
            if let _ = line.range(of: "^\\d+\\.\\s", options: .regularExpression) {
                if !currentText.isEmpty {
                    blocks.append(.text(currentText.trimmingCharacters(in: .whitespaces)))
                    currentText = ""
                }
                var listItems: [String] = []
                while i < lines.count, let range = lines[i].range(of: "^\\d+\\.\\s", options: .regularExpression) {
                    let item = String(lines[i][range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    listItems.append(item)
                    i += 1
                }
                if !listItems.isEmpty {
                    blocks.append(.list(listItems, ordered: true))
                }
                continue
            }
            
            // Check for unordered list (starts with - or *)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("-") || line.trimmingCharacters(in: .whitespaces).hasPrefix("*") {
                if !currentText.isEmpty {
                    blocks.append(.text(currentText.trimmingCharacters(in: .whitespaces)))
                    currentText = ""
                }
                var listItems: [String] = []
                while i < lines.count {
                    let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                        let item = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                        listItems.append(item)
                        i += 1
                    } else {
                        break
                    }
                }
                if !listItems.isEmpty {
                    blocks.append(.list(listItems, ordered: false))
                }
                continue
            }
            
            currentText += line + "\n"
            i += 1
        }
        
        // Add remaining text
        if !currentText.isEmpty {
            blocks.append(.text(currentText.trimmingCharacters(in: .whitespaces)))
        }
        
        return blocks.isEmpty ? [.text(text)] : blocks
    }
    
    @ViewBuilder
    private func renderTable(_ rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                        if rowIndex == 0 {
                            // Header row
                            Text(cell)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            // Data row
                            if let attributedCell = parseMarkdownWithMentions(cell) {
                                Text(attributedCell)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(cell)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                
                if rowIndex == 0 {
                    Divider()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func renderList(_ items: [String], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    if ordered {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("•")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let attributedItem = parseMarkdownWithMentions(item) {
                        Text(attributedItem)
                            .textSelection(.enabled)
                    } else {
                        Text(item)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func parseMarkdownWithMentions(_ text: String) -> AttributedString? {
        do {
            // First, replace mentions with markdown bold syntax, then parse
            var processedText = text
            let mentionPattern = "@([A-Z0-9.]+)"
            if let regex = try? NSRegularExpression(pattern: mentionPattern, options: []) {
                let nsString = processedText as NSString
                let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: nsString.length))
                
                // Replace mentions with markdown bold syntax
                for match in matches.reversed() {
                    let mention = nsString.substring(with: match.range)
                    // Replace @SYMBOL with **@SYMBOL** for bold formatting
                    processedText = (processedText as NSString).replacingCharacters(in: match.range, with: "**\(mention)**")
                }
            }
            
            // Parse markdown with full syntax support
            var attributedString = try AttributedString(markdown: processedText, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full))
            
            // Set default styling
            attributedString.font = .systemFont(ofSize: 14)
            attributedString.foregroundColor = .primary
            
            // Find and color mentions (now formatted as bold) as blue
            let boldMentionPattern = "\\*\\*@([A-Z0-9.]+)\\*\\*"
            if let regex = try? NSRegularExpression(pattern: boldMentionPattern, options: []) {
                let processedNsString = processedText as NSString
                let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: processedNsString.length))
                
                for match in matches.reversed() {
                    // Get the range of the mention part (without the ** markers)
                    let mentionStart = match.range.location + 2 // Skip **
                    let mentionLength = match.range.length - 4 // Remove ** from both sides
                    if mentionStart < processedText.count && mentionLength > 0 {
                        let mentionRange = NSRange(location: mentionStart, length: mentionLength)
                        if let range = Range(mentionRange, in: processedText) {
                            // Find in attributed string by searching for the mention text
                            let mentionText = String(processedText[range])
                            if let foundRange = attributedString.range(of: mentionText) {
                                attributedString[foundRange].foregroundColor = .blue
                            }
                        }
                    }
                }
            }
            
            return attributedString
        } catch {
            print("Markdown parsing error: \(error)")
            // Fallback: create attributed string with basic formatting
            var fallback = AttributedString(text)
            fallback.font = .systemFont(ofSize: 14)
            fallback.foregroundColor = .primary
            return fallback
        }
    }
    
    private struct TextPart {
        let text: String
        let isMention: Bool
    }
    
    private func parseMentions(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        // Pattern: @ followed by uppercase letters, numbers, or dots (for stock symbols)
        let pattern = "@([A-Z0-9.]+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var lastIndex = 0
            for match in matches {
                // Add text before match
                if match.range.location > lastIndex {
                    let beforeText = nsString.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                    if !beforeText.isEmpty {
                        parts.append(TextPart(text: beforeText, isMention: false))
                    }
                }
                
                // Add mention
                let mentionText = nsString.substring(with: match.range)
                parts.append(TextPart(text: mentionText, isMention: true))
                
                lastIndex = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastIndex < nsString.length {
                let remainingText = nsString.substring(from: lastIndex)
                if !remainingText.isEmpty {
                    parts.append(TextPart(text: remainingText, isMention: false))
                }
            }
            
            if parts.isEmpty {
                parts.append(TextPart(text: text, isMention: false))
            }
        } catch {
            // If regex fails, return whole text as single part
            parts.append(TextPart(text: text, isMention: false))
        }
        
        return parts
    }
}

@MainActor
class DictationManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        // Cancel previous task if exists
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Request microphone permission (macOS)
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted, let self = self else { return }
            
            DispatchQueue.main.async {
                self.startRecognition()
            }
        }
    }
    
    private func startRecognition() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        do {
            let audioEngine = AVAudioEngine()
            self.audioEngine = audioEngine
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            recognizedText = ""
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.recognizedText = result.bestTranscription.formattedString
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    DispatchQueue.main.async {
                        self.stopListening()
                    }
                }
            }
        } catch {
            print("Error starting speech recognition: \(error)")
            stopListening()
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        
        isListening = false
    }
}

struct FloatingChatBar: View {
    @Binding var isChatOpen: Bool
    @Binding var initialMessage: String
    @Binding var inputText: String
    @StateObject private var dictationManager = DictationManager()
    var onSendMessage: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // Custom text input with formatted mentions
            FormattedTextField(text: $inputText, placeholder: "Ask about stocks...", onSubmit: {
                sendMessage()
            })
            .frame(height: 20)
            
            if !inputText.isEmpty {
                // Send button when text is entered - 36x36px circle with smaller icon
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 36, height: 36) // Force square shape
                .clipShape(Circle()) // Make it circular
                .buttonStyle(.glassProminent) // Native Liquid Glass prominent button style
            } else {
                // Dictation button when empty - 36x36px circle with smaller icon, no background
                Button(action: {
                    if dictationManager.isListening {
                        dictationManager.stopListening()
                        inputText = dictationManager.recognizedText
                    } else {
                        dictationManager.requestAuthorization { granted in
                            if granted {
                                dictationManager.startListening()
                            }
                        }
                    }
                }) {
                    Image(systemName: dictationManager.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(dictationManager.isListening ? .red : .secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 36, height: 36) // Force square shape
                .clipShape(Circle()) // Make it circular
                .buttonStyle(.plain) // No background color
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(in: .capsule) // Native Liquid Glass for floating chat bar with capsule shape
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: 768)
        .onChange(of: dictationManager.recognizedText) {
            if !dictationManager.recognizedText.isEmpty && dictationManager.isListening {
                inputText = dictationManager.recognizedText
            }
        }
        .onChange(of: dictationManager.isListening) {
            if !dictationManager.isListening && !dictationManager.recognizedText.isEmpty {
                inputText = dictationManager.recognizedText
            }
        }
    }
    
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let message = inputText.trimmingCharacters(in: .whitespaces)
        inputText = ""
        dictationManager.stopListening()
        
        if !isChatOpen {
            // Open overlay with message
            initialMessage = message
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isChatOpen = true
            }
        } else {
            // Send message directly in overlay
            initialMessage = message
            // Trigger message send via binding change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                initialMessage = "" // Clear after triggering
            }
        }
    }
}
