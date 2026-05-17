//
//  TimePopover.swift
//  Calendr
//

import SwiftUI

struct TimePopover: View {

    @Binding var selection: String  // "HH:mm"
    var onClose: () -> Void

    // draft starts EMPTY so list shows all 48 slots on open (not filtered)
    @State private var draft: String = ""
    @State private var hoveredSlot: String? = nil
    @FocusState private var focused: Bool

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
                    if let first = filteredSlots.first {
                        proxy.scrollTo(first, anchor: .top)
                    }
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

        Button {
            selection = slot
            onClose()
        } label: {
            Text(slot)
                .font(.system(size: 11.5, weight: isSelected ? .bold : .regular, design: .monospaced))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, alignment: .center)
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
