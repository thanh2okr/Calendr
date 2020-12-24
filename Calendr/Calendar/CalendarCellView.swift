//
//  CalendarCellView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarCellView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: Observable<CalendarCellViewModel>
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>
    private let doubleClickObserver: AnyObserver<Date>
    private let calendarScaling: Observable<Double>
    private let calendarTextScaling: Observable<Double>
    private let combinedScaling: Observable<Double>
    private let highlightColor: Observable<NSColor?>

    private let label: Label
    private let eventsStackView = NSStackView()
    private let glassHighlight = NSGlassEffectView()
    private let borderLayer = CALayer()

    init(
        viewModel: Observable<CalendarCellViewModel>,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>,
        doubleClickObserver: AnyObserver<Date>,
        calendarScaling: Observable<Double>,
        calendarTextScaling: Observable<Double>,
        highlightColor: Observable<NSColor?> = .just(nil)
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver
        self.doubleClickObserver = doubleClickObserver
        self.calendarScaling = calendarScaling
        self.calendarTextScaling = calendarTextScaling
        self.highlightColor = highlightColor

        self.combinedScaling = Observable
            .combineLatest(calendarScaling, calendarTextScaling)
            .map(*)
            .share(replay: 1)

        label = Label(font: .systemFont(ofSize: Constants.fontSize), scaling: combinedScaling)

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)

        Observable.combineLatest(
            viewModel.map(\.isToday).distinctUntilChanged(),
            viewModel.map(\.isSelected).distinctUntilChanged(),
            viewModel.map(\.isHovered).distinctUntilChanged()
        )
        .map { isToday, isSelected, isHovered in
            [
                Accessibility.Calendar.date,
                isToday ? Accessibility.Calendar.today : nil,
                isSelected ? Accessibility.Calendar.selected : nil,
                isHovered ? Accessibility.Calendar.hovered : nil
            ]
            .compact()
        }
        .bind(to: rx.accessibilityIdentifiers)
        .disposed(by: disposeBag)
    }

    private func configureLayout() {

        forAutoLayout()

        // Liquid Glass highlight behind the date label (today / selected)
        glassHighlight.cornerRadius = Constants.glassRadius
        glassHighlight.style = .regular
        glassHighlight.isHidden = true
        addSubview(glassHighlight)
        glassHighlight.width(equalTo: Constants.glassSize)
        glassHighlight.height(equalTo: Constants.glassSize)

        // Legacy border layer kept for hover/selected state on older-style theming
        wantsLayer = true
        borderLayer.cornerRadius = Constants.cornerRadius
        layer!.addSublayer(borderLayer)

        label.alignment = .center
        label.textColor = .headerTextColor

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)

        eventsStackView.spacing = 2
        eventsStackView.top(equalTo: eventsContainer)
        eventsStackView.bottom(equalTo: eventsContainer)
        eventsStackView.center(in: eventsContainer, orientation: .horizontal)
        eventsStackView.width(lessThanOrEqualTo: eventsContainer)

        let contentStackView = NSStackView(views: [label, eventsContainer])
            .with(orientation: .vertical)
            .with(spacing: 2)

        addSubview(contentStackView)

        contentStackView.center(in: self)

        // Center glass highlight on the date number (horizontally in cell, vertically on label)
        glassHighlight.center(in: self, orientation: .horizontal)
        glassHighlight.center(in: label, orientation: .vertical)
    }

    private func setUpBindings() {

        calendarScaling
            .bind { [weak self, borderLayer] in
                borderLayer.borderWidth = Constants.borderWidth * $0
                self?.updateLayer()
            }
            .disposed(by: disposeBag)

        viewModel
            .map(\.text)
            .distinctUntilChanged()
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .map(\.alpha)
            .distinctUntilChanged()
            .bind(to: label.rx.alpha)
            .disposed(by: disposeBag)

        // Glass circle handles today / selected / hover — no borderLayer used
        Observable.combineLatest(
            viewModel.map(\.isToday).distinctUntilChanged(),
            viewModel.map(\.isSelected).distinctUntilChanged(),
            viewModel.map(\.isHovered).distinctUntilChanged(),
            highlightColor
        )
        .repeat(when: rx.updateLayer)
        .bind { [glassHighlight, label] isToday, isSelected, isHovered, highlightColor in
            glassHighlight.isHidden = !isToday && !isSelected && !isHovered
            if isToday {
                glassHighlight.style = .regular
                glassHighlight.tintColor = .controlAccentColor
                label.textColor = .white
            } else if isSelected {
                glassHighlight.style = .regular
                glassHighlight.tintColor = NSColor.labelColor.withAlphaComponent(0.6)
                label.textColor = .labelColor
            } else if isHovered {
                glassHighlight.style = .clear
                glassHighlight.tintColor = nil
                label.textColor = highlightColor ?? .headerTextColor
            } else {
                glassHighlight.tintColor = nil
                label.textColor = highlightColor ?? .headerTextColor
            }
        }
        .disposed(by: disposeBag)

        // borderLayer is no longer used for any state — suppress entirely
        borderLayer.rx.borderColor.onNext(CGColor(gray: 0, alpha: 0))

        Observable.combineLatest(
            viewModel.map(\.dots).distinctUntilChanged(),
            combinedScaling
        )
        .repeat(when: rx.updateLayer)
        .map { dots, scaling in
            if dots.count <= CalendarCellViewModel.maximumDotsCount {
                dots.map {
                    makeEventDot(color: $0, scaling: scaling)
                }
            } else {
                [
                    makeEventsGradient(colors: dots, scaling: scaling)
                ]
            }
        }
        .bind(to: eventsStackView.rx.arrangedSubviews)
        .disposed(by: disposeBag)

        /// When we single-click a date, it updates the event list, which causes the window to resize.
        /// That causes the 2nd click to be cancelled by macOS, even though we're clicking at the exact same place.
        /// Because of that, we have to calculate the time difference between single clicks and trigger the double click ourselves:
        ///
        /// Expected behavior:
        ///  - If the user clicked a date in the current month, immediately fire the single click and the double click later, if detected.
        ///  - If the user clicked a date in another month, wait for the double click. If detected, cancel the single click.
        ///
        /// That avoids changing months during the double click, which ends up opening the system calendar in the wrong date.

        var lastClickTimestamp: TimeInterval = 0
        var workItem: DispatchWorkItem?

        rx.click
            .withLatestFrom(viewModel)
            .bind { [clickObserver, doubleClickObserver] vm in
                let currentTimestamp = CACurrentMediaTime()
                let doubleClicked = currentTimestamp - lastClickTimestamp < NSEvent.doubleClickInterval

                if vm.inMonth {
                    clickObserver.onNext(vm.date)
                } else if !doubleClicked {
                    workItem = DispatchWorkItem {
                        clickObserver.onNext(vm.date)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: workItem!)
                }

                if doubleClicked {
                    workItem?.cancel()
                    doubleClickObserver.onNext(vm.date)
                }

                lastClickTimestamp = currentTimestamp
            }
            .disposed(by: disposeBag)

        rx.mouseEntered
            .withLatestFrom(viewModel.map(\.date))
            .bind(to: hoverObserver)
            .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        borderLayer.frame = bounds
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // Prevent propagating event to superview
    override func mouseExited(with event: NSEvent) { }

    override func updateTrackingAreas() {

        if let trackingArea = trackingAreas.first {
            guard trackingArea.rect != bounds else { return }
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self
        )

        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeEventsGradient(colors: [NSColor], scaling: Double) -> NSView {
    let view = NSView()
    let size = Constants.eventDotSize * scaling
    view.height(equalTo: size)
    view.width(equalTo: 4 * size, priority: .defaultHigh)

    let gradient = CAGradientLayer()
    gradient.colors = colors.map(\.cgColor)
    gradient.startPoint = CGPoint(x: 0, y: 0.5)
    gradient.endPoint = CGPoint(x: 1, y: 0.5)
    gradient.cornerRadius = size / 2

    view.layer = gradient

    return view
}

private func makeEventDot(color: NSColor, scaling: Double) -> NSView {

    let view = NSView()
    let size = Constants.eventDotSize * scaling

    view.size(equalTo: size)

    view.wantsLayer = true
    view.layer!.backgroundColor = color.effectiveCGColor
    view.layer!.cornerRadius = size / 2

    if BuildConfig.isUITesting {
        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Calendar.event)
    }

    return view
}

private enum Constants {

    static let fontSize: CGFloat = 13
    static let eventDotSize: CGFloat = 3

    static let borderWidth: CGFloat = 1.5
    static let cornerRadius: CGFloat = 7

    // Liquid Glass today/selected pill — slightly larger for visual clarity
    static let glassSize: CGFloat = 30
    // Perfect circle
    static var glassRadius: CGFloat { glassSize / 2 }
}
