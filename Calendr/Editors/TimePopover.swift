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

    @State private var hourDraft: String = ""
    @State private var minuteDraft: String = ""
    @State private var durationLabels: [String: String] = [:]
    @FocusState private var segment: InputSegment?

    private let cal = Calendar.current

    private enum InputSegment: Hashable { case hour, minute }

    // MARK: - Static data

    static let allSlots: [String] = (0 ..< 48).map {
        String(format: "%02d:%02d", $0 / 2, ($0 % 2) * 30)
    }

    // MARK: - Filtering

    private var filteredSlots: [String] {
        guard !hourDraft.isEmpty else { return Self.allSlots }
        let hPad = hourDraft.count == 1 ? "0\(hourDraft)" : hourDraft
        guard !minuteDraft.isEmpty else {
            return Self.allSlots.filter { $0.hasPrefix(hPad) }
        }
        return Self.allSlots.filter { $0.hasPrefix("\(hPad):\(minuteDraft)") }
    }

    /// Slot gần nhất với `selection` để scroll khi mở
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
        VStack(spacing: 10) {

            // ── Segmented HH : MM input ───────────────────────────────
            HStack(spacing: 0) {
                segmentField(text: $hourDraft, placeholder: "HH", seg: .hour)

                Text(":")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.35))
                    .frame(width: 12)

                segmentField(text: $minuteDraft, placeholder: "MM", seg: .minute)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
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
                .frame(maxHeight: 180)
                .onAppear {
                    buildDurationLabels()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        segment = .hour
                        if let target = nearestSlot {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
                .onChange(of: hourDraft)   { _, _ in scrollToFirst(proxy: proxy) }
                .onChange(of: minuteDraft) { _, _ in scrollToFirst(proxy: proxy) }
            }
        }
        .padding(14)
        .frame(width: 128)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Segment field builder

    @ViewBuilder
    private func segmentField(text: Binding<String>, placeholder: String, seg: InputSegment) -> some View {
        TextField("", text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .focused($segment, equals: seg)
            .frame(width: 28)
            .onSubmit { commitInput() }
            .onKeyPress(.escape) { onClose(); return .handled }
            .onKeyPress(.delete) {
                // Backspace ở phút rỗng → quay về giờ
                guard text.wrappedValue.isEmpty, seg == .minute else { return .ignored }
                segment = .hour
                return .handled
            }
            .onChange(of: text.wrappedValue) { _, new in
                handleChange(new, seg: seg, binding: text)
            }
            .overlay {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(segment == seg ? Color.accentColor.opacity(0.13) : Color.clear)
                    .animation(.easeInOut(duration: 0.1), value: segment)
            )
    }

    // MARK: - Input handling

    private func handleChange(_ new: String, seg: InputSegment, binding: Binding<String>) {
        // Chỉ giữ chữ số, tối đa 2 ký tự
        let digits = String(new.filter(\.isNumber).prefix(2))
        if digits != new { binding.wrappedValue = digits }

        switch seg {
        case .hour:
            guard !digits.isEmpty else { return }
            if digits.count == 2 {
                // "25" → không hợp lệ → revert về ký tự đầu, không nhảy
                if let h = Int(digits), h > 23 {
                    binding.wrappedValue = String(digits.prefix(1))
                    return
                }
                segment = .minute   // 2 chữ số hợp lệ → nhảy phút
            } else if (Int(digits) ?? 0) > 2 {
                // Chữ số đơn > 2 (3–9) → không thể là prefix của giờ hợp lệ (30–99) → nhảy luôn
                segment = .minute
            }

        case .minute:
            guard !digits.isEmpty else { return }
            if digits.count == 2 {
                // "67" → không hợp lệ → revert, không commit
                if let m = Int(digits), m > 59 {
                    binding.wrappedValue = String(digits.prefix(1))
                    return
                }
                commitInput()   // 2 chữ số hợp lệ → tự commit
            }
        }
    }

    // MARK: - Commit

    private func commitInput() {
        // Không gõ gì → chỉ đóng
        guard !hourDraft.isEmpty || !minuteDraft.isEmpty else { onClose(); return }

        let h = Int(hourDraft), m = Int(minuteDraft)

        // 1. Cả hai hợp lệ → commit trực tiếp
        if let h, let m, (0...23).contains(h), (0...59).contains(m) {
            selection = String(format: "%02d:%02d", h, m)
            onClose()
            return
        }

        // 2. Fallback: slot đầu tiên trong danh sách đã filter
        if let first = filteredSlots.first {
            selection = first
            onClose()
            return
        }

        onClose()
    }

    // MARK: - Scroll helper

    private func scrollToFirst(proxy: ScrollViewProxy) {
        let slots = filteredSlots
        guard let first = slots.first else { return }
        proxy.scrollTo(first, anchor: slots.count == 1 ? .center : .top)
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
}

// MARK: - SlotRowView

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
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, alignment: durationLabel == nil ? .center : .leading)
                    .padding(.leading, durationLabel == nil ? 0 : 10)

                if let dur = durationLabel {
                    Text(dur)
                        .font(.system(size: 11))
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
    @Previewable @State var time = "13:15"
    let ref = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
    TimePopover(selection: $time, referenceDate: ref, onClose: {})
}

#endif
