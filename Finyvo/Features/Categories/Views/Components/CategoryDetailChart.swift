//
//  CategoryDetailChart.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/23/25.
//  Modular chart components para CategoryDetailSheet.
//  Integrated with Constants.Haptic, Constants.Animation and CurrencyConfig.
//

import SwiftUI
import Charts

// MARK: - Chart Container

struct CategoryDetailChart: View {
    let accentColor: Color
    @Binding var selectedMonth: Date

    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)

                    Text("Actividad del mes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                }

                Spacer()

                MonthYearPicker(selectedMonth: $selectedMonth)
            }

            SpendingChart(
                accentColor: accentColor,
                selectedMonth: selectedMonth
            )
            .frame(height: 160)
        }
    }
}

// MARK: - Spending Chart (Bar + Interaction)

struct SpendingChart: View {
    let accentColor: Color
    let selectedMonth: Date

    @Environment(\.colorScheme) private var colorScheme

    @State private var data: [DailySpending] = []
    @State private var rawSelectedDate: Date?
    @State private var isAnimating: Bool = false
    @State private var lastHapticDate: Date?

    private var selectedDay: DailySpending? {
        guard let rawSelectedDate else { return nil }
        return data.first { Calendar.current.isDate($0.date, inSameDayAs: rawSelectedDate) }
    }

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Día", item.date, unit: .day),
                    y: .value("Monto", isAnimating ? item.amount : 0)
                )
                .foregroundStyle(barGradient(for: item))
                .opacity(barOpacity(for: item))
                .clipShape(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                )
            }

            if let selected = selectedDay {
                RuleMark(x: .value("Día", selected.date, unit: .day))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(FColors.textTertiary.opacity(0.5))
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        ChartTooltip(spending: selected)
                    }
            }
        }
        .chartXSelection(value: $rawSelectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(dayLabel(for: date))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(FColors.textTertiary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxAmount * 1.4))
        .chartXScale(range: .plotDimension(padding: 8))
        .onChange(of: rawSelectedDate) { _, newValue in
            guard let newValue else { return }
            let dominated = lastHapticDate.map {
                Calendar.current.isDate($0, inSameDayAs: newValue)
            } ?? false
            if !dominated {
                lastHapticDate = newValue
                Task { @MainActor in Constants.Haptic.light() }
            }
        }
        .onChange(of: selectedMonth) { _, newMonth in
            withAnimation(Constants.Animation.easeOut) { isAnimating = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                data = DailySpending.generate(for: newMonth)
                rawSelectedDate = nil
                withAnimation(Constants.Animation.chartSpring) {
                    isAnimating = true
                }
            }
        }
        .onAppear {
            data = DailySpending.generate(for: selectedMonth)
            withAnimation(Constants.Animation.chartSpring.delay(0.2)) {
                isAnimating = true
            }
        }
    }

    private var maxAmount: Double { data.map(\.amount).max() ?? 1000 }

    private func barOpacity(for item: DailySpending) -> Double {
        guard rawSelectedDate != nil else { return 1.0 }
        return Calendar.current.isDate(item.date, inSameDayAs: rawSelectedDate ?? Date()) ? 1.0 : 0.35
    }

    private func barGradient(for item: DailySpending) -> LinearGradient {
        let selected = Calendar.current.isDate(item.date, inSameDayAs: rawSelectedDate ?? Date())
        return LinearGradient(
            colors: [
                accentColor.opacity(selected ? 1.0 : 0.8),
                accentColor.opacity(selected ? 0.7 : 0.4)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Chart Tooltip Popup

private struct ChartTooltip: View {
    let spending: DailySpending

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            Text(formattedDate)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(FColors.textTertiary)

            Text(formattedAmount)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FColors.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundTertiary : Color.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.12),
                    radius: 6, y: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
    }

    private var formattedDate: String {
        spending.date.dayMonthString
    }

    private var formattedAmount: String {
        spending.amount.asCompactCurrency()
    }
}

// MARK: - Daily Spending Model

private struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double

    static func generate(for month: Date) -> [DailySpending] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth),
                  date <= Date()
            else { return nil }

            let hasSpending = Double.random(in: 0...1) > 0.25
            return DailySpending(date: date, amount: hasSpending ? Double.random(in: 200...3500) : 0)
        }
    }
}

// MARK: - Month + Year Picker

struct MonthYearPicker: View {
    @Binding var selectedMonth: Date
    @Environment(\.colorScheme) private var colorScheme

    private let calendar = Calendar.current

    // Only show 3 years
    private var availableYears: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return [currentYear, currentYear - 1, currentYear - 2]
    }

    private var allMonths: [Int] { Array(1...12) }

    private var monthComponent: Int {
        calendar.component(.month, from: selectedMonth)
    }

    private var yearComponent: Int {
        calendar.component(.year, from: selectedMonth)
    }

    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppConfig.Defaults.localeIdentifier)
        return formatter.monthSymbols[month - 1].capitalized
    }

    private func isFuture(_ month: Int, year: Int) -> Bool {
        let cm = calendar.component(.month, from: Date())
        let cy = calendar.component(.year, from: Date())
        return year > cy || (year == cy && month > cm)
    }

    private func update(month: Int? = nil, year: Int? = nil) {
        let newMon = month ?? monthComponent
        let newYr  = year  ?? yearComponent
        if isFuture(newMon, year: newYr) { return }
        var comps = DateComponents(); comps.year = newYr; comps.month = newMon; comps.day = 1
        if let newDate = calendar.date(from: comps) {
            selectedMonth = newDate
            Task { @MainActor in Constants.Haptic.selection() }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Month with scrollable Menu
            Menu {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(allMonths, id: \.self) { m in
                            Button {
                                update(month: m)
                            } label: {
                                HStack {
                                    Text(monthName(for: m))
                                    if m == monthComponent { Spacer(); Image(systemName: "checkmark") }
                                }
                                .padding(.vertical, 6)
                            }
                            .disabled(isFuture(m, year: yearComponent))
                        }
                    }
                }
                .background(Color.clear)
            } label: {
                PickerPill(text: monthName(for: monthComponent), showChevron: true)
            }
            .menuOrder(.fixed)

            // Year (no comma formatting)
            Menu {
                VStack(spacing: 0) {
                    ForEach(availableYears, id: \.self) { y in
                        Button {
                            update(year: y)
                        } label: {
                            HStack {
                                Text(verbatim: "\(y)")
                                if y == yearComponent { Spacer(); Image(systemName: "checkmark") }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            } label: {
                PickerPill(text: "\(yearComponent)", showChevron: true)
            }
            .menuOrder(.fixed)
        }
    }
}

// MARK: - Small Picker Pill

struct PickerPill: View {
    let text: String
    var showChevron: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(FColors.textSecondary)

            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        )
    }
}
