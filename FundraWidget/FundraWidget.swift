//
//  FundraWidget.swift
//  FundraWidget
//
//  Created by Brian Janish on 6/28/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Models (mirrored from main app for widget access)

@Model
final class Category {
    var name: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var balances: [Balance]
    
    init(name: String, sortOrder: Int) {
        self.name = name
        self.sortOrder = sortOrder
        self.balances = []
    }
}

@Model
final class Balance {
    var category: Category?
    var year: Int
    var month: Int
    var day: Int
    var amount: Double
    var updatedAt: Date?
    
    init(category: Category, year: Int, month: Int, day: Int, amount: Double) {
        self.category = category
        self.year = year
        self.month = month
        self.day = day
        self.amount = amount
        self.updatedAt = Date()
    }
}

// MARK: - Currency Formatting

private let currencySymbol: String = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.currencySymbol ?? "$"
}()

private func formatFullAmount(_ amount: Double) -> String {
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

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FundraEntry {
        FundraEntry(date: Date(), totalSavings: 12500, lastRecordedMonth: "Jun 2026", accountCount: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (FundraEntry) -> ()) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = fetchEntry()
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchEntry() -> FundraEntry {
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.fundra.shared")!
        let storeURL = groupURL.appending(path: "Fundra.store")
        
        do {
            let schema = Schema([Category.self, Balance.self])
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            
            let balanceDescriptor = FetchDescriptor<Balance>()
            let balances = try context.fetch(balanceDescriptor)
            
            let categoryDescriptor = FetchDescriptor<Category>()
            let categories = try context.fetch(categoryDescriptor)
            
            // Find the latest month
            let sorted = balances.sorted { ($0.year, $0.month) > ($1.year, $1.month) }
            let latestBalance = sorted.first
            
            // Total for latest month
            var totalSavings = 0.0
            var lastRecordedMonth = ""
            
            if let latest = latestBalance {
                let latestMonthBalances = balances.filter { $0.year == latest.year && $0.month == latest.month }
                totalSavings = latestMonthBalances.reduce(0) { $0 + $1.amount }
                
                let date = Calendar.current.date(from: DateComponents(year: latest.year, month: latest.month)) ?? Date()
                lastRecordedMonth = date.formatted(.dateTime.month(.abbreviated).year())
            }
            
            return FundraEntry(
                date: Date(),
                totalSavings: totalSavings,
                lastRecordedMonth: lastRecordedMonth,
                accountCount: categories.count
            )
        } catch {
            return FundraEntry(date: Date(), totalSavings: 0, lastRecordedMonth: "", accountCount: 0)
        }
    }
}

// MARK: - Entry

struct FundraEntry: TimelineEntry {
    let date: Date
    let totalSavings: Double
    let lastRecordedMonth: String
    let accountCount: Int
}

// MARK: - Widget View

struct FundraWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
    }
    
    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Branding
            HStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 1.5) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                        .frame(width: 3, height: 5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.54, green: 0.73, blue: 0.63))
                        .frame(width: 3, height: 9)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.76, green: 0.68, blue: 0.58))
                        .frame(width: 3, height: 13)
                }
                Text("Fundra")
                    .font(.system(size: 20, weight: .bold))
                    .italic()
                    .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
            }
            
            // Total savings
            if entry.accountCount > 0 {
                Text(formatFullAmount(entry.totalSavings))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.26, green: 0.54, blue: 0.38))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text(entry.lastRecordedMonth)
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4))
            } else {
                Text("Add accounts\nto get started")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    var mediumWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    HStack(alignment: .bottom, spacing: 1.5) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.43, green: 0.60, blue: 0.76))
                            .frame(width: 3, height: 5)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.54, green: 0.73, blue: 0.63))
                            .frame(width: 3, height: 9)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.76, green: 0.68, blue: 0.58))
                            .frame(width: 3, height: 13)
                    }
                    Text("Fundra")
                        .font(.system(size: 14, weight: .bold))
                        .italic()
                        .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
                }
                
                if entry.accountCount > 0 {
                    Text(formatFullAmount(entry.totalSavings))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.26, green: 0.54, blue: 0.38))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text("Total savings • \(entry.lastRecordedMonth)")
                        .font(.caption2)
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4))
                } else {
                    Text("Add accounts to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Widget Background

struct WidgetBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)
            : Color.white
    }
}

// MARK: - Widget Configuration

struct FundraWidget: Widget {
    let kind: String = "FundraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FundraWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("Fundra")
        .description("Your total savings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    FundraWidget()
} timeline: {
    FundraEntry(date: .now, totalSavings: 19120, lastRecordedMonth: "Jun 2026", accountCount: 6)
}

#Preview(as: .systemMedium) {
    FundraWidget()
} timeline: {
    FundraEntry(date: .now, totalSavings: 19120, lastRecordedMonth: "Jun 2026", accountCount: 6)
}
