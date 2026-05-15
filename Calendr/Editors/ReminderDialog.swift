//
//  ReminderDialog.swift
//  Calendr
//
//  Adapted from user's SwiftUI design — works as an NSWindow-hosted SwiftUI view
//  (no fake window chrome; HostingWindowController provides the real chrome).
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
    /// EKReminder.priority value (0 = none, 1 = high, 5 = medium, 9 = low)
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
        return currentCalendars.first(where: { $0.id == id }) ?? currentCalendars.first ?? .init(id: "", name: "", group: "", color: .accentColor)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Title bar
            Text(kind == .event ? "Sự kiện mới" : "Nhắc nhở mới")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .overlay(Divider(), alignment: .bottom)

            // Body
            VStack(spacing: 8) {

                // Kind segmented picker
                Picker("", selection: $kind) {
                    ForEach(ReminderKind.allCases) { k in
                        SwiftUI.Label(k.label, systemImage: k.systemImage).tag(k)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
                .padding(.top, 6)

                // Title + Notes card
                ReminderTitleNotesCard(title: $title, notes: $notes,
                                       kind: kind, dotColor: currentItem.color)

                // Date rows
                if kind == .reminder {
                    MetaRow(label: "Lịch hẹn") {
                        DatePicker("", selection: $startDate,
                                   displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                        Spacer()
                        Text("Cả ngày").font(.caption).foregroundStyle(.secondary)
                        Toggle("", isOn: $allDay).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                    }
                } else {
                    MetaRow(label: "Bắt đầu") {
                        DatePicker("", selection: $startDate,
                                   displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                        Spacer()
                        Text("Cả ngày").font(.caption).foregroundStyle(.secondary)
                        Toggle("", isOn: $allDay).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                    }
                    Divider()
                    MetaRow(label: "Kết thúc") {
                        DatePicker("", selection: $endDate,
                                   in: startDate...,
                                   displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
                Divider()

                // Calendar picker
                if !currentCalendars.isEmpty {
                    MetaRow(label: "Lịch") {
                        ReminderCalendarMenu(items: currentCalendars, selection: currentCalendarID)
                    }
                    Divider()
                }

                // Hashtags (reminders only)
                if kind == .reminder {
                    MetaRow(label: "Hashtag", align: .top) {
                        ReminderHashtagField(tags: $tags)
                    }
                    Divider()
                }

                // Priority
                MetaRow(label: "Ưu tiên") {
                    ReminderPriorityMenu(selection: $priority)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxHeight: .infinity, alignment: .top)

            // Footer
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
            .background(.black.opacity(0.06))
            .overlay(Divider(), alignment: .top)
        }
        .frame(width: 440, height: 420)
    }
}

// MARK: - Components

private struct ReminderTitleNotesCard: View {
    @Binding var title: String
    @Binding var notes: String
    let kind: ReminderKind
    let dotColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Circle().fill(dotColor).frame(width: 9, height: 9)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 3) {
                TextField(kind == .event ? "Tiêu đề sự kiện" : "Tiêu đề lời nhắc",
                          text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1...3)
                TextField("Mô tả chi tiết, ghi chú thêm…",
                          text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1...4)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 11).fill(.primary.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(.primary.opacity(0.08), lineWidth: 0.5))
    }
}

private struct MetaRow<Content: View>: View {
    let label: String
    var align: VerticalAlignment = .center
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: align, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)
            HStack(spacing: 6) { content() }
        }
        .padding(.vertical, 4)
    }
}

private struct ReminderCalendarMenu: View {
    let items: [DialogCalendarItem]
    @Binding var selection: String

    var current: DialogCalendarItem { items.first { $0.id == selection } ?? items[0] }
    var grouped: [(String, [DialogCalendarItem])] {
        Dictionary(grouping: items, by: \.group).sorted { $0.key < $1.key }
    }

    var body: some View {
        Menu {
            ForEach(grouped, id: \.0) { group, list in
                Section(group) {
                    ForEach(list) { item in
                        Button { selection = item.id } label: {
                            SwiftUI.Label {
                                Text(item.name)
                            } icon: {
                                Circle().fill(item.color)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Circle().fill(current.color).frame(width: 10, height: 10)
                Text(current.name).font(.system(size: 12.5, weight: .semibold))
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.18)))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct ReminderPriorityMenu: View {
    @Binding var selection: ReminderPriority
    var body: some View {
        Menu {
            ForEach(ReminderPriority.allCases) { p in
                Button { selection = p } label: {
                    SwiftUI.Label {
                        Text(p.label)
                    } icon: {
                        Image(systemName: p.systemImage)
                            .foregroundStyle(p.color)
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: selection.systemImage)
                    .foregroundStyle(selection.color)
                    .font(.system(size: 12))
                Text(selection.label).font(.system(size: 12.5, weight: .semibold))
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.18)))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct ReminderHashtagField: View {
    @Binding var tags: [String]
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
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
                    .background(Capsule().fill(.blue.opacity(0.15)))
                    .overlay(Capsule().stroke(.blue.opacity(0.30), lineWidth: 0.5))
                }
                TextField("# thêm hashtag…", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .onSubmit { commit() }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.14)))
        }
    }

    private func commit() {
        let t = draft.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "").lowercased()
        if !t.isEmpty && !tags.contains(t) { tags.append(t) }
        draft = ""
    }
}

// MARK: - FlowLayout

private struct ReminderFlowLayout: Layout {
    var spacing: CGFloat = 4
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x - bounds.minX + sz.width > maxW {
                x = bounds.minX; y += rowH + spacing; rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
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
        flatMap { section in
            section.calendars.map { $0.asDialogItem }
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Dialog") {
    ReminderDialog(
        reminderCalendars: [
            .init(id: "1", name: "Nhắc nhở", group: "iCloud", color: .blue),
            .init(id: "2", name: "Công việc", group: "iCloud", color: .red),
        ],
        eventCalendars: [
            .init(id: "3", name: "Lịch", group: "iCloud", color: .green),
        ],
        onSave: { print("Saved:", $0) },
        onCancel: { print("Cancelled") }
    )
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}

#endif
