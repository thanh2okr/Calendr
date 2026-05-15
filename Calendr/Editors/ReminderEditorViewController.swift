//
//  ReminderEditorViewController.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import SwiftUI

typealias ReminderEditorViewController = HostingViewModelController<ReminderEditorView>

struct ReminderEditorView: ViewModelView {
    @State private var viewModel: ReminderEditorViewModel

    init(viewModel: ReminderEditorViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ReminderDialog(
            reminderCalendars: viewModel.reminderCalendarSections.asDialogItems(),
            eventCalendars: viewModel.eventCalendarSections.asDialogItems(),
            onSave: { result in viewModel.save(result: result) },
            onCancel: { viewModel.confirmClose() },
            initialKind: viewModel.initialKind,
            initialDate: viewModel.initialDate
        )
        .alert(isPresented: $viewModel.isErrorVisible, error: viewModel.error) {
            Button("OK", role: .cancel, action: viewModel.dismissError)
                .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    ReminderEditorView(
        viewModel: .init(
            dueDate: .init(date: .now),
            calendarService: MockCalendarServiceProvider(
                calendars: [
                    .make(id: "1", account: "iCloud", title: "Reminders", color: .systemBlue),
                    .make(id: "2", account: "iCloud", title: "Groceries", color: .systemRed),
                    .make(id: "3", account: "Google", title: "Todos", color: .systemYellow),
                ]
            )
        )
    )
}

#endif
