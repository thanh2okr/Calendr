//
//  StatusItemIconFactory.swift
//  Calendr
//
//  Created by Paker on 25/07/23.
//

import AppKit

enum StatusItemIconFactory {

    static func icon(size: CGFloat, style: StatusItemIconStyle, textScaling: Double, dateProvider: DateProviding) -> NSImage {
        let headerHeight: CGFloat = 3 * textScaling
        let borderWidth: CGFloat = 2
        let radius: CGFloat = 2.5
        let rect = CGRect(x: 0, y: 0, width: size + borderWidth, height: size)
        let insetX = (2.5 * textScaling).rounded(to: 0.5)

        // weekNumber: square box matching the width of other icons (size+borderWidth)
        // e.g. size=12 → 14×14, same width as calendar/date icons which are 14×12
        let weekNumSide = size + borderWidth
        let weekNumRect = CGRect(x: 0, y: 0, width: weekNumSide, height: weekNumSide)

        let size = switch style {
        case .calendar, .date:
            rect.size
        case .dayOfWeek:
            rect.insetBy(dx: -insetX, dy: -0.5).size
        case .weekNumber:
            weekNumRect.size
        }

        let image = NSImage(size: size, flipped: true) { _ in
            /// can be any opaque color, but red is good for debugging
            let color = NSColor.red
            color.setStroke()
            color.setFill()

            if style != .dayOfWeek {
                let frameRect = style == .weekNumber ? weekNumRect : rect
                drawFrame(rect: frameRect, radius: radius, borderWidth: borderWidth, headerHeight: headerHeight)
            }

            switch style {

            case .calendar:
                drawCalendarDots(rect: rect, borderWidth: borderWidth, headerHeight: headerHeight)

            case .date:
                drawDate(rect: rect, headerHeight: headerHeight, textScaling: textScaling, dateProvider: dateProvider)

            case .dayOfWeek:
                drawDayOfWeekAndDate(rect: rect, insetX: insetX, textScaling: textScaling, dateProvider: dateProvider)

            case .weekNumber:
                drawWeekNumber(rect: weekNumRect, dateProvider: dateProvider)
            }

            return true
        }
        
        image.isTemplate = true

        return image
    }

    static func drawFrame(rect: CGRect, radius: CGFloat, borderWidth: CGFloat, headerHeight: CGFloat) {
        let strokePath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        strokePath.addClip()
        strokePath.lineWidth = borderWidth
        strokePath.stroke()

        var fillRect = rect
        fillRect.size.height = headerHeight
        let fillPath = NSBezierPath(rect: fillRect)
        fillPath.fill()
    }

    static func drawCalendarDots(rect: CGRect, borderWidth: CGFloat, headerHeight: CGFloat) {
        let offsetX: CGFloat = rect.origin.x + borderWidth
        let offsetY: CGFloat = rect.origin.y + headerHeight + 0.5
        let insets: CGFloat = 0.09 * rect.width
        let dotSize: CGFloat = 1.4
        let rows: Int = 3
        let cols: Int = 4
        let availableWidth: CGFloat = rect.size.width - 2 * borderWidth - 2 * insets - CGFloat(cols) * dotSize
        let availableHeight: CGFloat = rect.size.height - headerHeight - borderWidth - 2 * insets - CGFloat(rows) * dotSize
        let spacingX: CGFloat = availableWidth / CGFloat(cols - 1)
        let spacingY: CGFloat = availableHeight / CGFloat(rows - 1)
        for i in 1...10 {
            let row: Int = i % rows
            let col: Int = i / rows
            let dotPath = NSBezierPath(
                ovalIn: .init(
                    x: offsetX + insets + CGFloat(col) * (dotSize + spacingX),
                    y: offsetY + insets + CGFloat(row) * (dotSize + spacingY),
                    width: dotSize,
                    height: dotSize
                )
            )
            dotPath.fill()
        }
    }

    static func drawDate(rect: CGRect, headerHeight: CGFloat, textScaling: Double, dateProvider: DateProviding) {
        let formatter = DateFormatter(format: "d", calendar: dateProvider.calendar)
        let date = formatter.string(from: dateProvider.now)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let fontSize = (0.6 * rect.height).rounded(to: 0.5)
        let middleY = rect.height / 2 - fontSize / 2
        NSAttributedString(string: date, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor.red,
            .paragraphStyle: paragraph
        ]).draw(in: rect.offsetBy(dx: 0, dy: middleY))
    }

    static func drawWeekNumber(rect: CGRect, dateProvider: DateProviding) {
        let weekNumber = dateProvider.calendar.component(.weekOfYear, from: dateProvider.now)
        let text = "\(weekNumber)"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        // Header height is 3pt (same as other styles), so center number in body area below header
        let headerHeight: CGFloat = 3
        let bodyHeight = rect.height - headerHeight
        let fontSize = (0.6 * rect.height).rounded(to: 0.5)
        let midY = headerHeight + (bodyHeight - fontSize) / 2
        NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor.red,
            .paragraphStyle: paragraph
        ]).draw(in: rect.offsetBy(dx: 0, dy: midY))
    }

    static func drawDayOfWeekAndDate(rect: CGRect, insetX: CGFloat, textScaling: Double, dateProvider: DateProviding) {
        func run(fn: () -> Void) { fn() }

        let formatter = DateFormatter(calendar: dateProvider.calendar)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let fontSize = (0.6 * rect.height).rounded(to: 0.5)
        let middleY = rect.height / 2

        run {
            formatter.dateFormat = "E"
            let date = formatter.string(from: dateProvider.now).uppercased().trimmingCharacters(in: ["."])
            NSAttributedString(string: date, attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor.red,
                .paragraphStyle: paragraph
            ])
            .draw(in: rect.offsetBy(dx: insetX, dy: 0).insetBy(dx: -insetX, dy: -1))
        }

        run {
            formatter.dateFormat = "d"
            let date = formatter.string(from: dateProvider.now)
            NSAttributedString(string: date, attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: NSColor.red,
                .paragraphStyle: paragraph
            ])
            .draw(in: rect.offsetBy(dx: insetX, dy: middleY + 1).insetBy(dx: 0, dy: -2))
        }
    }
}
