//
//  GeneralSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

class GeneralSettingsViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    // Language
    private let languageLabel = Label(text: "Language")
    private let languageDropdown = Dropdown()

    // Menu Bar
    private let autoLaunchCheckbox = Checkbox(title: Strings.Settings.MenuBar.autoLaunch)
    private let showMenuBarIconCheckbox = Checkbox(title: Strings.Settings.MenuBar.showIcon)
    private let showMenuBarDateCheckbox = Checkbox(title: Strings.Settings.MenuBar.showDate)
    private let showMenuBarBackgroundCheckbox = Checkbox(title: Strings.Settings.MenuBar.showBackground)
    private let openOnHoverCheckbox = Checkbox(title: Strings.Settings.MenuBar.openOnHover)
    private let iconStyleDropdown = Dropdown()
    private let dateFormatDropdown = Dropdown()
    private let dateFormatTextField = NSTextField()

    // Next Event
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.NextEvent.showNextEvent)
    private let nextEventRangeStepperLabel = Label()
    private let nextEventRangeStepper = NSStepper()
    private let nextEventGrabAttentionLabel = Label(text: Strings.Settings.NextEvent.grabAttention)
    private let nextEventFlashingCheckbox = Checkbox(title: Strings.Settings.NextEvent.GrabAttention.flashing)
    private let nextEventSoundCheckbox = Checkbox(title: Strings.Settings.NextEvent.GrabAttention.sound)

    // Calendar
    private let firstWeekdayPrev = ImageButton(image: Icons.Settings.prev)
    private let firstWeekdayNext = ImageButton(image: Icons.Settings.next)
    private let highlightedWeekdaysButtons = NSStackView()
    private let highlightedWeekdaysColorWell = NSColorWell(style: .minimal)
    private let weekCountLabel = Label(text: Strings.Settings.Calendar.weekCount)
    private let weekCountStepperLabel = Label()
    private let weekCountStepper = NSStepper()
    private let showMonthOutlineCheckbox = Checkbox(title: Strings.Settings.Calendar.showMonthOutline)
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let showDeclinedEventsCheckbox = Checkbox(title: Strings.Settings.Calendar.showDeclinedEvents)
    private let preserveSelectedDateCheckbox = Checkbox(title: Strings.Settings.Calendar.preserveSelectedDate)
    private let dateHoverOptionCheckbox = Checkbox(title: Strings.Settings.Calendar.dateHoverOption)
    private let eventDotsLabel = Label(text: Strings.Settings.Calendar.eventDots)
    private let eventDotsDropdown = Dropdown()
    private let calendarAppViewModeLabel = Label(text: Strings.Settings.Calendar.calendarAppViewMode)
    private let calendarAppViewModeDropdown = Dropdown()
    private let defaultCalendarAppLabel = Label(text: Strings.Settings.Calendar.defaultCalendarApp)
    private let defaultCalendarAppDropdown = Dropdown()

    // Events
    private let showMapCheckbox = Checkbox(title: Strings.Settings.Events.showMap)
    private let mapBlacklistButton = ImageButton(image: Icons.Settings.blacklist)
    private let showFinishedEventsCheckbox = Checkbox(title: Strings.Settings.Events.showFinishedEvents)
    private let showOverdueCheckbox = Checkbox(title: Strings.Settings.Events.showOverdueReminders)
    private let showAllDayDetailsCheckbox = Checkbox(title: Strings.Settings.Events.showAllDayDetails)
    private let showRecurrenceCheckbox = Checkbox(title: Strings.Settings.Events.showRecurrenceIndicator)
    private let forceLocalTimeZoneCheckbox = Checkbox(title: Strings.Settings.Events.forceLocalTimeZone)
    private let showEventListSummaryCheckbox = Checkbox(title: Strings.Settings.Events.showEventListSummary)
    private let showVideoCallOnlyCheckbox = Checkbox(title: Strings.Settings.Events.showVideoCallOnly)
    private let futureEventsLabel = Label(text: Strings.Settings.Events.showFutureEvents)
    private let futureEventsStepperLabel = Label()
    private let futureEventsStepper = NSStepper()
    private let maxTitleLinesLabel = Label(text: Strings.Settings.Events.maxTitleLines)
    private let maxTitleLinesStepperLabel = Label()
    private let maxTitleLinesStepper = NSStepper()

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.General.view)

        iconStyleDropdown.setAccessibilityIdentifier(Accessibility.Settings.General.iconStyleDropdown)
        dateFormatDropdown.setAccessibilityIdentifier(Accessibility.Settings.General.dateFormatDropdown)
        dateFormatTextField.setAccessibilityIdentifier(Accessibility.Settings.General.dateFormatInput)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        let allSections = Sections.create([
            makeSection(title: "Language",                  content: languageContent),
            makeSection(title: Strings.Settings.menuBar,    content: menuBarContent),
            makeSection(title: Strings.Settings.nextEvent,  content: nextEventContent),
            makeSection(title: Strings.Settings.calendar,   content: calendarContent),
            makeSection(title: Strings.Settings.events,     content: eventsContent),
        ]).disposed(by: disposeBag)

        let contentStack = NSStackView(views: allSections)
            .with(spacing: Constants.contentSpacing)
            .with(orientation: .vertical)
            .with(hugging: .defaultHigh, for: .horizontal)
            .with(hugging: .defaultLow, for: .vertical)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = contentStack

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        if let clip = scrollView.contentView as? NSClipView {
            NSLayoutConstraint.activate([
                contentStack.topAnchor.constraint(equalTo: clip.topAnchor),
                contentStack.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
                // intentionally NO bottom constraint — lets content scroll freely
            ])
        }

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        iconStyleDropdown.height(equalTo: showMenuBarIconCheckbox)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Ensure scroll position starts at top when tab is opened
        if let clipView = view.subviews.compactMap({ $0 as? NSScrollView }).first?.contentView {
            clipView.scroll(to: .zero)
        }
    }

    func fittingSize(minWidth: CGFloat) -> NSSize {
        return NSSize(width: minWidth, height: 540)
    }

    private lazy var languageContent: NSView = {
        languageDropdown.isBordered = false
        languageDropdown.setContentHuggingPriority(.required, for: .horizontal)

        return NSStackView(views: [languageLabel, .spacer, languageDropdown])
    }()

    private lazy var menuBarContent: NSView = {

        dateFormatDropdown.isBordered = false
        dateFormatDropdown.alignment = .center

        dateFormatTextField.placeholderString = viewModel.dateFormatPlaceholder
        dateFormatTextField.refusesFirstResponder = true
        dateFormatTextField.focusRingType = .none
        dateFormatTextField.cell?.isScrollable = true

        iconStyleDropdown.isBordered = false
        iconStyleDropdown.setContentHuggingPriority(.required, for: .horizontal)

        let iconStyle = NSStackView(views: [
            showMenuBarIconCheckbox,
            iconStyleDropdown
        ])

        let dateFormat = NSStackView(views: [
            dateFormatDropdown,
            dateFormatTextField
        ])

        return NSStackView(views: [
            autoLaunchCheckbox,
            iconStyle,
            showMenuBarDateCheckbox,
            dateFormat,
            showMenuBarBackgroundCheckbox,
            openOnHoverCheckbox,
            .spacer
        ])
        .with(orientation: .vertical)
    }()

    private lazy var nextEventContent: NSView = {

        // Next event range

        nextEventRangeStepper.minValue = 0
        nextEventRangeStepper.maxValue = 24 * 60
        nextEventRangeStepper.valueWraps = false
        nextEventRangeStepper.refusesFirstResponder = true
        nextEventRangeStepper.focusRingType = .none

        nextEventRangeStepperLabel.font = .systemFont(ofSize: 13)

        // Next event stack view
        let showNextEventStack = NSStackView(views: [showNextEventCheckbox, .spacer, nextEventRangeStepperLabel, nextEventRangeStepper])
        let grabAttentionStack = NSStackView(views: [nextEventFlashingCheckbox, nextEventSoundCheckbox]).with(insets: .init(horizontal: 16))
        return NSStackView(views: [
            showNextEventStack,
            nextEventGrabAttentionLabel,
            grabAttentionStack

        ]).with(orientation: .vertical)
    }()

    private lazy var showDeclinedEventsTooltip: NSView = {

        let tooltipViewController = NSViewController()
        let view = NSView()
        tooltipViewController.view = view
        let label = Label(text: Strings.Settings.Calendar.showDeclinedEventsTooltip)
        label.preferredMaxLayoutWidth = 190
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.addSubview(label)
        label.edges(equalTo: view, margin: 8)

        let button = ImageButton(image: Icons.Settings.tooltip, cursor: nil)

        let popover = NSPopover()
        popover.contentViewController = tooltipViewController
        popover.behavior = .transient
        popover.animates = false

        button.rx.isHovered
            .bind { isHovered in
                guard isHovered else { return popover.performClose(nil) }
                popover.show(relativeTo: .zero, of: button, preferredEdge: .maxX)
            }
            .disposed(by: disposeBag)

        return button
    }()

    private lazy var calendarAppStack: NSView? = {
        guard viewModel.calendarAppOptions.count > 1 else {
            return nil
        }
        return NSStackView(views: [defaultCalendarAppLabel, defaultCalendarAppDropdown])
    }()

    private lazy var calendarContent: NSView = {

        firstWeekdayPrev.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        firstWeekdayNext.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)

        eventDotsDropdown.isBordered = false
        eventDotsDropdown.setContentHuggingPriority(.required, for: .horizontal)

        calendarAppViewModeDropdown.isBordered = false
        calendarAppViewModeDropdown.setContentHuggingPriority(.required, for: .horizontal)

        weekCountStepper.minValue = 6
        weekCountStepper.maxValue = 10
        weekCountStepper.valueWraps = false
        weekCountStepper.refusesFirstResponder = true
        weekCountStepper.focusRingType = .none

        let is26 = if #available(macOS 26.0, *) { true } else { false }

        highlightedWeekdaysColorWell.wantsLayer = true
        highlightedWeekdaysColorWell.width(equalTo: 22)
        highlightedWeekdaysColorWell.height(equalTo: 22)

        return NSStackView(views: [
            NSStackView(views: [firstWeekdayPrev, highlightedWeekdaysButtons, firstWeekdayNext, highlightedWeekdaysColorWell])
                .with(distribution: .fillProportionally),
            .dummy,
            is26 ? nil : showMonthOutlineCheckbox,  // glass window handles separation on macOS 26
            showWeekNumbersCheckbox,
            NSStackView(views: [showDeclinedEventsCheckbox, showDeclinedEventsTooltip]),
            preserveSelectedDateCheckbox,
            dateHoverOptionCheckbox,
            is26 ? nil : .dummy,
            NSStackView(
                views: [
                    NSStackView(views: [weekCountLabel, .spacer, weekCountStepperLabel, weekCountStepper]),
                    NSStackView(views: [eventDotsLabel, eventDotsDropdown]),
                    NSStackView(views: [calendarAppViewModeLabel, calendarAppViewModeDropdown]),
                    calendarAppStack
                ].compact()
            )
            .with(spacing: is26 ? 0 : 4)
            .with(orientation: .vertical)
            .with(distribution: .fillEqually)
        ].compact())
        .with(orientation: .vertical)
    }()

    private lazy var eventsContent: NSView = {

        // Future events range

        futureEventsStepper.minValue = 0
        futureEventsStepper.maxValue = 31
        futureEventsStepper.valueWraps = false
        futureEventsStepper.refusesFirstResponder = true
        futureEventsStepper.focusRingType = .none

        futureEventsStepperLabel.font = .systemFont(ofSize: 13)

        // Max title lines
        maxTitleLinesStepper.minValue = 1
        maxTitleLinesStepper.maxValue = 10
        maxTitleLinesStepper.valueWraps = false
        maxTitleLinesStepper.refusesFirstResponder = true
        maxTitleLinesStepper.focusRingType = .none

        maxTitleLinesStepperLabel.font = .systemFont(ofSize: 13)

        // Future events stack view
        let futureEventsStack = NSStackView(views: [futureEventsLabel, .spacer, futureEventsStepperLabel, futureEventsStepper])
        let maxTitleLinesStack = NSStackView(views: [maxTitleLinesLabel, .spacer, maxTitleLinesStepperLabel, maxTitleLinesStepper])

        return NSStackView(views: [
            NSStackView(views: [showMapCheckbox, mapBlacklistButton]),
            showFinishedEventsCheckbox,
            showOverdueCheckbox,
            showAllDayDetailsCheckbox,
            showRecurrenceCheckbox,
            forceLocalTimeZoneCheckbox,
            showEventListSummaryCheckbox,
            showVideoCallOnlyCheckbox,
            futureEventsStack,
            maxTitleLinesStack
        ])
        .with(orientation: .vertical)
        .with(insets: .init(bottom: 4))
    }()

    private func setUpBindings() {
        setUpLanguage()
        setUpMenuBar()
        setUpNextEvent()
        setUpCalendar()
        setUpEvents()
    }

    private func setUpLanguage() {

        // Language options: (display name, language code or nil for system default)
        let languageOptions: [(title: String, code: String?)] = [
            ("System (Default)", nil),
            ("English", "en"),
            ("Tiếng Việt", "vi"),
        ]

        let menu = NSMenu()
        for option in languageOptions {
            let item = NSMenuItem()
            item.title = option.title
            menu.addItem(item)
        }
        languageDropdown.menu = menu

        // Read current selection from AppleLanguages
        let currentCode = (UserDefaults.standard.array(forKey: "AppleLanguages") as? [String])?.first
        let selectedIndex = languageOptions.firstIndex(where: { $0.code == currentCode }) ?? 0
        languageDropdown.selectItem(at: selectedIndex)

        languageDropdown.rx.controlProperty(
            getter: { _ in self.languageDropdown.indexOfSelectedItem },
            setter: { $0.selectItem(at: $1) }
        )
        .skip(1)
        .bind { [weak self] index in
            guard let self else { return }
            let selected = languageOptions[index]
            if let code = selected.code {
                UserDefaults.standard.set([code], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
            // Prompt restart
            let alert = NSAlert()
            alert.messageText = selected.code == "vi" ? "Khởi động lại để áp dụng" : "Restart to Apply"
            alert.informativeText = selected.code == "vi"
                ? "CalX cần được khởi động lại để thay đổi ngôn ngữ."
                : "CalX needs to restart to apply the language change."
            alert.addButton(withTitle: selected.code == "vi" ? "Khởi động lại" : "Restart Now")
            alert.addButton(withTitle: selected.code == "vi" ? "Để sau" : "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSApp.terminate(nil)
            }
        }
        .disposed(by: disposeBag)
    }

    private func setUpMenuBar() {

        bind(
            control: autoLaunchCheckbox,
            observable: viewModel.autoLaunch,
            observer: viewModel.toggleAutoLaunch
        )
        .disposed(by: disposeBag)

        bind(
            control: showMenuBarIconCheckbox,
            observable: viewModel.showStatusItemIcon,
            observer: viewModel.toggleStatusItemIcon
        )
        .disposed(by: disposeBag)

        setUpIconStyle()

        bind(
            control: showMenuBarDateCheckbox,
            observable: viewModel.showStatusItemDate,
            observer: viewModel.toggleStatusItemDate
        )
        .disposed(by: disposeBag)

        setUpDateFormat()

        bind(
            control: showMenuBarBackgroundCheckbox,
            observable: viewModel.showStatusItemBackground,
            observer: viewModel.toggleStatusItemBackground
        )
        .disposed(by: disposeBag)

        bind(
            control: openOnHoverCheckbox,
            observable: viewModel.openOnHover,
            observer: viewModel.toggleOpenOnHover
        )
        .disposed(by: disposeBag)
    }

    private func setUpNextEvent() {

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showEventStatusItem,
            observer: viewModel.toggleEventStatusItem
        )
        .disposed(by: disposeBag)

        setUpNextEventRangeStepper()

        bind(
            control: nextEventFlashingCheckbox,
            observable: viewModel.eventStatusItemFlashing,
            observer: viewModel.toggleEventStatusItemFlashing
        )
        .disposed(by: disposeBag)

        bind(
            control: nextEventSoundCheckbox,
            observable: viewModel.eventStatusItemSound,
            observer: viewModel.toggleEventStatusItemSound
        )
        .disposed(by: disposeBag)
    }

    private func setUpNextEventRangeStepper() {

        let rangeStepperProperty = nextEventRangeStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.eventStatusItemCheckRange
            .bind(to: rangeStepperProperty)
            .disposed(by: disposeBag)

        rangeStepperProperty
            .bind(to: viewModel.eventStatusItemCheckRangeObserver)
            .disposed(by: disposeBag)

        viewModel.eventStatusItemCheckRangeLabel
            .bind(to: nextEventRangeStepperLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func setUpIconStyle() {

        let iconStyleControl = iconStyleDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        Observable.combineLatest(
            viewModel.iconStyleOptions, iconStyleControl.skip(1)
        )
        .map { $0[$1].style }
        .bind(to: viewModel.statusItemIconStyleObserver)
        .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.iconStyleOptions, viewModel.statusItemIconStyle
        )
        .bind { [dropdown = iconStyleDropdown] options, iconStyle in
            let menu = NSMenu()
            let width = options.map(\.image.size.width).reduce(0, max)
            for option in options {
                let item = NSMenuItem()
                item.title = " "
                item.image = option.image.with(padding: .init(x: (width - option.image.size.width) / 2, y: 0))
                menu.addItem(item)
            }
            dropdown.menu = menu
            dropdown.selectItem(at: options.firstIndex(where: { $0.style == iconStyle }) ?? 0)
        }
        .disposed(by: disposeBag)

        viewModel.showStatusItemIcon
            .map(!)
            .bind(to: iconStyleDropdown.rx.isHidden)
            .disposed(by: disposeBag)
    }

    private func setUpDateFormat() {

        let dateFormatControl = dateFormatDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        Observable.combineLatest(
            viewModel.dateFormatOptions, dateFormatControl.skip(1)
        )
        .compactMap { $0[safe: $1]?.style }
        .bind(to: viewModel.statusItemDateStyleObserver)
        .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.dateFormatOptions, viewModel.statusItemDateStyle
        )
        .bind { [dropdown = dateFormatDropdown] options, dateStyle in
            dropdown.removeAllItems()
            dropdown.addItems(withTitles: options.map(\.title))
            dropdown.selectItem(at: dateStyle.isCustom ? dropdown.numberOfItems - 1: options.firstIndex(where: { $0.style == dateStyle }) ?? 0)
        }
        .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind(to: dateFormatDropdown.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind(to: dateFormatTextField.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map(!)
            .bind(to: dateFormatTextField.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map(true)
            .bind(to: view.rx.needsLayout)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .skip(1)
            .matching(true)
            .bind(to: dateFormatTextField.rx.hasFocus)
            .disposed(by: disposeBag)

        dateFormatTextField.rx.text
            .skip(1)
            .skipNil()
            .bind(to: viewModel.statusItemDateFormatObserver)
            .disposed(by: disposeBag)

        viewModel.statusItemDateFormat
            .bind(to: dateFormatTextField.rx.text)
            .disposed(by: disposeBag)
    }

    private func setUpEventDots() {

        let eventDotsControl = eventDotsDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        let options = EventDotsStyle.allCases
        eventDotsDropdown.addItems(withTitles: options.map { "\($0.title) " })

        eventDotsControl
            .skip(1)
            .map { options[$0] }
            .bind(to: viewModel.eventDotsStyleObserver)
            .disposed(by: disposeBag)

        viewModel.eventDotsStyle
            .compactMap(options.firstIndex(of:))
            .bind(to: eventDotsControl)
            .disposed(by: disposeBag)
    }

    private func setUpCalendarAppViewMode() {

        let calendarAppViewModeControl = calendarAppViewModeDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        let options = viewModel.calendarAppViewModeOptions
        calendarAppViewModeDropdown.addItems(withTitles: options.map { "\($0.title) " })

        calendarAppViewModeControl
            .skip(1)
            .map { options[$0].mode }
            .bind(to: viewModel.calendarAppViewModeObserver)
            .disposed(by: disposeBag)

        viewModel.calendarAppViewMode
            .compactMap(options.map(\.mode).firstIndex(of:))
            .bind(to: calendarAppViewModeControl)
            .disposed(by: disposeBag)
    }

    private func setUpDefaultCalendarApp() {

        guard calendarAppStack != nil else {
            return
        }
        defaultCalendarAppDropdown.isBordered = false
        defaultCalendarAppDropdown.imagePosition = .imageOnly
        defaultCalendarAppDropdown.setContentHuggingPriority(.required, for: .horizontal)

        let options = viewModel.calendarAppOptions

        let menu = NSMenu()

        for (index, option) in options.enumerated() {
            let item = NSMenuItem()
            item.image = option.icon.with(size: .init(width: 16, height: 16))
            item.title = option.name
            item.tag = index
            menu.addItem(item)
        }

        defaultCalendarAppDropdown.menu = menu

        let defaultCalendarAppControl = defaultCalendarAppDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        defaultCalendarAppControl
            .skip(1)
            .map { options[$0].id }
            .bind(to: viewModel.defaultCalendarAppObserver)
            .disposed(by: disposeBag)

        viewModel.defaultCalendarApp
            .compactMap(options.map(\.id).firstIndex(of:))
            .bind(to: defaultCalendarAppControl)
            .disposed(by: disposeBag)
    }

    private func setUpCalendar() {

        setUpfirstWeekday()
        setUpHighlightedWeekdays()
        setUpHighlightedWeekdaysColor()
        setUpWeekCountStepper()

        bind(
            control: showMonthOutlineCheckbox,
            observable: viewModel.showMonthOutline,
            observer: viewModel.toggleMonthOutline
        )
        .disposed(by: disposeBag)

        bind(
            control: showWeekNumbersCheckbox,
            observable: viewModel.showWeekNumbers,
            observer: viewModel.toggleWeekNumbers
        )
        .disposed(by: disposeBag)

        bind(
            control: showDeclinedEventsCheckbox,
            observable: viewModel.showDeclinedEvents,
            observer: viewModel.toggleDeclinedEvents
        )
        .disposed(by: disposeBag)

        bind(
            control: preserveSelectedDateCheckbox,
            observable: viewModel.preserveSelectedDate,
            observer: viewModel.togglePreserveSelectedDate
        )
        .disposed(by: disposeBag)

        bind(
            control: dateHoverOptionCheckbox,
            observable: viewModel.dateHoverOption,
            observer: viewModel.toggleDateHoverOption
        )
        .disposed(by: disposeBag)

        setUpEventDots()
        setUpCalendarAppViewMode()
        setUpDefaultCalendarApp()
    }

    private func setUpWeekCountStepper() {

        let rangeStepperProperty = weekCountStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.weekCount
            .bind(to: rangeStepperProperty)
            .disposed(by: disposeBag)

        rangeStepperProperty
            .bind(to: viewModel.weekCountObserver)
            .disposed(by: disposeBag)

        viewModel.weekCount.map(\.description)
            .bind(to: weekCountStepperLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func setUpfirstWeekday() {

        firstWeekdayPrev.rx.tap
            .bind(to: viewModel.firstWeekdayPrevObserver)
            .disposed(by: disposeBag)

        firstWeekdayNext.rx.tap
            .bind(to: viewModel.firstWeekdayNextObserver)
            .disposed(by: disposeBag)
    }

    private func makeWeekDayButton(weekDay: WeekDay) -> DisposableWrapper<NSButton> {

        let button = CursorButton(cursor: .pointingHand)
        button.title = weekDay.title
        button.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        button.refusesFirstResponder = true
        button.bezelStyle = .accessoryBar
        button.setButtonType(.pushOnPushOff)

        let disposable = bind(
            control: button,
            observable: viewModel.highlightedWeekdays.map { $0.contains(weekDay.index) },
            observer: viewModel.toggleHighlightedWeekday.mapObserver { _ in weekDay.index }
        )

        return .init(value: button, disposable: disposable)
    }

    private func setUpHighlightedWeekdaysColor() {

        NSColorPanel.shared.showsAlpha = true

        let colorWellProperty = highlightedWeekdaysColorWell.rx.controlProperty(
            getter: \.color,
            setter: { $0.color = $1 }
        )

        viewModel.highlightedWeekdaysColor
            .bind(to: colorWellProperty)
            .disposed(by: disposeBag)

        colorWellProperty.skip(1)
            .bind(to: viewModel.highlightedWeekdaysColorObserver)
            .disposed(by: disposeBag)
    }

    private func setUpHighlightedWeekdays() {

        var weekDaysDisposeBag: DisposeBag!

        viewModel.highlightedWeekdaysOptions
            .distinctUntilChanged { $0.map(\.title) }
            .map { [weak self] in
                weekDaysDisposeBag = DisposeBag()
                return $0.compactMap {
                    self?.makeWeekDayButton(weekDay: $0).disposed(by: weekDaysDisposeBag)
                }
            }
            .bind(to: highlightedWeekdaysButtons.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    private func setUpEvents() {

        setUpFutureEventsStepper()
        setUpMaxTitleLinesStepper()

        mapBlacklistButton.rx.tap.bind { [weak self] in
            guard let self else { return }

            presentAsModalWindow(
                MapBlackListViewController(
                    viewModel: viewModel.mapBlackListViewModel()
                )
            )
        }
        .disposed(by: disposeBag)

        bind(
            control: showMapCheckbox,
            observable: viewModel.showMap,
            observer: viewModel.toggleMap
        )
        .disposed(by: disposeBag)

        bind(
            control: showFinishedEventsCheckbox,
            observable: viewModel.showPastEvents,
            observer: viewModel.togglePastEvents
        )
        .disposed(by: disposeBag)

        bind(
            control: showOverdueCheckbox,
            observable: viewModel.showOverdueReminders,
            observer: viewModel.toggleOverdueReminders
        )
        .disposed(by: disposeBag)

        bind(
            control: showAllDayDetailsCheckbox,
            observable: viewModel.showAllDayDetails,
            observer: viewModel.toggleAllDayDetails
        )
        .disposed(by: disposeBag)

        bind(
            control: showRecurrenceCheckbox,
            observable: viewModel.showRecurrenceIndicator,
            observer: viewModel.toggleRecurrenceIndicator
        )
        .disposed(by: disposeBag)

        bind(
            control: forceLocalTimeZoneCheckbox,
            observable: viewModel.forceLocalTimeZone,
            observer: viewModel.toggleForceLocalTimeZone
        )
        .disposed(by: disposeBag)

        bind(
            control: showEventListSummaryCheckbox,
            observable: viewModel.showEventListSummary,
            observer: viewModel.toggleEventListSummary
        )
        .disposed(by: disposeBag)

        bind(
            control: showVideoCallOnlyCheckbox,
            observable: viewModel.showVideoCallOnly,
            observer: viewModel.toggleShowVideoCallOnly
        )
        .disposed(by: disposeBag)
    }

    private func setUpMaxTitleLinesStepper() {

        let stepperProperty = maxTitleLinesStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.eventTitleLines
            .bind(to: stepperProperty)
            .disposed(by: disposeBag)

        stepperProperty
            .bind(to: viewModel.eventTitleLinesObserver)
            .disposed(by: disposeBag)

        viewModel.eventTitleLines.map(\.description)
            .bind(to: maxTitleLinesStepperLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func setUpFutureEventsStepper() {

        let rangeStepperProperty = futureEventsStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.futureEventsDays
            .bind(to: rangeStepperProperty)
            .disposed(by: disposeBag)

        rangeStepperProperty
            .bind(to: viewModel.futureEventsDaysObserver)
            .disposed(by: disposeBag)

        viewModel.futureEventsStepperLabel
            .bind(to: futureEventsStepperLabel.rx.text)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
