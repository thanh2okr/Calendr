//
//  TimePopover.swift
//  Calendr
//

import SwiftUI

// MARK: - TimePopover

struct TimePopover: View {

    @Binding var selection: String   // "HH:mm"
    var referenceDate: Date? = nil
    var onClose: () -> Void

    /// draft bắt đầu rỗng → 48 slot hiện đầy đủ khi mở, không bị filter ngay
    @State private var draft: String = ""
    /// Precomputed once in onAppear — tránh gọi cal.date(from:) 48× mỗi render
    @State private var durationLabels: [String: String] = [:]
    @FocusState private var focused: Bool

    private let cal = Calendar.current

    // MARK: - Static data

    static let allSlots: [String] = (0 ..< 48).map {
        String(format: "%02d:%02d", $0 / 2, ($0 % 2) * 30)
    }

    /// Regex literal → compiled at build time, zero runtime cost
    private static let validRegex = /^([0-1]\d|2[0-3]):[0-5]\d$/

    // MARK: - Filtering

    /// Single trimmed copy, used in both filterPrefix and filteredSlots
    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespaces)
    }

    /// Pad single-digit hour: "9" → "09", "9:3" → "09:3"
    private var filterPrefix: String {
        let t = trimmedDraft
        let hourPart = t.prefix(while: { $0 != ":" })
        return hourPart.count == 1 && hourPart.first?.isNumber == true ? "0" + t : t
    }

    private var filteredSlots: [String] {
        guard !trimmedDraft.isEmpty else { return Self.allSlots }
        let prefix = filterPrefix
        return Self.allSlots.filter { $0.hasPrefix(prefix) }
    }

    /// Slot gần nhất với `selection` để scroll khi mở
    /// → hoạt động ngay cả khi selection là "13:15" (không phải slot tròn 30 phút)
    private var nearestSlot: String? {
        if Self.allSlots.contains(selection) { return selection }
        let parts = selection.split(separator: ":")
        guard parts.count == 2,
              let sh = Int(parts[0]), let sm = Int(parts[1]) else { return Self.allSlots.first }
        let selMins = sh * 60 + sm
        return Self.allSlots.min {
            let ap = $0.split(separator: ":"), bp = $1.split(separator: ":")
            let am = (Int(ap[0]) ?? 0) * 60 + (Int(ap[1]) ?? 0)
            let bm = (Int(bp[0]) ?? 0) * 60 + (Int(bp[1]) ?? 0)
            return abs(am - selMins) < abs(bm - selMins)
        }
    }

    // MARK: - Body

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
                            // SlotRowView manages its own hover state →
                            // hovering một slot không re-render các slot khác
                            SlotRowView(
                                slot: slot,
                                isSelected: slot == selection,
                                durationLabel: durationLabels[slot]
                            ) {
                                selection = slot
                                onClose()
                            }
                            .id(slot)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 168)
                .onAppear {
                    buildDurationLabels()   // chạy 1 lần, cache kết quả
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focused = true
                        if let target = nearestSlot {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
                .onChange(of: draft) { _, _ in
                    guard !trimmedDraft.isEmpty else { return }
                    let slots = filteredSlots
                    guard let first = slots.first else { return }
                    proxy.scrollTo(first, anchor: slots.count == 1 ? .center : .top)
                }
            }
        }
        .padding(8)
        .frame(width: 140)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Commit

    private func commitInput() {
        let q = trimmedDraft
        guard !q.isEmpty else { onClose(); return }

        // 1. Ưu tiên slot đầu tiên trong danh sách đã filter
        if let first = filteredSlots.first {
            selection = first; onClose(); return
        }

        // 2. Fallback: normalize thô → validate → commit
        let normalized = normalizeTime(q)
        if !normalized.isEmpty {
            selection = normalized; onClose(); return
        }

        onClose()  // không hợp lệ → chỉ đóng, không thay đổi selection
    }

    // MARK: - Duration labels (precomputed)

    private func buildDurationLabels() {
        guard let ref = referenceDate else { return }
        var result: [String: String] = [:]
        for slot in Self.allSlots {
            let parts = slot.split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]), let m = Int(parts[1]) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: ref)
            comps.hour = h; comps.minute = m; comps.second = 0
            guard let slotDate = cal.date(from: comps) else { continue }
            let mins = Int(slotDate.timeIntervalSince(ref) / 60)
            guard mins > 0 else { continue }
            let hh = mins / 60, mm = mins % 60
            result[slot] = hh == 0 ? "\(mm)'" : mm == 0 ? "\(hh)g" : "\(hh)g\(mm)'"
        }
        durationLabels = result
    }

    // MARK: - Normalize + Validate

    private func isValid(_ s: String) -> Bool {
        (try? Self.validRegex.wholeMatch(in: s)) != nil
    }

    /// "9"→"09:00"  "9:5"→"09:05"  "9h30"→"09:30"  "930"→"09:30"  "1330"→"13:30"
    private func normalizeTime(_ raw: String) -> String {
        let t = raw.lowercased()

        // "9h30", "15h", "9h3"
        if let range = t.range(of: #"^(\d{1,2})h(\d{0,2})$"#, options: .regularExpression) {
            let parts = String(t[range]).components(separatedBy: "h")
            let h = Int(parts[0]) ?? -1
            let m = parts.count > 1 && !parts[1].isEmpty ? (Int(parts[1]) ?? -1) : 0
            if (0...23).contains(h) && (0...59).contains(m) {
                return validated(String(format: "%02d:%02d", h, m))
            }
        }

        // "9:5", "9:30", "13:30"
        let cp = t.split(separator: ":", maxSplits: 1).map(String.init)
        if cp.count == 2, let h = Int(cp[0]), let m = Int(cp[1]),
           (0...23).contains(h) && (0...59).contains(m) {
            return validated(String(format: "%02d:%02d", h, m))
        }

        // "9" "13" "930" "1330"
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

// MARK: - SlotRowView

/// Tách thành struct riêng với @State isHovered cục bộ.
/// Khi hover, chỉ view này re-render — KHÔNG kéo theo các slot khác trong LazyVStack.
private struct SlotRowView: View {
    let slot: String
    let isSelected: Bool
    let durationLabel: String?
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Text(slot)
                    .font(.system(size: 11.5, weight: isSelected ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, alignment: durationLabel == nil ? .center : .leading)
                    .padding(.leading, durationLabel == nil ? 0 : 10)

                if let dur = durationLabel {
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
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Start time — no reference") {
    @Previewable @State var time = "13:30"
    TimePopover(selection: $time, onClose: {})
}

#Preview("End time — with duration labels") {
    @Previewable @State var time = "13:15"   // non-round → tests nearest-slot scroll
    let ref = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
    TimePopover(selection: $time, referenceDate: ref, onClose: {})
}

#endif
