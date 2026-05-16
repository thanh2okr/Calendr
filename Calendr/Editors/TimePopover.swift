//
//  TimePopover.swift
//  Calendr
//

import SwiftUI

struct TimePopover: View {

    @Binding var selection: String  // "HH:mm"
    var onClose: () -> Void

    @State private var inputText: String = ""
    @FocusState private var focused: Bool

    // All 48 half-hour slots as "HH:mm" strings
    private static let allSlots: [String] = (0 ..< 48).map { i in
        String(format: "%02d:%02d", i / 2, (i % 2) * 30)
    }

    // Filter by prefix while typing; show all when empty
    private var filteredSlots: [String] {
        let q = inputText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Self.allSlots }
        return Self.allSlots.filter { $0.hasPrefix(q) }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Text field ────────────────────────────────────────────
            TextField("HH:MM", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .multilineTextAlignment(.center)
                .focused($focused)
                .onSubmit { commitInput() }
                .onKeyPress(.escape) { onClose(); return .handled }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)

            Divider()

            // ── Slot list ─────────────────────────────────────────────
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredSlots, id: \.self) { slot in
                            slotRow(slot)
                                .id(slot)
                        }
                    }
                }
                .frame(maxHeight: 180)
                .onAppear {
                    inputText = selection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focused = true
                        if Self.allSlots.contains(selection) {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                }
                .onChange(of: inputText) { _, _ in
                    if let first = filteredSlots.first {
                        proxy.scrollTo(first, anchor: .top)
                    }
                }
            }
        }
        .frame(width: 130)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Slot row

    @ViewBuilder
    private func slotRow(_ slot: String) -> some View {
        let isSelected = slot == selection
        Button {
            selection = slot
            onClose()
        } label: {
            Text(slot)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular)
                    .monospacedDigit())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Commit

    private func commitInput() {
        let normalized = normalizeTime(inputText)
        if !normalized.isEmpty {
            selection = normalized
        }
        onClose()
    }

    // "9" → "09:00", "9:5" → "09:05", "930" → "09:30", "9h30" → "09:30"
    private func normalizeTime(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespaces).lowercased()

        // Vietnamese "Nh" separator: "9h30", "15h", "9h3"
        if let range = t.range(of: #"^(\d{1,2})h(\d{0,2})$"#, options: .regularExpression) {
            let parts = String(t[range]).components(separatedBy: "h")
            let h = Int(parts[0]) ?? -1
            let m = (parts.count > 1 && !parts[1].isEmpty) ? (Int(parts[1]) ?? -1) : 0
            if (0...23).contains(h) && (0...59).contains(m) {
                return String(format: "%02d:%02d", h, m)
            }
        }

        // Colon-separated: "9:5", "9:30", "13:30"
        let colonParts = t.components(separatedBy: ":")
        if colonParts.count == 2, let h = Int(colonParts[0]), let m = Int(colonParts[1]) {
            if (0...23).contains(h) && (0...59).contains(m) {
                return String(format: "%02d:%02d", h, m)
            }
        }

        // Pure digits: "9" "13" "930" "1330"
        let digits = t.filter(\.isNumber)
        switch digits.count {
        case 1, 2:
            if let h = Int(digits), (0...23).contains(h) { return String(format: "%02d:00", h) }
        case 3:
            let h = Int(digits.prefix(1))!
            let m = Int(digits.suffix(2))!
            if (0...23).contains(h) && (0...59).contains(m) { return String(format: "%02d:%02d", h, m) }
        case 4:
            let h = Int(digits.prefix(2))!
            let m = Int(digits.suffix(2))!
            if (0...23).contains(h) && (0...59).contains(m) { return String(format: "%02d:%02d", h, m) }
        default: break
        }

        return ""
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    @Previewable @State var time = "13:30"
    TimePopover(selection: $time, onClose: {})
}

#endif
