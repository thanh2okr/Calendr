//
//  MockEventListSettings.swift
//  CalendrTests
//
//  Created by Paker on 13/03/2021.
//

import RxSwift
@testable import Calendr

class MockEventListSettings: MockEventSettings, EventListSettings {

    let togglePastEvents: AnyObserver<Bool>
    let showPastEvents: Observable<Bool>

    let toggleOverdueReminders: AnyObserver<Bool>
    let showOverdueReminders: Observable<Bool>

    let toggleEventListSummary: AnyObserver<Bool>
    let showEventListSummary: Observable<Bool>

    let toggleShowVideoCallOnly: AnyObserver<Bool>
    let showVideoCallOnly: Observable<Bool>

    override init() {
        (showPastEvents, togglePastEvents) = BehaviorSubject.pipe(value: true)
        (showOverdueReminders, toggleOverdueReminders) = BehaviorSubject.pipe(value: true)
        (showEventListSummary, toggleEventListSummary) = BehaviorSubject.pipe(value: true)
        (showVideoCallOnly, toggleShowVideoCallOnly) = BehaviorSubject.pipe(value: false)
    }
}
