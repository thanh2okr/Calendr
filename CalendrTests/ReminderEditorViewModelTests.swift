//
//  ReminderEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 25/10/2025.
//

import XCTest
import RxSwift
@testable import Calendr

class ReminderEditorViewModelTests: XCTestCase {

    func testDueDate() {

        let dateProvider = MockDateProvider()

        dateProvider.now = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30, second: 50)

        let dueDate = DueDate.withCurrentTime(
            at: .make(year: 2025, month: 10, day: 5, at: .start),
            adding: .init(hour: 5, minute: 10),
            using: dateProvider
        )

        XCTAssertEqual(dueDate.date, .make(year: 2025, month: 10, day: 5, hour: 15, minute: 40, second: 0))
    }

    func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
        XCTAssertTrue(viewModel.reminderCalendarSections.isEmpty)
        XCTAssertTrue(viewModel.eventCalendarSections.isEmpty)
    }

    func testViewModel_save_reminder_callsService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        let result = ReminderDialogResult(
            kind: .reminder,
            title: "My Reminder",
            notes: "",
            calendarID: "cal-1",
            tags: [],
            priority: .none,
            allDay: false,
            startDate: dueDate,
            endDate: dueDate.addingTimeInterval(3600)
        )

        viewModel.save(result: result)

        XCTAssertEqual(lastValue?.title, "My Reminder")
        XCTAssertEqual(lastValue?.calendar, "cal-1")
        XCTAssertEqual(lastValue?.date, dueDate)
        XCTAssertEqual(lastValue?.isAllDay, false)
        XCTAssertNil(lastValue?.notes)
        XCTAssertEqual(lastValue?.priority, 0)
    }

    func testViewModel_save_reminder_allDay() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        let result = ReminderDialogResult(
            kind: .reminder,
            title: "All Day",
            notes: "",
            calendarID: "cal-1",
            tags: [],
            priority: .none,
            allDay: true,
            startDate: dueDate,
            endDate: dueDate
        )

        viewModel.save(result: result)

        XCTAssertEqual(lastValue?.title, "All Day")
        XCTAssertEqual(lastValue?.isAllDay, true)
    }

    func testViewModel_save_reminder_withNotes_andPriority() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        let result = ReminderDialogResult(
            kind: .reminder,
            title: "Important Task",
            notes: "Some notes",
            calendarID: "cal-1",
            tags: [],
            priority: .high,
            allDay: false,
            startDate: dueDate,
            endDate: dueDate.addingTimeInterval(3600)
        )

        viewModel.save(result: result)

        XCTAssertEqual(lastValue?.notes, "Some notes")
        XCTAssertEqual(lastValue?.priority, ReminderPriority.high.ekPriority)
    }

    func testViewModel_save_event_callsService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: startDate), calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        let result = ReminderDialogResult(
            kind: .event,
            title: "Meeting",
            notes: "",
            calendarID: "cal-1",
            tags: [],
            priority: .none,
            allDay: false,
            startDate: startDate,
            endDate: endDate
        )

        viewModel.save(result: result)

        XCTAssertEqual(lastValue?.title, "Meeting")
        XCTAssertEqual(lastValue?.calendar, "cal-1")
        XCTAssertEqual(lastValue?.startDate, startDate)
        XCTAssertEqual(lastValue?.endDate, endDate)
        XCTAssertEqual(lastValue?.isAllDay, false)
        XCTAssertNil(lastValue?.notes)
    }

    func testViewModel_save_withError() {

        let calendarService = FailingCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = ReminderEditorViewModel(calendarService: calendarService)

        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertNil(viewModel.error)

        viewModel.save(result: .makeReminder(calendarID: ""))

        XCTAssertTrue(viewModel.isErrorVisible)
        XCTAssertEqual(viewModel.error?.localizedDescription, "Creation failed")

        viewModel.dismissError()

        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertNil(viewModel.error)
    }

    func testViewModel_save_withError_shouldNotCloseWindow() {

        let calendarService = FailingCalendarService()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = ReminderEditorViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.save(result: .makeReminder(calendarID: ""))

        XCTAssertTrue(viewModel.isErrorVisible)

        viewModel.dismissError()

        XCTAssertFalse(viewModel.isErrorVisible)

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_save_withSuccess_shouldCloseWindow() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let expectation = expectation(description: "Should close window")

        let viewModel = ReminderEditorViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.save(result: .makeReminder(calendarID: "cal-1"))

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_requestWindowClose_alwaysReturnsTrue() {

        let viewModel = ReminderEditorViewModel()

        XCTAssertTrue(viewModel.requestWindowClose())
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
    }

    func testViewModel_confirmClose_callsCallback() {

        let expectation = expectation(description: "Should call onCloseConfirmed")

        let viewModel = ReminderEditorViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.confirmClose()

        waitForExpectations(timeout: 0.1)
    }

    // MARK: - Calendar loading

    func testViewModel_calendars_shouldLoadBothKinds() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Reminders"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.reminderCalendarSections.count, 1)
        XCTAssertEqual(viewModel.eventCalendarSections.count, 1)
    }

    func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.reminderCalendarSections.count, 2)
        XCTAssertEqual(viewModel.reminderCalendarSections[0].account.title, "Google")
        XCTAssertEqual(viewModel.reminderCalendarSections[0].calendars.map(\.title), ["Tasks"])
        XCTAssertEqual(viewModel.reminderCalendarSections[1].account.title, "iCloud")
        XCTAssertEqual(viewModel.reminderCalendarSections[1].calendars.map(\.title), ["Personal", "Work"])
    }
}

private class FailingCalendarService: MockCalendarServiceProvider {

    override func createReminder(title: String, calendar: String, date: Date, isAllDay: Bool, notes: String?, priority: Int) -> Completable {
        return .error(.unexpected("Creation failed"))
    }
}

private extension ReminderEditorViewModel {

    convenience init(dueDate: Date = .now, calendarService: CalendarServiceProviding = MockCalendarServiceProvider()) {
        self.init(dueDate: .init(date: dueDate), calendarService: calendarService)
    }
}

private extension ReminderDialogResult {

    static func makeReminder(calendarID: String) -> ReminderDialogResult {
        ReminderDialogResult(
            kind: .reminder,
            title: "Test",
            notes: "",
            calendarID: calendarID,
            tags: [],
            priority: .none,
            allDay: false,
            startDate: .now,
            endDate: .now.addingTimeInterval(3600)
        )
    }
}
