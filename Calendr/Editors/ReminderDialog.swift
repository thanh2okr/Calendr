//
//  ReminderDialog.swift
//  Calendr
//

import SwiftUI

// MARK: - Models

enum ReminderKind: String, CaseIterable, Identifiable {
    case reminder, event
    var id: String { rawValue }
    var label: String { self == .reminder ? "Lời nhắc" : "Sự kiện" }
    var systemImage: String { self == .reminder ? "circle.inset.filled" : "calendar" }
}

enum ReminderPriority: String, CaseIterable, Identifiable {
    case none, low, medium, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none:   "Không"
        case .low:    "Thấp"
        case .medium: "Trung bình"
        case .high:   "Cao"
        }
    }
    var ekPriority: Int {
        switch self { case .none: 0; case .low: 9; case .medium: 5; case .high: 1 }
    }
    var systemImage: String {
        switch self {
        case .none, .low: "flag"
        case .medium:     "flag.fill"
        case .high:       "flag.2.crossed.fill"
        }
    }
    var color: Color {
        switch self {
        case .none:   .secondary
        case .low:    .yellow
        case .medium: .orange
        case .high:   .red
        }
    }
}

struct DialogCalendarItem: Identifiable, Hashable {
    let id: String
    let name: String
    let group: String
    let color: Color
}

struct ReminderDialogResult {
    var kind: ReminderKind
    var title: String
    var notes: String
    var calendarID: String
    var tags: [String]
    var priority: ReminderPriority
    var allDay: Bool
    var startDate: Date
    var endDate: Date
}

// MARK: - Main dialog

struct ReminderDialog: View {

    let reminderCalendars: [DialogCalendarItem]
    let eventCalendars: [DialogCalendarItem]
    var onSave: (ReminderDialogResult) -> Void = { _ in }
    var onCancel: () -> Void = {}
    var initialKind: ReminderKind = .reminder
    var initialDate: Date = .now

    @State private var kind: ReminderKind
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var reminderCalendarID: String
    @State private var eventCalendarID: String
    @State private var tags: [String] = []
    @State private var priority: ReminderPriority = .none
    @State private var allDay: Bool = false
    @State private var startDate: Date
    @State private var endDate: Date

    init(
        reminderCalendars: [DialogCalendarItem],
        eventCalendars: [DialogCalendarItem],
        onSave: @escaping (ReminderDialogResult) -> Void,
        onCancel: @escaping () -> Void,
        initialKind: ReminderKind = .reminder,
        initialDate: Date = .now
    ) {
        self.reminderCalendars = reminderCalendars
        self.eventCalendars = eventCalendars
        self.onSave = onSave
        self.onCancel = onCancel
        self.initialKind = initialKind
        self.initialDate = initialDate

        _kind = State(initialValue: initialKind)
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate.addingTimeInterval(3600))
        _reminderCalendarID = State(initialValue: reminderCalendars.first?.id ?? "")
        _eventCalendarID = State(initialValue: eventCalendars.first?.id ?? "")
    }

    private var currentCalendars: [DialogCalendarItem] { kind == .event ? eventCalendars : reminderCalendars }
    private var currentCalendarID: Binding<String> { kind == .event ? $eventCalendarID : $reminderCalendarID }
    private var currentItem: DialogCalendarItem {
        let id = kind == .event ? eventCalendarID : reminderCalendarID
        return currentCalendars.first(where: { $0.id == id })
            ?? currentCalendars.first
            ?? .init(id: "", name: "", group: "", color: .accentColor)
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 0) {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 14)

                Spacer()

                Text(kind == .event ? "Sự kiện mới" : "Nhắc nhở mới")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                // Balance spacer to keep title centered
                Color.clear.frame(width: 27)
            }
            .frame(height: 38)
            .overlay(Divider(), alignment: .bottom)

            VStack(alignment: .leading, spacing: 0) {

                Picker("", selection: $kind) {
                    ForEach(ReminderKind.allCases) { k in
                        SwiftUI.Label(k.label, systemImage: k.systemImage).tag(k)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
                .padding(.bottom, 8)

                ReminderTitleCard(title: $title, notes: $notes, kind: kind, dotColor: currentItem.color)
                    .padding(.bottom, 8)

                Divider()

                // Date rows — start always shown; end only for events; all-day always shown
                DialogRow(label: kind == .reminder ? "Lịch hẹn" : "Bắt đầu") {
                    DatePickerRow(date: $startDate, showTime: !allDay)
                }
                if kind == .event {
                    Divider()
                    DialogRow(label: "Kết thúc") {
                        DatePickerRow(date: $endDate, showTime: !allDay, minDate: startDate)
                    }
                }
                Divider()
                DialogRow(label: "Cả ngày") {
                    Toggle("", isOn: $allDay).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                }

                Divider()

                if !currentCalendars.isEmpty {
                    DialogRow(label: "Lịch") {
                        ReminderCalendarMenu(items: currentCalendars, selection: currentCalendarID)
                    }
                    Divider()
                }

                if kind == .reminder {
                    DialogRow(label: "Hashtag", align: .top) {
                        ReminderHashtagField(tags: $tags)
                    }
                    Divider()
                }

                DialogRow(label: "Ưu tiên") {
                    ReminderPriorityMenu(selection: $priority)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity, alignment: .top)

            HStack {
                Spacer()
                Button("Hủy") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Thêm") {
                    onSave(ReminderDialogResult(
                        kind: kind, title: title, notes: notes,
                        calendarID: kind == .event ? eventCalendarID : reminderCalendarID,
                        tags: tags, priority: priority, allDay: allDay,
                        startDate: startDate, endDate: endDate
                    ))
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.primary.opacity(0.05))
            .overlay(Divider(), alignment: .top)
        }
        .frame(width: 420, height: 460)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 40, y: 16)
        .onChange(of: reminderCalendars) { _, newCalendars in
            if reminderCalendarID.isEmpty, let first = newCalendars.first {
                reminderCalendarID = first.id
            }
        }
        .onChange(of: eventCalendars) { _, newCalendars in
            if eventCalendarID.isEmpty, let first = newCalendars.first {
                eventCalendarID = first.id
            }
        }
    }
}

// MARK: - Components

/// Row căn trái: [label 60px] [content]
private struct DialogRow<Content: View>: View {
    let label: String
    var align: VerticalAlignment = .center
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: align, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct ReminderTitleCard: View {
    @Binding var title: String
    @Binding var notes: String
    let kind: ReminderKind
    let dotColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 9) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 9, height: 9)
                    .padding(.top, 5)
                TextField(
                    kind == .event ? "Tiêu đề sự kiện" : "Tiêu đề lời nhắc",
                    text: $title,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1...3)
            }

            Divider().padding(.leading, 18).padding(.top, 6)

            TextField("Ghi chú…", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1...4)
                .padding(.leading, 18)
                .padding(.top, 6)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.primary.opacity(0.08), lineWidth: 0.5))
    }
}

/// Chip-style menu button shared by calendar and priority pickers.
private struct ChipMenu<Icon: View, Content: View>: View {
    @ViewBuilder let icon: () -> Icon
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu { content() } label: {
            HStack(spacing: 6) {
                icon()
                Text(label).font(.system(size: 12.5, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 7).fill(.primary.opacity(0.08)))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct ReminderCalendarMenu: View {
    let items: [DialogCalendarItem]
    @Binding var selection: String

    // Computed once per init — items is a `let`, never mutates after creation.
    private let grouped: [(String, [DialogCalendarItem])]

    init(items: [DialogCalendarItem], selection: Binding<String>) {
        self.items = items
        self._selection = selection
        self.grouped = Dictionary(grouping: items, by: \.group).sorted { $0.key < $1.key }
    }

    private var current: DialogCalendarItem {
        items.first { $0.id == selection } ?? items[0]
    }

    var body: some View {
        ChipMenu(
            icon: { Circle().fill(current.color).frame(width: 9, height: 9) },
            label: current.name
        ) {
            ForEach(grouped, id: \.0) { group, list in
                Section(group) {
                    ForEach(list) { item in
                        Button { selection = item.id } label: {
                            SwiftUI.Label { Text(item.name) } icon: { Circle().fill(item.color) }
                        }
                    }
                }
            }
        }
    }
}

private struct ReminderPriorityMenu: View {
    @Binding var selection: ReminderPriority

    var body: some View {
        ChipMenu(
            icon: {
                Image(systemName: selection.systemImage)
                    .foregroundStyle(selection.color)
                    .font(.system(size: 11))
            },
            label: selection.label
        ) {
            ForEach(ReminderPriority.allCases) { p in
                Button { selection = p } label: {
                    SwiftUI.Label {
                        Text(p.label)
                    } icon: {
                        Image(systemName: p.systemImage).foregroundStyle(p.color)
                    }
                }
            }
        }
    }
}

private struct ReminderHashtagField: View {
    @Binding var tags: [String]
    @State private var draft: String = ""

    var body: some View {
        ReminderFlowLayout(spacing: 4) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 3) {
                    Text("#\(tag)")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.blue)
                    Button { tags.removeAll { $0 == tag } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                .padding(.leading, 7).padding(.trailing, 3).padding(.vertical, 2)
                .background(Capsule().fill(.blue.opacity(0.12)))
                .overlay(Capsule().stroke(.blue.opacity(0.25), lineWidth: 0.5))
            }
            TextField("# thêm hashtag…", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onSubmit { commit() }
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7).fill(.primary.opacity(0.05)))
    }

    private func commit() {
        let t = draft.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "").lowercased()
        if !t.isEmpty && !tags.contains(t) { tags.append(t) }
        draft = ""
    }
}

private struct ReminderFlowLayout: Layout {
    var spacing: CGFloat = 4

    // Cache subview sizes so placeSubviews doesn't remeasure.
    struct Cache { var sizes: [CGSize] = [] }
    func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sz in cache.sizes {
            if x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let maxW = bounds.width
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for (sv, sz) in zip(subviews, cache.sizes) {
            if x - bounds.minX + sz.width > maxW { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

// MARK: - DatePickerRow

/// Text-field stepper + calendar icon that opens a floating popover.
/// Popover has a graphical calendar (date) and, when showTime, a separate
/// field picker for time — avoiding the macOS 26 inline-overlay issue.
private struct DatePickerRow: View {
    @Binding var date: Date
    var showTime: Bool = true
    var minDate: Date? = nil

    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 8) {
            NativeDatePicker(selection: $date, showTime: showTime, minDate: minDate)
            Button { showPopover.toggle() } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(showPopover ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                DatePickerPopover(date: $date, showTime: showTime, minDate: minDate) {
                    showPopover = false
                }
            }
        }
    }
}

private struct DatePickerPopover: View {
    @Binding var date: Date
    var showTime: Bool
    var minDate: Date?
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Graphical calendar — date only
            Group {
                if let min = minDate {
                    DatePicker("", selection: $date, in: min..., displayedComponents: .date)
                } else {
                    DatePicker("", selection: $date, displayedComponents: .date)
                }
            }
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if showTime {
                Divider()
                HStack {
                    Text("Giờ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.field)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()
            HStack {
                Spacer()
                Button("Xong") { onDone() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(8)
        }
        .frame(width: 260)
    }
}

// MARK: - NativeDatePicker

/// NSDatePicker wrapped in NSViewRepresentable using .textFieldAndStepper style.
/// Calendar overlay disabled — DatePickerRow handles it via SwiftUI popover instead.
private struct NativeDatePicker: NSViewRepresentable {
    @Binding var selection: Date
    var showTime: Bool = true
    var minDate: Date? = nil

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textFieldAndStepper
        picker.presentsCalendarOverlay = false
        picker.isBezeled = false
        picker.isBordered = false
        picker.drawsBackground = false
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }

    func updateNSView(_ picker: NSDatePicker, context: Context) {
        picker.datePickerElements = showTime ? [.yearMonthDay, .hourMinute] : .yearMonthDay
        if let min = minDate { picker.minDate = min }
        if picker.dateValue != selection { picker.dateValue = selection }
        context.coordinator.selection = $selection
    }

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    class Coordinator: NSObject {
        var selection: Binding<Date>
        init(selection: Binding<Date>) { self.selection = selection }
        @objc func dateChanged(_ picker: NSDatePicker) { selection.wrappedValue = picker.dateValue }
    }
}

// MARK: - Helpers

extension CalendarModel {
    var asDialogItem: DialogCalendarItem {
        DialogCalendarItem(id: id, name: title, group: account.title, color: Color(nsColor: color))
    }
}

extension [CalendarSection] {
    func asDialogItems() -> [DialogCalendarItem] {
        flatMap { $0.calendars.map { $0.asDialogItem } }
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    ReminderDialog(
        reminderCalendars: [
            .init(id: "1", name: "Nhắc nhở", group: "iCloud", color: .blue),
            .init(id: "2", name: "Công việc", group: "iCloud", color: .red),
        ],
        eventCalendars: [
            .init(id: "3", name: "Lịch", group: "iCloud", color: .green),
        ],
        onSave: { _ in },
        onCancel: {}
    )
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}

#endif
