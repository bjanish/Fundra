//
//  ContentView.swift
//  Fundra
//
//  Created by Brian Janish on 6/10/26.
//

import SwiftUI
import SwiftData
import Charts
import StoreKit
import WidgetKit

// MARK: - Screenshot Mode (DEBUG only)
#if DEBUG
let screenshotMode = true  // Seeds data, skips Face ID, no date restriction — looks like production (for App Store screenshots)
let debugMode = false         // Everything screenshot mode does + debug overlays (dark/light toggle, etc.)
let useRealisticData = true  // true = 6 accounts, 1 month (June); false = 3 accounts, 3 months (growth testing)
#endif

#if canImport(UIKit)
import UIKit
#endif

import AudioToolbox
import UserNotifications

// MARK: - Brand Colors

let moneyGreen = Color(red: 0.26, green: 0.54, blue: 0.38)

// MARK: - Number Formatting

private let allowedAmountCharacters = CharacterSet(charactersIn: "0123456789.,")

// MARK: - Locale-Aware Currency Formatting

private let currencySymbol: String = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.currencySymbol ?? "$"
}()

private let decimalSeparator: String = {
    Locale.current.decimalSeparator ?? "."
}()

func filterAmountInput(_ value: String) -> String {
    var filtered = String(value.unicodeScalars.filter { allowedAmountCharacters.contains($0) })
    
    // Normalize: treat both . and , as the decimal separator
    let sep: Character = decimalSeparator == "," ? "," : "."
    let otherSep: Character = sep == "," ? "." : ","
    
    // Replace the non-locale separator with the locale one
    filtered = filtered.map { $0 == otherSep ? sep : $0 }.map(String.init).joined()
    
    // Allow only one decimal separator
    var foundFirst = false
    filtered = String(filtered.filter { char in
        if char == sep {
            if foundFirst { return false }
            foundFirst = true
        }
        return true
    })
    
    // Limit to 2 decimal places
    if let dotIndex = filtered.firstIndex(of: sep) {
        let afterDot = filtered[filtered.index(after: dotIndex)...]
        let digitsAfterDot = afterDot.filter { $0.isNumber }
        if digitsAfterDot.count > 2 {
            let endIndex = filtered.index(dotIndex, offsetBy: 3)
            filtered = String(filtered[...endIndex])
        }
    }
    
    return filtered
}

func abbreviatedAmount(_ amount: Double) -> String {
    if amount >= 1_000_000 {
        return String(format: "\(currencySymbol)%.1fM", amount / 1_000_000)
    } else if amount >= 100_000 {
        return String(format: "\(currencySymbol)%.0fK", amount / 1_000)
    } else if amount >= 10_000 {
        return String(format: "\(currencySymbol)%.1fK", amount / 1_000)
    } else {
        return formatFullAmount(amount)
    }
}

func formatFullAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    if amount.truncatingRemainder(dividingBy: 1) == 0 {
        formatter.maximumFractionDigits = 0
    } else {
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
    }
    return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(amount)"
}

// MARK: - Monthly Reminder Notification

func requestAndScheduleMonthlyReminder() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
        guard granted else { return }
        scheduleMonthlyReminder()
    }
}

private func scheduleMonthlyReminder() {
    let center = UNUserNotificationCenter.current()
    
    // Remove any existing reminder before scheduling
    center.removePendingNotificationRequests(withIdentifiers: ["fundra-monthly-reminder"])
    
    let content = UNMutableNotificationContent()
    content.title = "Time to record"
    content.body = "It's a new month — update your savings totals in Fundra."
    content.sound = .default
    
    // Fire on the 1st of every month at 9:00 AM
    var dateComponents = DateComponents()
    dateComponents.day = 1
    dateComponents.hour = 9
    dateComponents.minute = 0
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "fundra-monthly-reminder", content: content, trigger: trigger)
    
    center.add(request)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    #if DEBUG
    @State private var debugColorScheme: ColorScheme? = nil
    @State private var hasSeeded = false
    #endif
    
    var body: some View {
        Group {
            if categories.isEmpty {
                OnboardingView()
            } else {
                MainView()
            }
        }
        #if DEBUG
        .onAppear {
            if (screenshotMode || debugMode) && !hasSeeded {
                hasSeeded = true
                seedScreenshotData()
            }
        }
        .preferredColorScheme((screenshotMode || debugMode) ? debugColorScheme : nil)
        .overlay(alignment: .topLeading) {
            if debugMode {
                Button {
                    if let current = debugColorScheme {
                        debugColorScheme = current == .dark ? .light : .dark
                    } else {
                        debugColorScheme = colorScheme == .dark ? .light : .dark
                    }
                } label: {
                    // Show destination: sun if currently dark (tap to go light), moon if currently light (tap to go dark)
                    let effective = debugColorScheme ?? colorScheme
                    Image(systemName: effective == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5), in: Circle())
                }
                .padding(.leading, 12)
                .padding(.top, 12)
            }
        }
        #endif
    }
    
    #if DEBUG
    private func seedScreenshotData() {
        // Wipe existing data and re-seed fresh every launch
        let categoryDescriptor = FetchDescriptor<Category>()
        let balanceDescriptor = FetchDescriptor<Balance>()
        if let existingCategories = try? modelContext.fetch(categoryDescriptor) {
            for cat in existingCategories { modelContext.delete(cat) }
        }
        if let existingBalances = try? modelContext.fetch(balanceDescriptor) {
            for bal in existingBalances { modelContext.delete(bal) }
        }
        try? modelContext.save()
        
        if screenshotMode {
            seedGrowthData()
        } else if useRealisticData {
            seedRealisticData()
        } else {
            seedGrowthData()
        }
    }
    
    private func seedGrowthData() {
        let accounts = [
            ("Emergency", [1800.0, 2100.0, 2450.0]),
            ("Vacation",  [2400.0, 2750.0, 3120.0]),
            ("New Car",   [7200.0, 7950.0, 8750.0]),
            ("Savings",   [3500.0, 4100.0, 4800.0]),
        ]
        
        let months = [
            (year: 2026, month: 1, day: 15),
            (year: 2026, month: 2, day: 15),
            (year: 2026, month: 3, day: 15),
        ]
        
        for (index, (name, amounts)) in accounts.enumerated() {
            let category = Category(name: name, sortOrder: index)
            modelContext.insert(category)
            
            for (monthIndex, amount) in amounts.enumerated() {
                let m = months[monthIndex]
                let balance = Balance(category: category, year: m.year, month: m.month, day: m.day, amount: amount)
                modelContext.insert(balance)
            }
        }
        
        try? modelContext.save()
    }
    
    private func seedRealisticData() {
        let accounts: [(String, Double)] = [
            ("Cash", 1000.0),
            ("Apple", 1873.0),
            ("FCCU", 7000.0),
            ("Inspira", 7621.0),
            ("Moomoo", 12673.0),
            ("Forbright", 34152.0),
        ]
        
        for (index, (name, amount)) in accounts.enumerated() {
            let category = Category(name: name, sortOrder: index)
            modelContext.insert(category)
            
            let balance = Balance(category: category, year: 2026, month: 6, day: 15, amount: amount)
            modelContext.insert(balance)
        }
        
        try? modelContext.save()
    }
    #endif
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var accountNames: [String] = ["", "", ""]
    @State private var logoBarHeights: [CGFloat] = [8, 14, 22]
    @State private var waveOffset: Int = -1
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill([
                                Color(red: 0.43, green: 0.60, blue: 0.76),
                                Color(red: 0.54, green: 0.73, blue: 0.63),
                                Color(red: 0.76, green: 0.68, blue: 0.58),
                            ][index])
                            .frame(width: 6, height: logoBarHeights[index])
                    }
                }
                .onAppear {
                    randomizeBarHeights()
                }
                
                VStack(spacing: 4) {
                    let fullText = "Welcome to Fundra"
                    let fundraStart = 11 // index where "Fundra" begins
                    HStack(spacing: 0) {
                        ForEach(Array(fullText.enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.title)
                                .fontWeight(.bold)
                                .italic(index >= fundraStart)
                                .foregroundColor(index >= fundraStart ? Color(red: 0.43, green: 0.60, blue: 0.76) : .primary)
                                .offset(y: waveOffset == index ? -10 : 0)
                                .animation(.easeInOut(duration: 0.25), value: waveOffset)
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            startWave(count: fullText.count)
                        }
                    }
                    
                    Text("Add your savings to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 32)
            
            // Account inputs
            VStack(spacing: 15) {
                let suggestions = ["e.g., Savings", "e.g., Vacation", "e.g., Emergency", "e.g., New Car", "e.g., Roth IRA", "e.g., Cash"]
                ForEach(0..<accountNames.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            TextField("Name", text: $accountNames[index])
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .onChange(of: accountNames[index]) { _, newValue in
                                    if newValue.count > 15 { accountNames[index] = String(newValue.prefix(15)) }
                                }
                                .focused($focusedField, equals: index)
                            if accountNames.count > 1 {
                                Button {
                                    accountNames.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if isDuplicate(at: index) {
                            Text("Already added")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 12)
                        } else {
                            Text(suggestions[index % suggestions.count])
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                                .opacity(accountNames[index].isEmpty ? 1 : 0)
                        }
                    }
                }
                
                if accountNames.count < 6 {
                    Button {
                        accountNames.append("")
                        focusedField = accountNames.count - 1
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add another")
                        }
                    }
                    .font(.callout)
                    .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            
            Button("Get Started") {
                saveAccounts()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(accountNames.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty })
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.27) {
                focusedField = 0
            }
        }
    }
    
    private func saveAccounts() {
        let validNames = accountNames
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Remove duplicates (case-insensitive), keeping first occurrence
        var seen = Set<String>()
        let uniqueNames = validNames.filter { name in
            let lower = name.lowercased()
            if seen.contains(lower) { return false }
            seen.insert(lower)
            return true
        }
        
        for (index, name) in uniqueNames.enumerated() {
            let category = Category(name: name, sortOrder: index)
            modelContext.insert(category)
        }
    }
    
    private func startWave(count: Int) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                waveOffset = i
            }
        }
        // Reset after wave completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.06 + 0.25) {
            waveOffset = -1
        }
    }
    
    private func isDuplicate(at index: Int) -> Bool {
        let name = accountNames[index].trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.isEmpty else { return false }
        return accountNames.enumerated().contains { i, other in
            i < index && other.trimmingCharacters(in: .whitespaces).lowercased() == name
        }
    }
    
    private func randomizeBarHeights() {
        withAnimation(.easeInOut(duration: 1.2)) {
            logoBarHeights = [
                CGFloat.random(in: 6...9),
                CGFloat.random(in: 12...16),
                CGFloat.random(in: 19...22),
            ]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            randomizeBarHeights()
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var allBalances: [Balance]
    @State private var showRecordMonth = false
    @State private var showGrowthSummary = false
    @State private var currentPeriodIndex: Int?
    @State private var editingCategory: Category? = nil
    @State private var editingBalance: Balance? = nil
    @State private var showAddCategory = false
    @State private var deletingCategory: Category? = nil
    @State private var showDeleteMonth = false
    @State private var isDeletingLastMonth = false
    @State private var undoData: [(categoryId: PersistentIdentifier, year: Int, month: Int, day: Int, amount: Double)] = []
    @State private var showUndoToast = false
    @State private var chartAnimating = false
    @State private var chartWiggleOffset: CGFloat = 0
    @State private var chartWiggleVertical: CGFloat = 0
    @State private var displayedTotal: Double = 0
    @State private var titleIconAnimating = false
    @State private var titleTapCount = 0
    @State private var showConfetti = false
    @AppStorage("hasSeenLongPressTip") private var hasSeenLongPressTip = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var chartColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.30, green: 0.45, blue: 0.60),  // darker blue
                Color(red: 0.38, green: 0.57, blue: 0.47),  // darker green
                Color(red: 0.60, green: 0.52, blue: 0.42),  // darker tan
                Color(red: 0.44, green: 0.37, blue: 0.60),  // darker purple
                Color(red: 0.60, green: 0.42, blue: 0.42),  // darker rose
                Color(red: 0.35, green: 0.53, blue: 0.60),  // darker teal
            ]
        } else {
            return [
                Color(red: 0.43, green: 0.60, blue: 0.76),  // #6e98c2
                Color(red: 0.54, green: 0.73, blue: 0.63),  // #8abba2
                Color(red: 0.76, green: 0.68, blue: 0.58),  // #c2ad95
                Color(red: 0.60, green: 0.53, blue: 0.76),  // #9888c2
                Color(red: 0.76, green: 0.58, blue: 0.58),  // #c29595
                Color(red: 0.50, green: 0.69, blue: 0.76),  // #7fb0c2
            ]
        }
    }
    
    private var periods: [(year: Int, month: Int, day: Int)] {
        let grouped = Dictionary(grouping: allBalances) { "\($0.year)-\($0.month)" }
        return grouped.keys.compactMap { key in
            guard let balance = grouped[key]?.first else { return nil }
            return (balance.year, balance.month, balance.day)
        }.sorted { a, b in
            if a.year != b.year { return a.year < b.year }
            return a.month < b.month
        }
    }
    
    private var selectedPeriod: (year: Int, month: Int, day: Int)? {
        guard !periods.isEmpty else { return nil }
        let index = currentPeriodIndex ?? (periods.count - 1)
        guard index >= 0 && index < periods.count else { return nil }
        return periods[index]
    }
    
    private var currentTotal: Double {
        guard let period = selectedPeriod else { return 0 }
        return allBalances
            .filter { $0.year == period.year && $0.month == period.month }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var latestBalances: [(name: String, amount: Double)] {
        guard let period = selectedPeriod else { return [] }
        return categories.compactMap { category in
            guard let balance = category.balances.first(where: {
                $0.year == period.year && $0.month == period.month
            }) else { return nil }
            return (name: category.name, amount: balance.amount)
        }.sorted { $0.amount < $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // App title
                    HStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(0..<3, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill([
                                        Color(red: 0.43, green: 0.60, blue: 0.76),
                                        Color(red: 0.54, green: 0.73, blue: 0.63),
                                        Color(red: 0.76, green: 0.68, blue: 0.58),
                                    ][index])
                                    .frame(width: 4, height: titleIconAnimating ? [4, 8, 14.4][index] : 0)
                            }
                        }
                        .frame(width: 16, height: 16)
                        
                        Text("Fundra")
                            .font(.system(size: 28, weight: .bold))
                            .italic()
                            .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                    .onAppear {
                        titleIconAnimating = true
                    }
                    .onTapGesture {
                        titleTapCount += 1
                        withAnimation(.easeOut(duration: 0.1)) {
                            titleIconAnimating = false
                            chartAnimating = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                titleIconAnimating = true
                            }
                            withAnimation(.easeOut(duration: 0.6)) {
                                chartAnimating = true
                            }
                        }
                        if titleTapCount % 3 == 0 {
                            showConfetti = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            // Earthquake jiggle — fixed pattern, chaotic feel
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                let steps: [(x: CGFloat, y: CGFloat, duration: Double)] = [
                                    ( 5, -3, 0.04),
                                    (-6,  4, 0.05),
                                    ( 3,  6, 0.04),
                                    (-7, -2, 0.05),
                                    ( 6, -5, 0.04),
                                    (-4,  7, 0.05),
                                    ( 7,  2, 0.04),
                                    (-3, -6, 0.04),
                                    ( 2,  3, 0.05),
                                    ( 0,  0, 0.04),
                                ]
                                var delay = 0.0
                                for (index, step) in steps.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        withAnimation(.linear(duration: step.duration)) {
                                            chartWiggleOffset = step.x
                                            chartWiggleVertical = step.y
                                        }
                                        if index < steps.count - 1 {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        }
                                    }
                                    delay += step.duration
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                showConfetti = false
                            }
                        }
                    }
                    
                    // Total header
                    headerView
                        .padding(.top, 8)
                    
                    // Chart
                    chartView
                    
                    // Export & Share actions
                    HStack(spacing: 20) {
                        ShareLink(item: exportCSVData(), preview: SharePreview(exportFileName, image: exportPreviewImage)) {
                            HStack(spacing: 7) {
                                MiniBarChartIcon(animating: titleIconAnimating)
                                Text("Export")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if let chartURL = chartImageURL, let chartImage = renderedChartImage {
                            ShareLink(item: chartURL, preview: SharePreview("Fundra Chart", image: chartImage)) {
                                HStack(spacing: 7) {
                                    MiniBarChartIcon(animating: titleIconAnimating)
                                    Text("Save Chart")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: {}) {
                                HStack(spacing: 7) {
                                    MiniBarChartIcon(opacity: 0.5, animating: titleIconAnimating)
                                    Text("Save Chart")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))
                            }
                            .disabled(true)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.08))
                    )
                    
                    // Separator
                    Divider()
                        .padding(.top, 1)
                        .padding(.bottom, 2)
                    
                    // Account list
                    accountListView
                    
                    // Quote
                    QuoteView()
                        .padding(.top, -4)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showRecordMonth = true }) {
                        Text("Record")
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? Color(white: 0.95) : .white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(colorScheme == .dark ? Color(red: 0.20, green: 0.45, blue: 0.32) : Color(red: 0.28, green: 0.55, blue: 0.40))
                    .shadow(color: (colorScheme == .dark ? Color(red: 0.20, green: 0.45, blue: 0.32) : Color(red: 0.28, green: 0.55, blue: 0.40)).opacity(0.4), radius: 4, x: 0, y: 2)
                    .controlSize(.mini)
                }
            }
            .background(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(UIColor.systemBackground))
            .sheet(isPresented: $showRecordMonth) {
                RecordMonthView()
            }
            .sheet(isPresented: $showGrowthSummary) {
                GrowthSummaryView(selectedPeriod: selectedPeriod, allBalances: allBalances, periods: periods)
            }
            .sheet(item: $editingBalance) { balance in
                EditBalanceView(balance: balance)
            }
            .sheet(item: $editingCategory) { category in
                ManageCategoryView(category: category)
            }
            .sheet(isPresented: $showAddCategory) {
                AddAccountView(selectedPeriod: selectedPeriod)
            }
            .alert(isDeletingLastMonth ? "⚠️ Delete Month?" : "Delete Month?", isPresented: $showDeleteMonth) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    guard let period = selectedPeriod else { return }
                    let toDelete = allBalances.filter { $0.year == period.year && $0.month == period.month }
                    
                    // save for undo
                    undoData = toDelete.compactMap { balance in
                        guard let category = balance.category else { return nil }
                        return (categoryId: category.persistentModelID, year: balance.year, month: balance.month, day: balance.day, amount: balance.amount)
                    }
                    
                    let isLastMonth = periods.count == 1
                    
                    for balance in toDelete {
                        modelContext.delete(balance)
                    }
                    
                    // If this was the only month, reset to onboarding
                    if isLastMonth {
                        for category in categories {
                            modelContext.delete(category)
                        }
                        try? modelContext.save()
                        return
                    }
                    
                    try? modelContext.save()
                    
                    if let idx = currentPeriodIndex, idx > 0 {
                        currentPeriodIndex = idx - 1
                    } else {
                        currentPeriodIndex = nil
                    }
                    
                    // show undo toast
                    showUndoToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if showUndoToast {
                            showUndoToast = false
                            undoData = []
                        }
                    }
                }
            } message: {
                if isDeletingLastMonth {
                    Text("This is your last month. Deleting it will reset the app to setup.")
                } else if let period = selectedPeriod {
                    let date = Calendar.current.date(from: DateComponents(year: period.year, month: period.month)) ?? Date()
                    Text("This will remove all balances for \(date.formatted(.dateTime.month(.wide).year())).")
                } else {
                    Text("This will remove all balances for this month.")
                }
            }
            .alert("Delete Account?", isPresented: Binding(
                get: { deletingCategory != nil },
                set: { if !$0 { deletingCategory = nil } }
            )) {
                Button("Cancel", role: .cancel) { deletingCategory = nil }
                Button("Delete", role: .destructive) {
                    if let category = deletingCategory {
                        modelContext.delete(category)
                        try? modelContext.save()
                    }
                    deletingCategory = nil
                }
            } message: {
                if categories.count == 1 {
                    Text("This is your last account. Deleting it will reset the app to setup.")
                } else {
                    Text("This will delete '\(deletingCategory?.name ?? "")' and all its balances.")
                }
            }
            .overlay(alignment: .bottom) {
                if showUndoToast {
                    HStack {
                        Text("Month deleted")
                            .foregroundColor(.white)
                        Spacer()
                        Button("Undo") {
                            // restore balances
                            for item in undoData {
                                if let category = modelContext.model(for: item.categoryId) as? Category {
                                    let balance = Balance(category: category, year: item.year, month: item.month, day: item.day, amount: item.amount)
                                    modelContext.insert(balance)
                                }
                            }
                            try? modelContext.save()
                            undoData = []
                            showUndoToast = false
                            currentPeriodIndex = periods.count - 1
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: showUndoToast)
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var activeIndex: Int {
        currentPeriodIndex ?? (periods.count - 1)
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            if currentTotal > 0 {
                Text(formatFullAmount(displayedTotal))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(moneyGreen)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.6), value: displayedTotal)
            }
            
            // Month navigation
            HStack(spacing: 16) {
                Button(action: {
                    if activeIndex > 0 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPeriodIndex = activeIndex - 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(activeIndex > 0 ? .blue : .gray.opacity(0.3))
                }
                .disabled(activeIndex <= 0)
                
                if let period = selectedPeriod {
                    let date = Calendar.current.date(from: DateComponents(year: period.year, month: period.month, day: period.day)) ?? Date()
                    Text(date, format: .dateTime.month(.wide).day().year())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            isDeletingLastMonth = periods.count == 1
                            showDeleteMonth = true
                        }
                }
                
                Button(action: {
                    if activeIndex < periods.count - 1 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPeriodIndex = activeIndex + 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(activeIndex < periods.count - 1 ? .blue : .gray.opacity(0.3))
                }
                .disabled(activeIndex >= periods.count - 1)
            }
        }
        .padding(.top, 8)
        .onAppear {
            if currentPeriodIndex == nil {
                currentPeriodIndex = periods.count - 1
            }
            displayedTotal = currentTotal
            triggerChartAnimation()
        }
        .onChange(of: periods.count) {
            currentPeriodIndex = periods.count - 1
        }
        .onChange(of: currentPeriodIndex) {
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedTotal = currentTotal
            }
            triggerChartAnimation()
        }
        .onChange(of: allBalances.count) {
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedTotal = currentTotal
            }
        }
        .onChange(of: currentTotal) {
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedTotal = currentTotal
            }
        }
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        Group {
            if !latestBalances.isEmpty {
                Chart {
                    ForEach(Array(latestBalances.enumerated()), id: \.element.name) { index, item in
                        BarMark(
                            x: .value("Account", item.name),
                            y: .value("Balance", chartAnimating ? item.amount : 0)
                        )
                        .foregroundStyle(chartColors[index % chartColors.count])
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text(abbreviatedAmount(item.amount))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .opacity(chartAnimating ? 1 : 0)
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                guard let name: String = proxy.value(atX: location.x) else { return }
                                guard let period = selectedPeriod,
                                      let category = categories.first(where: { $0.name == name }),
                                      let balance = category.balances.first(where: { $0.year == period.year && $0.month == period.month })
                                else { return }
                                editingBalance = balance
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                let maxChars: Int = {
                                    switch latestBalances.count {
                                    case 6: return 9
                                    case 5: return 11
                                    default: return 15
                                    }
                                }()
                                Text(name.count > maxChars ? String(name.prefix(maxChars - 1)) + "…" : name)
                                    .font(.system(size: 10, weight: .semibold))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.gray.opacity(0.4))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(abbreviatedAmount(amount))
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...(latestBalances.map(\.amount).max() ?? 1))
                .frame(maxWidth: latestBalances.count == 1 ? 200 : .infinity, alignment: .center)
                .frame(height: 230)
                .padding(.horizontal)
                .padding(.top, 30)
                .padding(.bottom, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.20))
                        .padding(.horizontal, 8)
                )
                .id(currentPeriodIndex)
                .transition(.opacity.combined(with: .slide))
                .offset(x: chartWiggleOffset, y: chartWiggleVertical)
            } else if allBalances.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("Record your first month to see the chart")
                            .foregroundColor(.secondary)
                    )
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Account List
    
    private var accountListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Accounts")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.75) : .primary)
                Spacer()
                Button {
                    showGrowthSummary = true
                } label: {
                    HStack(spacing: 5) {
                        MiniLineChartIcon()
                        Text("Growth")
                    }
                }
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(red: 0.43, green: 0.60, blue: 0.76) : Color(red: 0.30, green: 0.45, blue: 0.60))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            let sortedCategories = categoriesSortedByBalance
            ForEach(sortedCategories, id: \.id) { category in
                let balance = latestBalance(for: category)
                HStack {
                    Text(category.name)
                        .font(.body)
                        .foregroundColor(Color(white: 0.35))
                    Spacer()
                    if let balance = balance {
                        Text(formatFullAmount(balance.amount))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(moneyGreen)
                    } else {
                        Text("—")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let balance = balance {
                        editingBalance = balance
                    } else {
                        showRecordMonth = true
                    }
                }
                .contextMenu {
                    Button {
                        editingCategory = category
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deletingCategory = category
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                
                Divider()
                    .padding(.horizontal)
            }
            
            // Add category button
            if !hasSeenLongPressTip {
                Text("Tip: Long-press an account to rename or delete it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation {
                                hasSeenLongPressTip = true
                            }
                        }
                    }
            }
            
            Button(action: { showAddCategory = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Account")
                }
                .font(.callout)
                .foregroundColor(categories.count >= 6 ? .gray.opacity(0.4) : (colorScheme == .dark ? Color(red: 0.43, green: 0.60, blue: 0.76) : Color(red: 0.30, green: 0.45, blue: 0.60)))
            }
            .disabled(categories.count >= 6)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 6)
            
            if categories.count >= 6 {
                Text("6 account limit reached")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.4))
                    .padding(.horizontal)
            }
        }
        .padding(.top, -1)
    }
    
    private var categoriesSortedByBalance: [Category] {
        categories.sorted { cat1, cat2 in
            let bal1 = latestBalance(for: cat1)?.amount ?? 0
            let bal2 = latestBalance(for: cat2)?.amount ?? 0
            return bal1 < bal2
        }
    }
    
    private func latestBalance(for category: Category) -> Balance? {
        guard let period = selectedPeriod else { return nil }
        return category.balances.first {
            $0.year == period.year && $0.month == period.month
        }
    }
    
    private func triggerChartAnimation() {
        chartAnimating = false
        withAnimation(.easeOut(duration: 0.6)) {
            chartAnimating = true
        }
    }
    
    // MARK: - Export & Share
    
    private var exportPreviewImage: Image {
        let barHeights: [CGFloat] = [20, 40, 72]
        let view = HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(chartColors[index])
                    .frame(width: 20, height: barHeights[index])
            }
        }
        .padding(20)
        .background(Color.white)
        .frame(width: 100, height: 100)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "doc.text")
    }
    
    private var exportFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Fundra_\(formatter.string(from: Date())).csv"
    }
    
    private func exportCSVData() -> URL {
        var csv = "Account,Date,Amount\n"
        for period in periods {
            let date = Calendar.current.date(from: DateComponents(year: period.year, month: period.month, day: period.day)) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let dateString = dateFormatter.string(from: date)
            
            for category in categories {
                if let balance = category.balances.first(where: { $0.year == period.year && $0.month == period.month }) {
                    csv += "\(category.name),\(dateString),\(String(format: "%.2f", balance.amount))\n"
                }
            }
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(exportFileName)
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    private var renderedChartImage: Image? {
        guard !latestBalances.isEmpty else { return nil }
        let renderer = ImageRenderer(content: chartForExport)
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
    
    private var chartImageURL: URL? {
        guard !latestBalances.isEmpty else { return nil }
        let renderer = ImageRenderer(content: chartForExport)
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage,
              let data = uiImage.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FundraChart.png")
        try? data.write(to: url)
        return url
    }
    
    @ViewBuilder
    private var chartForExport: some View {
        VStack(spacing: 4) {
            // Total
            if currentTotal > 0 {
                Text(formatFullAmount(currentTotal))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(moneyGreen)
            }
            
            // Date
            if let period = selectedPeriod {
                let date = Calendar.current.date(from: DateComponents(year: period.year, month: period.month, day: period.day)) ?? Date()
                Text(date, format: .dateTime.month(.wide).day().year())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Chart with annotations
            Chart {
                ForEach(Array(latestBalances.enumerated()), id: \.element.name) { index, item in
                    BarMark(
                        x: .value("Account", item.name),
                        y: .value("Balance", item.amount)
                    )
                    .foregroundStyle(chartColors[index % chartColors.count])
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(abbreviatedAmount(item.amount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            let maxChars: Int = {
                                switch latestBalances.count {
                                case 6: return 9
                                case 5: return 11
                                default: return 15
                                }
                            }()
                            Text(name.count > maxChars ? String(name.prefix(maxChars - 1)) + "…" : name)
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.4))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(abbreviatedAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(width: 400, height: 242)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Record Month

struct RecordMonthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("hasAskedNotificationPermission") private var hasAskedNotification = false
    @AppStorage("recordSaveCount") private var recordSaveCount = 0
    
    @State private var selectedDate = Date()
    @State private var amounts: [String] = []
    @State private var placeholders: [String] = []
    @State private var isReady = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    #if DEBUG
                    if screenshotMode {
                        // Screenshot mode: restrict to seeded date (looks like production)
                        let screenshotMaxDate = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!
                        DatePicker(selection: $selectedDate, in: ...screenshotMaxDate, displayedComponents: .date) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 0.43, green: 0.60, blue: 0.76), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                    Circle()
                                        .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                                        .frame(width: 5, height: 5)
                                }
                                Text("Record date")
                            }
                        }
                            .datePickerStyle(.compact)
                            .tint(Color(red: 0.43, green: 0.60, blue: 0.76))
                            .padding(.leading, 4)
                    } else if debugMode {
                        // Debug mode: no date restriction
                        DatePicker(selection: $selectedDate, displayedComponents: .date) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 0.43, green: 0.60, blue: 0.76), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                    Circle()
                                        .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                                        .frame(width: 5, height: 5)
                                }
                                Text("Record date")
                            }
                        }
                            .datePickerStyle(.compact)
                            .tint(Color(red: 0.43, green: 0.60, blue: 0.76))
                            .padding(.leading, 4)
                    } else {
                        DatePicker(selection: $selectedDate, in: ...Date(), displayedComponents: .date) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 0.43, green: 0.60, blue: 0.76), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                    Circle()
                                        .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                                        .frame(width: 5, height: 5)
                                }
                                Text("Record date")
                            }
                        }
                            .datePickerStyle(.compact)
                            .tint(Color(red: 0.43, green: 0.60, blue: 0.76))
                            .padding(.leading, 4)
                    }
                    #else
                    DatePicker(selection: $selectedDate, in: ...Date(), displayedComponents: .date) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color(red: 0.43, green: 0.60, blue: 0.76), lineWidth: 1.5)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                                    .frame(width: 5, height: 5)
                            }
                            Text("Record date")
                        }
                    }
                        .datePickerStyle(.compact)
                        .tint(Color(red: 0.43, green: 0.60, blue: 0.76))
                        .padding(.leading, 4)
                    #endif
                    Text("One entry per month. Recording again will update that month.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isReady {
                    Section("Balances") {
                        ForEach(0..<categories.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(categories[index].name)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text(currencySymbol)
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                    TextField(placeholders.indices.contains(index) ? placeholders[index] : "0.00", text: $amounts[index])
                                        .font(.title3)
                                        .onChange(of: amounts[index]) { _, newValue in
                                            let filtered = filterAmountInput(newValue)
                                            if filtered != newValue { amounts[index] = filtered }
                                        }
                                        #if os(iOS)
                                        .keyboardType(.decimalPad)
                                        #endif
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("")
            
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        MiniBarChartIcon()
                        Text("Record")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { save() }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.22, green: 0.38, blue: 0.55))
                    .shadow(color: Color(red: 0.22, green: 0.38, blue: 0.55).opacity(0.4), radius: 4, x: 0, y: 2)
                    .controlSize(.small)
                    .disabled({
                            let allValid = amounts.allSatisfy {
                                let raw = $0.replacingOccurrences(of: ",", with: "")
                                guard let amount = Double(raw), amount >= 0 else { return false }
                                return true
                            }
                            let hasNonZero = amounts.contains {
                                let raw = $0.replacingOccurrences(of: ",", with: "")
                                guard let amount = Double(raw), amount > 0 else { return false }
                                return true
                            }
                            return !allValid || !hasNonZero
                        }())
                }
            }
            .onAppear {
                amounts = Array(repeating: "", count: categories.count)
                placeholders = Array(repeating: "0.00", count: categories.count)
                isReady = true
                #if DEBUG
                if screenshotMode {
                    selectedDate = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15)) ?? Date()
                }
                #endif
                prefillAmounts()
            }
            .onChange(of: selectedDate) {
                prefillAmounts()
            }
        }
    }
    
    private func prefillAmounts() {
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        let year = components.year!
        let month = components.month!
        
        for (index, category) in categories.enumerated() {
            if let existing = category.balances.first(where: { $0.year == year && $0.month == month }) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                if existing.amount.truncatingRemainder(dividingBy: 1) == 0 {
                    formatter.maximumFractionDigits = 0
                } else {
                    formatter.maximumFractionDigits = 2
                    formatter.minimumFractionDigits = 2
                }
                amounts[index] = formatter.string(from: NSNumber(value: existing.amount)) ?? String(format: "%.2f", existing.amount)
            } else {
                amounts[index] = ""
            }
            
            // Set placeholder from most recent previous balance
            let previousBalance = category.balances
                .filter { $0.year < year || ($0.year == year && $0.month < month) }
                .sorted { a, b in
                    if a.year != b.year { return a.year > b.year }
                    return a.month > b.month
                }
                .first
            
            if let prev = previousBalance {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                if prev.amount.truncatingRemainder(dividingBy: 1) == 0 {
                    formatter.maximumFractionDigits = 0
                } else {
                    formatter.maximumFractionDigits = 2
                    formatter.minimumFractionDigits = 2
                }
                placeholders[index] = formatter.string(from: NSNumber(value: prev.amount)) ?? "0.00"
            } else {
                placeholders[index] = "0.00"
            }
        }
    }
    
    private func save() {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        let year = components.year!
        let month = components.month!
        let day = components.day!
        
        for (index, category) in categories.enumerated() {
            let raw = amounts[index].replacingOccurrences(of: ",", with: "")
            guard let amount = Double(raw), amount >= 0 else { continue }
            
            // check if balance already exists for this category/month
            let categoryID = category.persistentModelID
            let descriptor = FetchDescriptor<Balance>(predicate: #Predicate { balance in
                balance.year == year && balance.month == month && balance.category?.persistentModelID == categoryID
            })
            
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.amount = amount
                existing.day = day
                existing.updatedAt = Date()
            } else {
                let balance = Balance(category: category, year: year, month: month, day: day, amount: amount)
                modelContext.insert(balance)
            }
        }
        
        try? modelContext.save()
        
        // Request review on 3rd and 6th save
        recordSaveCount += 1
        if recordSaveCount == 3 || recordSaveCount == 6 {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
        
        // Request notification permission after first successful Record
        if !hasAskedNotification {
            hasAskedNotification = true
            requestAndScheduleMonthlyReminder()
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

// MARK: - Growth Summary

struct GrowthSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let selectedPeriod: (year: Int, month: Int, day: Int)?
    let allBalances: [Balance]
    let periods: [(year: Int, month: Int, day: Int)]
    
    private func total(year: Int, month: Int) -> Double {
        allBalances
            .filter { $0.year == year && $0.month == month }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if periods.count < 2 {
                    VStack(spacing: 16) {
                        Text("Record each month to track your\nsavings growth over time.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Sample preview chart
                        Chart {
                            let sampleData: [(String, Double)] = [
                                ("Jan", 4200),
                                ("Feb", 4800),
                                ("Mar", 5500),
                                ("Apr", 6400)
                            ]
                            ForEach(sampleData, id: \.0) { month, amount in
                                LineMark(
                                    x: .value("Month", month),
                                    y: .value("Total", amount)
                                )
                                .foregroundStyle(moneyGreen.opacity(0.4))
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Month", month),
                                    y: .value("Total", amount)
                                )
                                .foregroundStyle(moneyGreen.opacity(colorScheme == .dark ? 0.08 : 0.18))
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Month", month),
                                    y: .value("Total", amount)
                                )
                                .foregroundStyle(Color(red: 0.75, green: 0.65, blue: 0.38))
                                .symbolSize(40)
                            }
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.75, green: 0.65, blue: 0.38))
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .opacity(0.5)
                        
                        Text("Sample data — yours will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.top, 24)
                } else if let selected = selectedPeriod {
                    let first = periods.first!
                    
                    if selected.year == first.year && selected.month == first.month {
                        VStack(spacing: 16) {
                            Text("Swipe to a later month to\nsee your growth over time.")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Sample preview chart
                            Chart {
                                let sampleData: [(String, Double)] = [
                                    ("Jan", 4200),
                                    ("Feb", 4800),
                                    ("Mar", 5500),
                                    ("Apr", 6400)
                                ]
                                ForEach(sampleData, id: \.0) { month, amount in
                                    LineMark(
                                        x: .value("Month", month),
                                        y: .value("Total", amount)
                                    )
                                    .foregroundStyle(moneyGreen.opacity(0.4))
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Month", month),
                                        y: .value("Total", amount)
                                    )
                                    .foregroundStyle(moneyGreen.opacity(colorScheme == .dark ? 0.08 : 0.18))
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Month", month),
                                        y: .value("Total", amount)
                                    )
                                    .foregroundStyle(Color(red: 0.75, green: 0.65, blue: 0.38))
                                    .symbolSize(40)
                                }
                            }
                            .chartYAxis(.hidden)
                            .chartXAxis {
                                AxisMarks(values: .automatic) { _ in
                                    AxisValueLabel()
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.75, green: 0.65, blue: 0.38))
                                }
                            }
                            .frame(height: 160)
                            .padding(.horizontal, 24)
                            .padding(.top, 60)
                            .opacity(0.5)
                            
                            Text("Sample data — yours will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.top, 24)
                    } else {
                    let firstTotal = total(year: first.year, month: first.month)
                    let selectedTotal = total(year: selected.year, month: selected.month)
                    let change = selectedTotal - firstTotal
                    let pct = firstTotal > 0 ? (change / firstTotal) * 100 : 0
                    
                    // find prior month
                    let selectedIndex = periods.firstIndex(where: { $0.year == selected.year && $0.month == selected.month }) ?? 0
                    let priorPeriod = selectedIndex > 0 ? periods[selectedIndex - 1] : nil
                    let priorTotal = priorPeriod != nil ? total(year: priorPeriod!.year, month: priorPeriod!.month) : nil
                    
                    VStack(alignment: .leading, spacing: 16) {
                        let firstDate = Calendar.current.date(from: DateComponents(year: first.year, month: first.month, day: first.day)) ?? Date()
                        let selectedDate = Calendar.current.date(from: DateComponents(year: selected.year, month: selected.month, day: selected.day)) ?? Date()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 7) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 0.43, green: 0.60, blue: 0.76), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                    Circle()
                                        .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                                        .frame(width: 5, height: 5)
                                }
                                Text("\(firstDate, format: .dateTime.month(.wide)) (first recorded)")
                            }
                                .foregroundColor(.secondary)
                            Text(formatFullAmount(firstTotal))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        if let priorTotal = priorTotal, let priorPeriod = priorPeriod,
                           !(priorPeriod.year == first.year && priorPeriod.month == first.month) {
                            let priorDate = Calendar.current.date(from: DateComponents(year: priorPeriod.year, month: priorPeriod.month, day: priorPeriod.day)) ?? Date()
                            let monthChange = selectedTotal - priorTotal
                            let monthPct = priorTotal > 0 ? (monthChange / priorTotal) * 100 : 0
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 7) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color(red: 0.54, green: 0.73, blue: 0.63), lineWidth: 1.5)
                                            .frame(width: 10, height: 10)
                                        Circle()
                                            .fill(Color(red: 0.54, green: 0.73, blue: 0.63))
                                            .frame(width: 5, height: 5)
                                    }
                                    Text("\(priorDate, format: .dateTime.month(.wide)) (prior month)")
                                }
                                    .foregroundColor(.secondary)
                                HStack(spacing: 6) {
                                    Text(formatFullAmount(priorTotal))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Text("(\(monthChange >= 0 ? "+" : "-")\(formatFullAmount(abs(monthChange))), \(monthPct, specifier: "%.1f")%)")
                                        .font(.system(size: 15))
                                        .foregroundColor(monthChange >= 0 ? moneyGreen : .red)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 7) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 0.76, green: 0.68, blue: 0.58), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                    Circle()
                                        .fill(Color(red: 0.76, green: 0.68, blue: 0.58))
                                        .frame(width: 5, height: 5)
                                }
                                Text("\(selectedDate, format: .dateTime.month(.wide)) (current)")
                            }
                                .foregroundColor(.secondary)
                            Text(formatFullAmount(selectedTotal))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        let firstDate = Calendar.current.date(from: DateComponents(year: first.year, month: first.month, day: first.day)) ?? Date()
                        let selectedDate = Calendar.current.date(from: DateComponents(year: selected.year, month: selected.month, day: selected.day)) ?? Date()
                        
                        HStack {
                            Text("Total growth from \(firstDate, format: .dateTime.month(.wide)) to \(selectedDate, format: .dateTime.month(.wide)):")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        HStack {
                            Text("\(change >= 0 ? "+" : "-")\(formatFullAmount(abs(change))) (\(pct, specifier: "%.1f")%)")
                                .fontWeight(.bold)
                                .foregroundColor(change >= 0 ? moneyGreen : .red)
                        }
                        .font(.title3)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    
                    // Line chart showing total over time
                    Chart {
                        ForEach(Array(periods.enumerated()), id: \.offset) { _, period in
                            let periodTotal = total(year: period.year, month: period.month)
                            let date = Calendar.current.date(from: DateComponents(year: period.year, month: period.month, day: period.day)) ?? Date()
                            LineMark(
                                x: .value("Month", date),
                                y: .value("Total", periodTotal)
                            )
                            .foregroundStyle(moneyGreen)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Month", date),
                                y: .value("Total", periodTotal)
                            )
                            .foregroundStyle(moneyGreen.opacity(0.1))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Month", date),
                                y: .value("Total", periodTotal)
                            )
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.65, green: 0.55, blue: 0.30) : Color(red: 0.75, green: 0.63, blue: 0.0))
                            .symbolSize(30)
                        }
                    }
                    .chartXAxis {
                        let dates: [Date] = periods.map { period in
                            Calendar.current.date(from: DateComponents(year: period.year, month: period.month, day: period.day)) ?? Date()
                        }
                        AxisMarks(values: dates) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(.footnote)
                                .foregroundStyle(colorScheme == .dark ? Color(red: 0.75, green: 0.65, blue: 0.38) : Color(red: 0.20, green: 0.40, blue: 0.28))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.gray.opacity(0.4))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(abbreviatedAmount(amount))
                                        .font(.footnote)
                                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.65, green: 0.55, blue: 0.30) : Color(red: 0.20, green: 0.40, blue: 0.28))
                                        .padding(.trailing, 6)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, 24)
                    .padding([.horizontal, .bottom], 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        MiniBarChartIcon()
                        Text("Growth Summary")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Balance

struct EditBalanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var balance: Balance
    @State private var amountText: String = ""
    @State private var isRenaming = false
    @State private var renameText: String = ""
    @FocusState private var renameFieldFocused: Bool
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    private var isDuplicateName: Bool {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        return categories.contains { $0.id != balance.category?.id && $0.name.lowercased() == trimmed }
    }
    
    private var nameHasChanged: Bool {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        return trimmed != (balance.category?.name ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isRenaming {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                TextField("Account name", text: $renameText)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .autocorrectionDisabled()
                                    .focused($renameFieldFocused)
                                    .onChange(of: renameText) { _, newValue in
                                        if newValue.count > 15 { renameText = String(newValue.prefix(15)) }
                                    }
                                Button {
                                    let name = renameText.trimmingCharacters(in: .whitespaces)
                                    if !name.isEmpty && !isDuplicateName {
                                        balance.category?.name = name
                                    }
                                    isRenaming = false
                                } label: {
                                    Text("Done")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(nameHasChanged ? .blue : .secondary)
                                }
                                .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicateName)
                            }
                            if isDuplicateName {
                                Text("Name already exists")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    } else {
                        HStack {
                            Text(balance.category?.name ?? "Amount")
                                .font(.body)
                            Spacer()
                            Button {
                                renameText = balance.category?.name ?? ""
                                isRenaming = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    renameFieldFocused = true
                                }
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        Text(currencySymbol)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .font(.title3)
                            .onChange(of: amountText) { _, newValue in
                                let filtered = filterAmountInput(newValue)
                                if filtered != newValue { amountText = filtered }
                            }
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
                
                if let updatedAt = balance.updatedAt {
                    Section {
                        Text("Last edited: \(updatedAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        MiniBarChartIcon()
                        Text("Edit Balance")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        let raw = amountText.replacingOccurrences(of: ",", with: "")
                        if let amount = Double(raw), amount >= 0 {
                            balance.amount = amount
                            balance.updatedAt = Date()
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.22, green: 0.38, blue: 0.55))
                    .shadow(color: Color(red: 0.22, green: 0.38, blue: 0.55).opacity(0.4), radius: 4, x: 0, y: 2)
                    .controlSize(.small)
                    .disabled({
                        let raw = amountText.replacingOccurrences(of: ",", with: "")
                        guard let amount = Double(raw), amount >= 0 else { return true }
                        return false
                    }())
                }
            }
            .onAppear {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                if balance.amount.truncatingRemainder(dividingBy: 1) == 0 {
                    formatter.maximumFractionDigits = 0
                } else {
                    formatter.maximumFractionDigits = 2
                    formatter.minimumFractionDigits = 2
                }
                amountText = formatter.string(from: NSNumber(value: balance.amount)) ?? String(format: "%.2f", balance.amount)
            }
        }
    }
}

// MARK: - Manage Category

struct ManageCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    var category: Category
    @State private var newName: String = ""
    
    private var isDuplicateName: Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespaces).lowercased()
        return categories.contains { $0.id != category.id && $0.name.lowercased() == trimmed }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rename") {
                    TextField("Account name", text: $newName)
                        .autocorrectionDisabled()
                        .onChange(of: newName) { _, newValue in
                            if newValue.count > 15 { newName = String(newValue.prefix(15)) }
                        }
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        MiniBarChartIcon()
                        Text("Account")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        let name = newName.trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty {
                            category.name = name
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.22, green: 0.38, blue: 0.55))
                    .shadow(color: Color(red: 0.22, green: 0.38, blue: 0.55).opacity(0.4), radius: 4, x: 0, y: 2)
                    .controlSize(.small)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicateName)
                }
            }
            .onAppear {
                newName = category.name
            }
        }
    }
}

// MARK: - Mini Bar Chart Icon

struct MiniBarChartIcon: View {
    var opacity: Double = 1.0
    var animating: Bool = true
    
    private let barColors: [Color] = [
        Color(red: 0.43, green: 0.60, blue: 0.76),  // #6e98c2
        Color(red: 0.54, green: 0.73, blue: 0.63),  // #8abba2
        Color(red: 0.76, green: 0.68, blue: 0.58),  // #c2ad95
    ]
    
    private let barHeights: [CGFloat] = [4, 8, 14.4]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColors[index].opacity(opacity))
                    .frame(width: 4, height: animating ? barHeights[index] : 0)
            }
        }
        .frame(width: 16, height: 16)
    }
}

// MARK: - Mini Line Chart Icon

struct MiniLineChartIcon: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 1, y: 13))
            path.addLine(to: CGPoint(x: 5, y: 9))
            path.addLine(to: CGPoint(x: 9, y: 11))
            path.addLine(to: CGPoint(x: 15, y: 3))
        }
        .stroke(moneyGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 16, height: 16)
    }
}

// MARK: - Add Account

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    let selectedPeriod: (year: Int, month: Int, day: Int)?
    
    @State private var accountName = ""
    @State private var balanceText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Name") {
                    TextField("Account name", text: $accountName)
                        .font(.title3)
                        .autocorrectionDisabled()
                        .onChange(of: accountName) { _, newValue in
                            if newValue.count > 15 { accountName = String(newValue.prefix(15)) }
                        }
                }
                
                Section("Initial Balance") {
                    HStack {
                        Text(currencySymbol)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $balanceText)
                            .font(.title3)
                            .onChange(of: balanceText) { _, newValue in
                                let filtered = filterAmountInput(newValue)
                                if filtered != newValue { balanceText = filtered }
                            }
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        MiniBarChartIcon()
                        Text("Add Account")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { save() }) {
                        Text("Add")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.22, green: 0.38, blue: 0.55))
                    .shadow(color: Color(red: 0.22, green: 0.38, blue: 0.55).opacity(0.4), radius: 4, x: 0, y: 2)
                        .controlSize(.small)
                        .disabled(accountName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicateName || {
                            let raw = balanceText.replacingOccurrences(of: ",", with: "")
                            guard let amount = Double(raw), amount > 0 else { return true }
                            return false
                        }())
                }
            }
        }
    }
    
    private var isDuplicateName: Bool {
        let trimmed = accountName.trimmingCharacters(in: .whitespaces).lowercased()
        return categories.contains { $0.name.lowercased() == trimmed }
    }
    
    private func save() {
        let name = accountName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let maxOrder = (categories.map(\.sortOrder).max() ?? 0) + 1
        let category = Category(name: name, sortOrder: maxOrder)
        modelContext.insert(category)
        
        if let period = selectedPeriod {
            let raw = balanceText.replacingOccurrences(of: ",", with: "")
            if let amount = Double(raw), amount >= 0 {
                let balance = Balance(category: category, year: period.year, month: period.month, day: period.day, amount: amount)
                modelContext.insert(balance)
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, color: Color, rotation: Double, size: CGFloat)] = []
    
    private let colors: [Color] = [
        Color(red: 0.43, green: 0.60, blue: 0.76),
        Color(red: 0.54, green: 0.73, blue: 0.63),
        Color(red: 0.76, green: 0.68, blue: 0.58),
        Color(red: 0.60, green: 0.53, blue: 0.76),
        Color(red: 0.76, green: 0.58, blue: 0.58),
        Color(red: 0.22, green: 0.48, blue: 0.34),
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 0.6)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func createParticles(in size: CGSize) {
        for i in 0..<80 {
            let startX = CGFloat.random(in: 0...size.width)
            let startY: CGFloat = -20
            let color = colors.randomElement()!
            let rotation = Double.random(in: 0...360)
            let particleSize = CGFloat.random(in: 6...12)
            
            particles.append((id: i, x: startX, y: startY, color: color, rotation: rotation, size: particleSize))
            
            let endY = size.height + 50
            let drift = CGFloat.random(in: -60...60)
            let delay = Double.random(in: 0...0.5)
            
            withAnimation(.easeIn(duration: Double.random(in: 1.5...2.5)).delay(delay)) {
                particles[i].y = endY
                particles[i].x = startX + drift
                particles[i].rotation = rotation + Double.random(in: 180...720)
            }
        }
    }
}

// MARK: - Speech Bubble Shape

struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailWidth: CGFloat = 12
        let tailHeight: CGFloat = 10
        let tailOffset: CGFloat = rect.width * 0.7 + 24
        
        var path = Path()
        let bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        
        // Start at top-left corner
        path.move(to: CGPoint(x: bodyRect.minX + radius, y: bodyRect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.minY))
        path.addArc(center: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.minY + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        
        // Right edge
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - radius))
        path.addArc(center: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.maxY - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        // Bottom edge with tail gap
        path.addLine(to: CGPoint(x: tailOffset + tailWidth, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: tailOffset + tailWidth / 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailOffset, y: bodyRect.maxY))
        
        // Continue bottom edge
        path.addLine(to: CGPoint(x: bodyRect.minX + radius, y: bodyRect.maxY))
        path.addArc(center: CGPoint(x: bodyRect.minX + radius, y: bodyRect.maxY - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        // Left edge
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + radius))
        path.addArc(center: CGPoint(x: bodyRect.minX + radius, y: bodyRect.minY + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Quote View

struct QuoteView: View {
    @State private var currentQuote: (text: String, author: String)
    @State private var quoteOpacity: Double = 1.0
    
    private static let quotes: [(String, String)] = [
        ("Do not save what is left after spending, but spend what is left after saving.", "— Warren Buffett"),
        ("A penny saved is a penny earned.", "— Benjamin Franklin"),
        ("Wealth is not about having a lot of money; it's about having a lot of options.", "— Chris Rock"),
        ("Financial freedom is available to those who learn about it and work for it.", "— Robert Kiyosaki"),
        ("It's not your salary that makes you rich, it's your spending habits.", "— Charles A. Jaffe"),
        ("Save money and money will save you.", "— Jamaican Proverb"),
        ("Compound interest is the eighth wonder of the world.", "— Albert Einstein"),
        ("An investment in knowledge pays the best interest.", "— Benjamin Franklin"),
        ("Never spend your money before you have earned it.", "— Thomas Jefferson"),
        ("The more you learn, the more you earn.", "— Warren Buffett"),
    ]
    
    init() {
        let q = Self.quotes.randomElement()!
        _currentQuote = State(initialValue: (text: q.0, author: q.1))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(currentQuote.text)\"")
                    .font(.footnote)
                    .italic()
                    .foregroundColor(.secondary)
                
                Text(currentQuote.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: 260)
            .opacity(quoteOpacity)
            
            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
    }
    
    private func refresh() {
        withAnimation(.easeOut(duration: 0.2)) {
            quoteOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let q = Self.quotes.randomElement()!
            currentQuote = (text: q.0, author: q.1)
            withAnimation(.easeIn(duration: 0.3)) {
                quoteOpacity = 1
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Balance.self], inMemory: true)
}
