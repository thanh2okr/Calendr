//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift
import RxCocoa
import CoreImage.CIFilterBuiltins

class EventView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventViewModel

    private let birthdayIcon = NSImageView()
    private let recurrenceIcon = NSImageView()
    private let priority = Label()
    private let title = Label()
    private let subtitle = Label()
    private let subtitleLink = Label(align: .left)
    private let duration = Label()
    private let relativeDuration = Label()
    private let progress = NSView()
    private let linkBtn = ImageButton()
    private let completeBtn = ImageButton()
    private let priorityLabel = Label()
    // hoverLayer kept for updateLayer() reference only
    private let hoverLayer = CALayer()
    // Card background layers (bottom to top): blur → tint → hover → stripe → content
    private let blurView = NSVisualEffectView()
    private let tintView = NSView()
    private let hoverOverlay = NSView()
    private let colorStripe = NSView()
    private let cornerRadius: CGFloat = 10
    private let progressBallSize: CGFloat = 8

    // slideView: the card face — clips content, slides left on swipe
    private let slideView = NSView()
    // checkContainer: sits behind slideView, shown only during slide
    private let checkContainer = NSView()
    private let slideRevealWidth: CGFloat = 56
    private var isRevealed = false
    private var dragStart: CGPoint = .zero

    private var fixedHeightConstraint: NSLayoutConstraint?

    private lazy var progressTop = progress.top(equalTo: self)

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setData()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.EventList.event)
    }

    private func setUpContextMenu(_ viewModel: some ContextMenuViewModel) {
        menu = ContextMenu(viewModel: viewModel)
    }

    private func setData() {

        if let contextMenuViewModel = viewModel.makeContextMenuViewModel() {
            setUpContextMenu(contextMenuViewModel)
        }

        switch viewModel.type {

            case .birthday:
                birthdayIcon.isHidden = false

            case .reminder:
                priority.textColor = viewModel.color
                priority.stringValue = viewModel.priority ?? ""
                priority.isHidden = viewModel.priority == nil

                completeBtn.contentTintColor = viewModel.color

            case .event:
                break
        }

        // Solid color stripe — .filled is opaque, .bordered (maybe status) is semi-transparent
        let stripeAlpha: CGFloat = viewModel.barStyle == .bordered ? 0.5 : 1.0
        colorStripe.layer?.backgroundColor = viewModel.color.withAlphaComponent(stripeAlpha).cgColor

        title.attributedStringValue = .init(
            string: viewModel.title,
            attributes: viewModel.isDeclined ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue] : [:]
        )

        subtitle.stringValue = viewModel.subtitle

        if let link = viewModel.subtitleLink {
            subtitleLink.stringValue = link
        } else {
            subtitleLink.isHidden = true
        }

        linkBtn.isHidden = viewModel.link == nil
        linkBtn.toolTip = viewModel.link?.url.absoluteString
    }

    private func configureLayout() {

        forAutoLayout()

        // self: clips the slide animation
        wantsLayer = true
        clipsToBounds = true
        layer?.cornerRadius = cornerRadius

        // hoverLayer no longer used (replaced by hoverOverlay inside slideView)

        // checkContainer behind slideView — hidden until slide is triggered
        if viewModel.type.isReminder {
            checkContainer.isHidden = true
            addSubview(checkContainer)
            checkContainer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                checkContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                checkContainer.topAnchor.constraint(equalTo: topAnchor),
                checkContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
                checkContainer.widthAnchor.constraint(equalToConstant: slideRevealWidth),
            ])

            completeBtn.setContentHuggingPriority(.required, for: .horizontal)
            completeBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
            checkContainer.addSubview(completeBtn)
            completeBtn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                completeBtn.centerXAnchor.constraint(equalTo: checkContainer.centerXAnchor),
                completeBtn.centerYAnchor.constraint(equalTo: checkContainer.centerYAnchor),
            ])
        }

        // slideView on top — covers checkContainer, clips content to rounded corners
        slideView.wantsLayer = true
        slideView.clipsToBounds = true
        slideView.layer?.cornerRadius = cornerRadius
        addSubview(slideView)
        slideView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slideView.leadingAnchor.constraint(equalTo: leadingAnchor),
            slideView.topAnchor.constraint(equalTo: topAnchor),
            slideView.bottomAnchor.constraint(equalTo: bottomAnchor),
            slideView.widthAnchor.constraint(equalTo: widthAnchor),
        ])

        // Blur background (bottom-most layer of card)
        blurView.material = .sidebar
        blurView.blendingMode = .withinWindow
        blurView.state = .active
        slideView.addSubview(blurView)
        blurView.edges(equalTo: slideView)

        // Tint overlay — transparent by default, colored for in-progress/pending
        tintView.wantsLayer = true
        slideView.addSubview(tintView)
        tintView.edges(equalTo: slideView)

        // Hover overlay — white glow on mouse-enter, sits above tint
        hoverOverlay.wantsLayer = true
        hoverOverlay.isHidden = true
        slideView.addSubview(hoverOverlay)
        hoverOverlay.edges(equalTo: slideView)

        // Color stripe — flush with left edge, 3pt solid, clips to slideView's corner radius
        colorStripe.wantsLayer = true
        slideView.addSubview(colorStripe)
        colorStripe.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorStripe.leadingAnchor.constraint(equalTo: slideView.leadingAnchor),
            colorStripe.topAnchor.constraint(equalTo: slideView.topAnchor),
            colorStripe.bottomAnchor.constraint(equalTo: slideView.bottomAnchor),
            colorStripe.widthAnchor.constraint(equalToConstant: 3),
        ])

        // --- labels & icons ---

        [birthdayIcon, recurrenceIcon, linkBtn, priority, relativeDuration].forEach {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        priority.isHidden = true
        priority.font = .systemFont(ofSize: 13)

        birthdayIcon.isHidden = true
        birthdayIcon.contentTintColor = .systemRed

        recurrenceIcon.isHidden = true

        title.forceVibrancy = false
        title.lineBreakMode = .byWordWrapping
        title.textColor = .headerTextColor
        title.font = .systemFont(ofSize: 13, weight: .regular)

        duration.lineBreakMode = .byWordWrapping
        duration.textColor = .secondaryLabelColor
        duration.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)

        relativeDuration.isHidden = true
        relativeDuration.textColor = .tertiaryLabelColor
        relativeDuration.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)

        subtitle.lineBreakMode = .byWordWrapping
        subtitle.maximumNumberOfLines = 2
        subtitle.cell?.truncatesLastVisibleLine = true
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 11)

        subtitleLink.lineBreakMode = .byTruncatingTail
        subtitleLink.textColor = .secondaryLabelColor
        subtitleLink.font = .systemFont(ofSize: 11)

        // Title row:
        // - Reminders: [birthdayIcon, priority, title]
        // - Calendar/Birthday events: [birthdayIcon, priority, title, recurrenceIcon] (icon inline at end)
        let titleRowViews: [NSView] = viewModel.type.isReminder
            ? [birthdayIcon, priority, title]
            : [birthdayIcon, priority, title, recurrenceIcon]
        let titleStackView = NSStackView(views: titleRowViews)
            .with(spacing: 4)
            .with(alignment: .firstBaseline)
        titleStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        viewModel.showDetails
            .map { [viewModel] in
                !$0 || viewModel.subtitle.isEmpty
            }
            .bind(to: subtitle.rx.isHidden)
            .disposed(by: disposeBag)

        // Link row:
        // - Reminders: [subtitleLink] (no linkBtn icon)
        // - Calendar events with link: [subtitleLink, linkBtn] (icon inline at end)
        let linkRowViews: [NSView] = (viewModel.type.isReminder || viewModel.link == nil)
            ? [subtitleLink]
            : [subtitleLink, linkBtn]
        let linkStackView = NSStackView(views: linkRowViews).with(spacing: 4)

        Observable.combineLatest(viewModel.showDetails, linkStackView.rx.isContentHidden)
            .map { !$0 || $1 }
            .bind(to: linkStackView.rx.isHidden)
            .disposed(by: disposeBag)

        let durationStackView = NSStackView(views: [duration, relativeDuration])
        duration.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        durationStackView.setHuggingPriority(.defaultHigh, for: .horizontal)

        durationStackView.rx.isContentHidden
            .bind(to: durationStackView.rx.isHidden)
            .disposed(by: disposeBag)

        priorityLabel.font = .systemFont(ofSize: 10, weight: .medium)
        priorityLabel.isHidden = viewModel.priorityText == nil
        if let text = viewModel.priorityText { priorityLabel.stringValue = text }
        if let color = viewModel.priorityColor { priorityLabel.textColor = color }

        let eventStackView = NSStackView(views: [titleStackView, subtitle, linkStackView, durationStackView, priorityLabel])
            .with(orientation: .vertical)
            .with(spacing: 2)
            .with(alignment: .leading)
            .with(insets: .init(top: 7, left: 0, bottom: 7, right: 0))

        // Layout: [stripe 14pt gap] [content, expands] [right margin 8pt]
        // Icons are now inline with their respective content rows (no separate right icon column)
        let mainContentStack = NSStackView(
            views: [.spacer(width: 14), eventStackView, .spacer(width: 8)]
        ).with(spacing: 0).with(alignment: .top)

        slideView.addSubview(mainContentStack)
        mainContentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainContentStack.leadingAnchor.constraint(equalTo: slideView.leadingAnchor),
            mainContentStack.trailingAnchor.constraint(equalTo: slideView.trailingAnchor),
            mainContentStack.topAnchor.constraint(equalTo: slideView.topAnchor),
            mainContentStack.bottomAnchor.constraint(equalTo: slideView.bottomAnchor),
        ])

        configureProgress()
    }

    private func configureProgress() {

        addSubview(progress)

        let ringSize: CGFloat = 0.5

        let ball = NSView()
        ball.wantsLayer = true
        ball.size(equalTo: progressBallSize - ringSize)

        let ring = NSView()
        ring.wantsLayer = true
        ring.layer?.cornerRadius = progressBallSize / 2
        ring.layer?.borderWidth = ringSize
        ring.layer?.allowsEdgeAntialiasing = true
        ring.addSubview(ball)
        ring.size(equalTo: progressBallSize)

        ball.center(in: ring)

        let line = NSView()
        line.wantsLayer = true
        line.layer?.borderWidth = ringSize
        line.height(equalTo: 1.5 + 2 * ringSize)

        let glue = NSView()
        glue.wantsLayer = true
        glue.height(equalTo: 1.5)

        rx.updateLayer
            .startWith(())
            .bind {
                ring.layer?.borderColor = NSColor.windowBackgroundColor.effectiveCGColor
                line.layer?.borderColor = NSColor.windowBackgroundColor.effectiveCGColor
                ball.layer?.backgroundColor = NSColor.systemRed.effectiveCGColor
                line.layer?.backgroundColor = NSColor.systemRed.effectiveCGColor
                glue.layer?.backgroundColor = NSColor.systemRed.effectiveCGColor
            }
            .disposed(by: disposeBag)

        progress.isHidden = true
        progress.leading(equalTo: self, constant: -progressBallSize / 2 + 2)
        progress.trailing(equalTo: self)
        progress.addSubview(line)
        progress.addSubview(ring)
        progress.addSubview(glue)

        line.center(in: progress, orientation: .vertical)
        line.leading(equalTo: progress)
        line.trailing(equalTo: progress)

        ball.leading(equalTo: progress)
        ball.top(equalTo: progress)
        ball.bottom(equalTo: progress)

        glue.center(in: line, orientation: .vertical)
        glue.leading(equalTo: ball.centerXAnchor)
        glue.width(equalTo: progressBallSize)
    }

    private func setUpBindings() {

        rx.isHovered
            .startWith(false)
            .distinctUntilChanged()
            .map(!)
            .bind(to: hoverOverlay.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.duration
            .bind(to: duration.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.duration.map(\.isEmpty)
            .bind(to: duration.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.titleLines
            .bind { [weak self] lines in
                guard let self else { return }
                title.maximumNumberOfLines = lines
                updateFixedHeight(lines: lines)
            }
            .disposed(by: disposeBag)

        if let link = viewModel.link {
            Observable.combineLatest(
                link.isMeeting
                    ? viewModel.isInProgress.map { $0 ? Icons.Event.video_fill : Icons.Event.video }
                    : .just(Icons.Event.link),
                Scaling.observable
            )
            .map { $0.with(pointSize: 10 * $1) }
            .bind(to: linkBtn.rx.image)
            .disposed(by: disposeBag)

            viewModel.isInProgress.map { $0 ? .controlAccentColor : .secondaryLabelColor }
                .bind(to: linkBtn.rx.contentTintColor)
                .disposed(by: disposeBag)

            linkBtn.rx.tap
                .bind(to: viewModel.linkTapped)
                .disposed(by: disposeBag)
        }

        if viewModel.type.isBirthday {

            Scaling.observable
                .map { Icons.Event.birthday.with(pointSize: 10 * $0) }
                .bind(to: birthdayIcon.rx.image)
                .disposed(by: disposeBag)

        } else {

            viewModel.isFaded
                .map { $0 ? 0.5 : 1 }
                .bind(to: rx.alpha)
                .disposed(by: disposeBag)

            Observable.combineLatest(viewModel.showRecurrenceIndicator, Scaling.observable)
                .filter(\.0)
                .map { Icons.Event.recurrence.with(pointSize: 10 * $1) }
                .bind(to: recurrenceIcon.rx.image)
                .disposed(by: disposeBag)

            viewModel.showRecurrenceIndicator
                .map(!)
                .bind(to: recurrenceIcon.rx.isHidden)
                .disposed(by: disposeBag)
        }

        if viewModel.type.isEvent {

            Observable.combineLatest(
                viewModel.progress, rx.observe(\.frame)
            )
            .compactMap { [progressBallSize] progress, frame in
                progress.map { max(1, $0 * frame.height - progressBallSize / 2) }
            }
            .bind(to: progressTop.rx.constant)
            .disposed(by: disposeBag)

            viewModel.isInProgress
                .map(!)
                .bind(to: progress.rx.isHidden)
                .disposed(by: disposeBag)
        }

        // relativeDuration shown for all event types (overdue reminders + upcoming events)
        viewModel.relativeDuration
            .bind(to: relativeDuration.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.relativeDuration.map(\.isEmpty)
            .bind(to: relativeDuration.rx.isHidden)
            .disposed(by: disposeBag)

        if viewModel.type.isReminder {
            Observable
                .combineLatest(viewModel.isCompleted, Scaling.observable)
                .map { completed, scaling in
                    let icon = completed ? Icons.Reminder.complete : Icons.Reminder.incomplete
                    return icon.with(pointSize: 14 * scaling)
                }
                .bind(to: completeBtn.rx.image)
                .disposed(by: disposeBag)

            completeBtn.rx.tap
                .bind(to: viewModel.completeTapped)
                .disposed(by: disposeBag)
        }

        viewModel.backgroundColor
            .map(\.cgColor)
            .bind(to: tintView.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        rx.click {
            $0.delaysPrimaryMouseButtonEvents = false
        }
        .withUnretained(self)
        .flatMapFirst { [viewModel] view, _ -> Observable<Void> in
            guard !view.isRevealed else {
                view.collapseSlide()
                return .empty()
            }
            let vm = viewModel.makeDetailsViewModel()
            let vc = EventDetailsViewController(viewModel: vm)
            let popover = Popover()
            popover.behavior = .transient
            popover.contentViewController = vc
            popover.delegate = vc
            popover.push(from: view, spacing: 4, delay: vm.optimisticLoadTime)

            return popover.rx.deallocated
                .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        }
        .subscribe()
        .disposed(by: disposeBag)

        rx.observe(\.frame)
            .bind { [weak self] _ in self?.updateLayer() }
            .disposed(by: disposeBag)
    }

    // MARK: - Fixed height

    private func updateFixedHeight(lines: Int) {
        fixedHeightConstraint?.isActive = false
        fixedHeightConstraint = nil
        guard lines > 0 else { return }

        let titleFont = NSFont.systemFont(ofSize: 13, weight: .regular)
        let durationFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let titleLineH = ceil(titleFont.boundingRectForFont.height)
        let durationLineH = ceil(durationFont.boundingRectForFont.height)
        let height = 7 + CGFloat(lines) * titleLineH + 2 + durationLineH + 7
        let c = heightAnchor.constraint(equalToConstant: height)
        c.priority = .defaultHigh
        c.isActive = true
        fixedHeightConstraint = c
    }

    // MARK: - Slide gesture (reminders only)

    // Only one EventView can be revealed at a time
    private static weak var currentRevealedView: EventView?

    override func mouseDown(with event: NSEvent) {
        guard viewModel.type.isReminder else {
            super.mouseDown(with: event)
            return
        }
        dragStart = convert(event.locationInWindow, from: nil)
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard viewModel.type.isReminder else {
            super.mouseDragged(with: event)
            return
        }
        let current = convert(event.locationInWindow, from: nil)
        let dx = current.x - dragStart.x
        let dy = current.y - dragStart.y
        // Only process if horizontal movement is clearly dominant (not a scroll gesture)
        guard abs(dx) > abs(dy), abs(dx) > 8 else { return }

        let baseOffset: CGFloat = isRevealed ? -slideRevealWidth : 0
        let newOffset = max(-slideRevealWidth, min(0, baseOffset + dx))

        if newOffset < 0 { checkContainer.isHidden = false }
        applySlide(newOffset, animated: false)
    }

    override func mouseUp(with event: NSEvent) {
        guard viewModel.type.isReminder else {
            super.mouseUp(with: event)
            return
        }
        let current = convert(event.locationInWindow, from: nil)
        let dx = current.x - dragStart.x
        let dy = current.y - dragStart.y
        let threshold = slideRevealWidth * 0.4

        // If movement was mostly vertical (scroll), treat as normal click — don't change slide state
        guard abs(dx) > abs(dy), abs(dx) > 8 else {
            super.mouseUp(with: event)
            return
        }

        if dx < -threshold {
            expandSlide()
        } else if dx > threshold {
            collapseSlide()
        } else {
            applySlide(isRevealed ? -slideRevealWidth : 0, animated: true)
        }
    }

    private func expandSlide() {
        // Collapse any previously revealed card first (only 1 at a time)
        if let prev = EventView.currentRevealedView, prev !== self {
            prev.collapseSlide()
        }
        EventView.currentRevealedView = self
        checkContainer.isHidden = false
        isRevealed = true
        applySlide(-slideRevealWidth, animated: true)
    }

    func collapseSlide() {
        if EventView.currentRevealedView === self {
            EventView.currentRevealedView = nil
        }
        isRevealed = false
        applySlide(0, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.isRevealed else { return }
            self.checkContainer.isHidden = true
        }
    }

    private func applySlide(_ offset: CGFloat, animated: Bool) {
        let transform = CATransform3DMakeTranslation(offset, 0, 0)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                slideView.layer?.transform = transform
            }
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            slideView.layer?.transform = transform
            CATransaction.commit()
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func updateLayer() {
        super.updateLayer()
        // Adaptive hover glow — white overlay for visible brightening on hover
        hoverOverlay.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).effectiveCGColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea(_:))
        // Use modern NSTrackingArea — .inVisibleRect prevents spurious
        // mouseEntered events when views are re-laid-out inside scroll views
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
