//
//  TimePopover.swift
//  Calendr
//

import SwiftUI

struct TimePopover: View {

    @Binding var selection: String  // "HH:mm"
    var referenceDate: Date? = nil  // nếu có → hiện duration label ở mỗi slot
    var onClose: () -> Void

    // draft starts EMPTY so list shows all 48 slots on open (not filtered)
    @State private var draft: String = ""
    @State private var hoveredSlot: String? = nil
    @FocusState private var focused: Bool

    private let cal = Calendar.current

    private static let allSlots: [String] = (0 ..< 48).map { i in
        String(format: "%02d:%02d", i / 2, (i % 2) * 30)
    }

    // Pad single-digit hour before prefix-matching: "9" → "09", "9:3" → "09:3"
    private var filterPrefix: String {
        let t = draft.trimmingCharacters(in: .whitespaces)
        let hourPart: String
        if let colonIdx = t.firstIndex(of: ":") {
            hourPart = String(t[t.startIndex ..< colonIdx])
        } else {
            hourPart = t
        }
        return (hourPart.count == 1 && hourPart.first?.isNumber == true) ? "0" + t : t
    }

    private var filteredSlots: [String] {
        guard !draft.trimmingCharacters(in: .whitespaces).isEmpty else { return Self.allSlots }
        let prefix = filterPrefix
        return Self.allSlots.filter { $0.hasPrefix(prefix) }
    }

    var body: some View {
        VStack(spacing: 6) {

            // ── Text field ────────────────────────────────────────────
            TextField("HH:MM", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .focused($focused)
                .onSubmit { commitInput() }
                .onKeyPress(.escape) { onClose(); return .handled }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                        )
                )

            // ── Slot list ─────────────────────────────────────────────
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredSlots, id: \.self) { slot in
                            slotRow(slot).id(slot)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 168)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focused = true
                        if Self.allSlots.contains(selection) {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                }
                .onChange(of: draft) { _, _ in
                    // Only scroll when filter is actually active (draft non-empty)
                    guard !draft.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let slots = filteredSlots
                    guard let first = slots.first else { return }
                    let anchor: UnitPoint = slots.count == 1 ? .center : .top
                    proxy.scrollTo(first, anchor: anchor)
                }
            }
        }
        .padding(8)
        .frame(width: 140)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Slot row

    @ViewBuilder
    private func slotRow(_ slot: String) -> some View {
        let isSelected = slot == selection
        let isHovered  = hoveredSlot == slot && !isSelected
        let dur        = durationLabel(for: slot)

        Button {
            selection = slot
            onClose()
        } label: {
            HStack(spacing: 0) {
                Text(slot)
                    .font(.system(size: 11.5, weight: isSelected ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, alignment: dur == nil ? .center : .leading)
                    .padding(.leading, dur == nil ? 0 : 10)

                if let dur {
                    Text(dur)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color.secondary)
                        .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        isSelected ? Color.accentColor
                        : isHovered ? Color.gray.opacity(0.1)
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { over in hoveredSlot = over ? slot : nil }
    }

    // "1g", "30'", "1g30'" — tính từ referenceDate đến slot (same calendar day)
    private func durationLabel(for slot: String) -> String? {
        guard let ref = referenceDate else { return nil }
        let parts = slot.components(separatedBy: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        var comps = cal.dateComponents([.year, .month, .day], from: ref)
        comps.hour = h; comps.minute = m; comps.second = 0
        guard let slotDate = cal.date(from: comps) else { return nil }
        let totalMins = Int(slotDate.timeIntervalSince(ref) / 60)
        guard totalMins > 0 else { return nil }
        let hh = totalMins / 60, mm = totalMins % 60
        if hh == 0 { return "\(mm)'" }
        if mm == 0 { return "\(hh)g" }
        return "\(hh)g\(mm)'"
    }

    // MARK: - Commit

    private func commitInput() {
        let q = draft.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { onClose(); return }

        // 1. Prefer first slot in the filtered list
        if let first = filteredSlots.first {
            selection = first
            onClose()
            return
        }

        // 2. Fallback: normalize raw input, validate, commit
        let normalized = normalizeTime(q)
        if !normalized.isEmpty {
            selection = normalized
            onClose()
            return
        }

        // Nothing valid — close without changing selection
        onClose()
    }

    // MARK: - Normalize + Validate

    // Passes only if format is exactly HH:mm with valid hour/minute values
    private func isValid(_ s: String) -> Bool {
        s.range(of: #"^([0-1]\d|2[0-3]):[0-5]\d$"#, options: .regularExpression) != nil
    }

    // "9"→"09:00"  "9:5"→"09:05"  "9:30"→"09:30"  "9h30"→"09:30"  "1330"→"13:30"
    private func normalizeTime(_ raw: String) -> String {
        let t = raw.lowercased()

        // Vietnamese "h" separator: "9h30", "15h", "9h3"
        if let range = t.range(of: #"^(\d{1,2})h(\d{0,2})$"#, options: .regularExpression) {
            let parts = String(t[range]).components(separatedBy: "h")
            let h = Int(parts[0]) ?? -1
            let m = parts.count > 1 && !parts[1].isEmpty ? (Int(parts[1]) ?? -1) : 0
            if (0...23).contains(h) && (0...59).contains(m) {
                return validated(String(format: "%02d:%02d", h, m))
            }
        }

        // Colon-separated: "9:5", "9:30", "13:30"
        let cp = t.components(separatedBy: ":")
        if cp.count == 2, let h = Int(cp[0]), let m = Int(cp[1]),
           (0...23).contains(h) && (0...59).contains(m) {
            return validated(String(format: "%02d:%02d", h, m))
        }

        // Pure digits: "9" "13" "930" "1330"
        let digits = t.filter(\.isNumber)
        switch digits.count {
        case 1, 2:
            if let h = Int(digits), (0...23).contains(h) {
                return validated(String(format: "%02d:00", h))
            }
        case 3:
            if let h = Int(digits.prefix(1)), let m = Int(digits.suffix(2)),
               (0...23).contains(h) && (0...59).contains(m) {
                return validated(String(format: "%02d:%02d", h, m))
            }
        case 4:
            if let h = Int(digits.prefix(2)), let m = Int(digits.suffix(2)),
               (0...23).contains(h) && (0...59).contains(m) {
                return validated(String(format: "%02d:%02d", h, m))
            }
        default: break
        }

        return ""
    }

    private func validated(_ s: String) -> String { isValid(s) ? s : "" }
}

// MARK: - Preview

#if DEBUG

#Preview {
    @Previewable @State var time = "13:30"
    TimePopover(selection: $time, onClose: {})
}

#endif
