//
//  CalendarPopover.swift
//  Calendr
//

import SwiftUI

// MARK: - CalendarPopover

struct CalendarPopover: View {

    @Binding var selection: Date
    var minDate: Date? = nil
    var onClose: () -> Void

    @State private var displayedMonth: Date

    private static let weekdayLabels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    init(selection: Binding<Date>, minDate: Date? = nil, onClose: @escaping () -> Void) {
        self._selection = selection
        self.minDate = minDate
        self.onClose = onClose
        self._displayedMonth = State(initialValue: Self.startOfMonth(for: selection.wrappedValue))
    }

    private static func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    private let cal = Calendar.current
    @State private var slideForward = true

    private var monthTitle: String {
        let comps = cal.dateComponents([.month, .year], from: displayedMonth)
        return "Tháng \(comps.month ?? 0) \(comps.year ?? 0)"
    }

    // 42 cells (6 rows × 7 cols) with prev/next month padding
    private var gridDays: [DayItem] {
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        // 1=Sun … 7=Sat — column index for first day (CN is column 0)
        let leadingCount = cal.component(.weekday, from: displayedMonth) - 1

        var items: [DayItem] = []

        for i in stride(from: leadingCount, through: 1, by: -1) {
            if let d = cal.date(byAdding: .day, value: -i, to: displayedMonth) {
                items.append(DayItem(date: d, kind: .other))
            }
        }
        for i in 0 ..< daysInMonth {
            if let d = cal.date(byAdding: .day, value: i, to: displayedMonth) {
                items.append(DayItem(date: d, kind: .current))
            }
        }
        let trailing = 42 - items.count
        if trailing > 0, let last = items.last?.date {
            for i in 1 ... trailing {
                if let d = cal.date(byAdding: .day, value: i, to: last) {
                    items.append(DayItem(date: d, kind: .other))
                }
            }
        }
        return items
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    }

    var body: some View {
        VStack(spacing: 6) {
            // ── Month navigation header ──────────────────────────────
            HStack(spacing: 0) {
                navButton("chevron.left")  { prevMonth() }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                navButton("chevron.right") { nextMonth() }
            }

            // ── Weekday labels ───────────────────────────────────────
            LazyVGrid(columns: gridColumns, spacing: 1) {
                ForEach(Self.weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // ── Day grid (slide animation on month change) ───────────
            LazyVGrid(columns: gridColumns, spacing: 1) {
                ForEach(gridDays) { item in
                    let isSelected  = cal.isDate(item.date, inSameDayAs: selection)
                    let isToday     = cal.isDateInToday(item.date)
                    let isDisabled  = minDate.map {
                        cal.compare(item.date, to: $0, toGranularity: .day) == .orderedAscending
                    } ?? false

                    DayCellView(
                        day: cal.component(.day, from: item.date),
                        isSelected: isSelected,
                        isToday: isToday,
                        isOtherMonth: item.kind == .other,
                        isDisabled: isDisabled
                    ) {
                        selection = mergeDate(item.date, withTimeFrom: selection)
                        onClose()
                    }
                }
            }
            .id(displayedMonth)
            .transition(.asymmetric(
                insertion: .move(edge: slideForward ? .trailing : .leading).combined(with: .opacity),
                removal:   .move(edge: slideForward ? .leading  : .trailing).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.2), value: displayedMonth)
            .clipped()

            // ── "Hôm nay" button ─────────────────────────────────────
            HStack {
                Spacer()
                Button("Hôm nay") {
                    let today = Date.now
                    selection = mergeDate(today, withTimeFrom: selection)
                    displayedMonth = Self.startOfMonth(for: today)
                    onClose()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding(8)
        .frame(width: 210)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func navButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func prevMonth() {
        slideForward = false
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }

    private func nextMonth() {
        slideForward = true
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }

    // Keep the time from `timeSrc` while using the date part of `dateTarget`
    private func mergeDate(_ dateTarget: Date, withTimeFrom timeSrc: Date) -> Date {
        var comps = cal.dateComponents([.year, .month, .day], from: dateTarget)
        let time  = cal.dateComponents([.hour, .minute, .second], from: timeSrc)
        comps.hour = time.hour; comps.minute = time.minute; comps.second = time.second
        return cal.date(from: comps) ?? dateTarget
    }
}

// MARK: - DayItem

private struct DayItem: Identifiable {
    enum Kind { case current, other }
    let date: Date
    let kind: Kind
    var id: Date { date }
}

// MARK: - DayCellView

private struct DayCellView: View {
    let day: Int
    let isSelected:   Bool
    let isToday:      Bool
    let isOtherMonth: Bool
    let isDisabled:   Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(day)")
                .font(.system(size: 10.5, weight: isSelected || isToday ? .bold : .regular))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(cellBackground)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var foregroundColor: Color {
        if isSelected                   { return .white }
        if isDisabled || isOtherMonth   { return Color.secondary.opacity(0.5) }
        if isToday                      { return Color.accentColor }
        return .primary
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    @Previewable @State var date = Date.now
    CalendarPopover(selection: $date, onClose: {})
        .background(.regularMaterial)
}

#endif
