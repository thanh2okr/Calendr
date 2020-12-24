//
//  EventListViewModel.swift
//  Calendr
//
//  Created by Paker on 26/02/2021.
//

import Cocoa
import RxSwift

enum EventListItem {
    case section(String, isOverdue: Bool = false)
    case interval(EventIntervalViewModel)
    case event(EventViewModel)
}

private extension EventListItem {
    var event: EventViewModel? { if case .event(let event) = self { event } else { nil } }
}

struct EventListSummaryItem: Equatable {
    let colors: Set<NSColor>
    let count: Int
}

struct EventListSummary: Equatable {
    let overdue: EventListSummaryItem
    let allday: EventListSummaryItem
    let today: EventListSummaryItem
}

class EventListViewModel {

    private let disposeBag = DisposeBag()

    private let source: EventDetailsSource
    private let isShowingDetailsModal: BehaviorSubject<Bool>
    private let callback: AnyObserver<ContextCallbackAction>
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let geocoder: GeocodeServiceProviding
    private let weatherService: WeatherServiceProviding
    private let workspace: WorkspaceServiceProviding
    private let localStorage: LocalStorageProvider
    private let settings: EventListSettings
    private let scheduler: SchedulerType
    private let refreshScheduler: SchedulerType
    private let eventsScheduler: SchedulerType

    private let dateFormatter: DateFormatter
    private let relativeFormatter: RelativeDateTimeFormatter
    private let dateComponentsFormatter: DateComponentsFormatter

    private struct EventListProps: Equatable {
        var events: [EventModel]
        let date: Date
        let showPastEvents: Bool
        let showOverdueReminders: Bool
        let showVideoCallOnly: Bool
        let isTodaySelected: Bool
    }

    private struct EventListGroups {
        let overdue: [EventListItem]
        let allday: [EventListItem]
        let today: [EventListItem]
        let future: [EventListItem]
    }

    private let groups = BehaviorSubject<EventListGroups>(value: .init(overdue: [], allday: [], today: [], future: []))

    let items: Observable<[EventListItem]>
    let summary: Observable<EventListSummary>

    init(
        source: EventDetailsSource,
        eventsObservable: Observable<DateEvents>,
        isShowingDetailsModal: BehaviorSubject<Bool>,
        callback: AnyObserver<ContextCallbackAction>,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider,
        settings: EventListSettings,
        scheduler: SchedulerType,
        refreshScheduler: SchedulerType,
        eventsScheduler: SchedulerType
    ) {
        self.source = source
        self.isShowingDetailsModal = isShowingDetailsModal
        self.callback = callback
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.geocoder = geocoder
        self.weatherService = weatherService
        self.workspace = workspace
        self.localStorage = localStorage
        self.settings = settings
        self.scheduler = scheduler
        self.refreshScheduler = refreshScheduler
        self.eventsScheduler = eventsScheduler

        dateFormatter = DateFormatter(template: "EEEE d MMM", calendar: dateProvider.calendar)

        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named

        dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.calendar = dateProvider.calendar
        dateComponentsFormatter.unitsStyle = .abbreviated
        dateComponentsFormatter.allowedUnits = [.hour, .minute]

        items = groups.map {
            $0.overdue + $0.allday + $0.today + $0.future
        }.share(replay: 1)

        summary = groups.flatMapLatest { groups in

            let overduePast = Observable.just(groups.overdue.compactMap(\.event))

            let overdueToday: Observable<[EventViewModel]> = Observable.combineLatest(
                groups.today
                    .compactMap(\.event)
                    .filter(\.type.isReminder)
                    .map { event -> Observable<EventViewModel?> in
                        event.isInProgress.map { $0 ? event : nil }
                    }
            ).map { $0.compact() }

            let allday = Observable.just(groups.allday.compactMap(\.event))

            // pending events except overdue today
            let today: Observable<[EventViewModel]> = Observable.combineLatest(
                groups.today.compactMap(\.event).map { event -> Observable<EventViewModel?> in
                    Observable
                        .combineLatest(event.isFaded, event.isInProgress)
                        .map { isFaded, isInProgress -> EventViewModel? in
                            isFaded || (event.type.isReminder && isInProgress) ? nil : event
                        }
                }
            ).map { $0.compact() }

            func makeItem(_ items: [EventViewModel]) -> EventListSummaryItem {
                let r = Dictionary(grouping: items, by: \.color)
                return .init(colors: Set(r.keys) , count: r.values.map(\.count).reduce(0, +))
            }

            return Observable.combineLatest(overduePast, overdueToday, allday, today)
                .map { overduePast, overdueToday, allday, today in
                    EventListSummary(
                        overdue: makeItem(overduePast + overdueToday),
                        allday: makeItem(allday),
                        today: makeItem(today)
                    )
                }
        }
        .share(replay: 1)

        let listProps = Observable.combineLatest(
            eventsObservable,
            settings.showPastEvents,
            settings.showOverdueReminders,
            settings.showVideoCallOnly,
            isShowingDetailsModal
        )
        .compactMap { dateEvents, showPast, showOverdue, showVideoCallOnly, isShowingDetailsModal -> EventListProps? in
            guard !isShowingDetailsModal else { return nil }

            let isTodaySelected = dateProvider.calendar.isDate(dateEvents.date, inSameDayAs: dateProvider.now)

            var events = dateEvents.events
            if showVideoCallOnly {
                events = events.filter { $0.detectLink(using: workspace)?.isMeeting == true }
            }

            return .init(
                events: events,
                date: dateEvents.date,
                showPastEvents: showPast,
                showOverdueReminders: showOverdue,
                showVideoCallOnly: showVideoCallOnly,
                isTodaySelected: isTodaySelected
            )
        }
        .distinctUntilChanged()

        let propsWithRefresh = listProps.flatMapLatest { props -> Observable<EventListProps> in

            guard props.isTodaySelected && !props.showPastEvents, !props.events.isEmpty else {
                return .just(props)
            }

            // schedule refresh for every event end to hide past events
            let ticker = Observable.merge(
                props.events
                    .filter {
                        !$0.isAllDay && !$0.type.isReminder && $0.range(using: dateProvider).endsToday
                    }
                    .map {
                        Int(dateProvider.now.distance(to: $0.end).rounded(.up)) + 1
                    }
                    .filter { $0 >= 0 }
                    .map {
                        Observable<Int>.timer(.seconds($0), scheduler: refreshScheduler)
                    }
            )
            .void()
            .startWith(())

            return ticker.map {
                var props = props
                props.events = props.events.filter {
                    if case .reminder(let completed) = $0.type {
                        return !completed
                    }
                    return $0.isAllDay || !$0.range(using: dateProvider).isPast
                }
                return props
            }
        }

        // build event list
        propsWithRefresh.compactMap { [weak self] props -> EventListGroups? in
            guard let self else { return nil }

            if source == .menubar {
                let items = props.events.map { EventListItem.event(self.makeEventViewModel($0, true)) }
                return EventListGroups(overdue: [], allday: [], today: items, future: [])
            }

            let overdue = overdueViewModels(props)
            let allday = allDayViewModels(props)
            let today = todayViewModels(props, withFuture: false)
            let future = todayViewModels(props, withFuture: true)

            return EventListGroups(overdue: overdue, allday: allday, today: today, future: future)
        }
        .bind(to: groups)
        .disposed(by: disposeBag)
    }

    // MARK: - Private

    private func makeEventViewModel(_ event: EventModel, _ isTodaySelected: Bool) -> EventViewModel {
        EventViewModel(
            source: source,
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            localStorage: localStorage,
            settings: settings,
            isShowingDetailsModal: isShowingDetailsModal.asObserver(),
            callback: callback,
            isTodaySelected: isTodaySelected,
            scheduler: eventsScheduler
        )
    }

    private func isOverdue(_ event: EventModel, _ isTodaySelected: Bool) -> Bool {
        isTodaySelected &&
        event.type == .reminder(completed: false) &&
        dateProvider.calendar.isDate(event.start, lessThan: dateProvider.now, granularity: .day)
    }

    private func isFuture(_ event: EventModel, from date: Date) -> Bool {
        dateProvider.calendar.isDate(event.start, greaterThan: date, granularity: .day)
    }

    private func overdueViewModels(_ props: EventListProps) -> [EventListItem] {

        guard props.showOverdueReminders else { return [] }

        let items = props.events
            .filter { isOverdue($0, props.isTodaySelected) }
            .sorted(by: \.start)
            .map { EventListItem.event(makeEventViewModel($0, props.isTodaySelected)) }

        guard !items.isEmpty else { return [] }
        return [.section(Strings.Reminder.Status.overdue, isOverdue: true)] + items
    }

    private func allDayViewModels(_ props: EventListProps) -> [EventListItem] {

        var viewModels: [EventListItem] = props.events
            .filter {
                $0.isAllDay &&
                !isFuture($0, from: props.date) &&
                !isOverdue($0, props.isTodaySelected)
            }
            .sorted(by: \.calendar.color.hashValue)
            .map { .event(makeEventViewModel($0, props.isTodaySelected)) }

        if !viewModels.isEmpty {
            viewModels.insert(.section(Strings.Event.allDay), at: 0)
        }
        return viewModels
    }

    private func todayViewModels(_ props: EventListProps, withFuture: Bool) -> [EventListItem] {

        return props.events
            .filter {
                let isFuture = isFuture($0, from: props.date)
                return (
                    isFuture == withFuture &&
                    (!$0.isAllDay || isFuture) &&
                    !isOverdue($0, props.isTodaySelected)
                )
            }
            .sorted {
                ($0.start, $0.end, $0.isAllDay) < ($1.start, $1.end, $1.isAllDay)
            }
            .prevMap { prev, curr -> [EventListItem] in

                let viewModel = makeEventViewModel(curr, props.isTodaySelected)
                let eventItem: EventListItem = .event(viewModel)

                // if first event or different date, show section header
                guard let prev, dateProvider.calendar.isDate(prev.start, inSameDayAs: curr.start) else {
                    // Future events: single "Upcoming" header, only on first item
                    if withFuture {
                        guard prev == nil else { return [eventItem] }
                        return [.section("Upcoming"), eventItem]
                    }

                    let isToday = props.isTodaySelected && dateProvider.isDateInToday(curr.start)
                    let title = isToday ? Strings.Formatter.Date.today : dateFormatter.string(from: curr.start)
                    return [.section(title), eventItem]
                }

                guard prev.end.distance(to: curr.start) >= 60 else {
                    return [eventItem]
                }

                let fade = Observable
                    .merge(viewModel.isFaded, viewModel.isInProgress)
                    .take(until: \.isTrue, behavior: .inclusive)

                let ticker = Observable<Int>.interval(.seconds(1), scheduler: scheduler).void().startWith(())

                let interval = ticker.compactMap { [dateProvider, dateComponentsFormatter] in

                    let isUpcoming = dateProvider.calendar.isDate(
                        dateProvider.now, in: (prev.end, curr.start),
                        granularity: .second
                    )

                    let truncatedNow = Date(timeIntervalSince1970: floor(dateProvider.now.timeIntervalSince1970 / 60) * 60)

                    return dateComponentsFormatter.string(
                        from: isUpcoming ? truncatedNow : prev.end,
                        to: curr.start
                    )
                }

                let intervalViewModel = EventIntervalViewModel(text: interval, fade: fade)

                return [.interval(intervalViewModel), eventItem]
            }
            .flatten()
    }
}
