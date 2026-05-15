//
//  ReminderEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import AppKit
import Observation
import RxSwift

@Observation.Observable
class ReminderEditorViewModel: HostingWindowControllerDelegate {

    var isCloseConfirmationVisible = false
    var isErrorVisible = false

    private(set) var reminderCalendarSections: [CalendarSection] = []
    private(set) var eventCalendarSections: [CalendarSection] = []

    private(set) var error: UnexpectedError? {
        didSet {
            if error != nil {
                isErrorVisible = true
            }
        }
    }

    /// Initial values passed to ReminderDialog
    let initialDate: Date
    let initialKind: ReminderKind

    private let calendarService: CalendarServiceProviding
    private let disposeBag = DisposeBag()

    init(dueDate: DueDate, calendarService: CalendarServiceProviding, kind: ReminderKind = .reminder) {
        self.initialDate = dueDate.date
        self.initialKind = kind
        self.calendarService = calendarService
        loadCalendars()
    }

    var onCloseConfirmed: (() -> Void)?

    func confirmClose() {
        isCloseConfirmationVisible = false
        onCloseConfirmed?()
    }

    func dismissError() {
        isErrorVisible = false
        error = nil
    }

    func save(result: ReminderDialogResult) {
        let notes = result.notes.isEmpty ? nil : result.notes

        switch result.kind {
        case .reminder:
            calendarService.createReminder(
                title: result.title,
                calendar: result.calendarID,
                date: result.startDate,
                isAllDay: result.allDay,
                notes: notes,
                priority: result.priority.ekPriority
            )
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.confirmClose()
            }, onError: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)

        case .event:
            calendarService.createEvent(
                title: result.title,
                notes: notes,
                calendar: result.calendarID,
                startDate: result.startDate,
                endDate: result.endDate,
                isAllDay: result.allDay
            )
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.confirmClose()
            }, onError: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)
        }
    }

    func requestWindowClose() -> Bool {
        // We can't easily check if the dialog has a title without access to its state,
        // so we just close directly. The dialog footer Hủy button calls onCancel which
        // routes here for immediate close.
        return true
    }

    // MARK: - Private

    private func loadCalendars() {

        Single.zip(
            calendarService.calendars(forNew: .reminder),
            calendarService.calendars(forNew: .event)
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] reminders, events in
            self?.reminderCalendarSections = reminders.groupedByAccount()
            self?.eventCalendarSections = events.groupedByAccount()
        }, onFailure: { [weak self] error in
            self?.error = error.unexpected
        })
        .disposed(by: disposeBag)
    }
}
