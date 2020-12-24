//
//  MockEventSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockEventSettings: MockAppearanceSettings, EventSettings {

    let showRecurrenceIndicator: Observable<Bool>
    let forceLocalTimeZone: Observable<Bool>
    let showMap: Observable<Bool>
    let showAllDayDetails: Observable<Bool>
    let eventTitleLines: Observable<Int>

    init(
        showRecurrenceIndicator: Bool = true,
        forceLocalTimeZone: Bool = false,
        showMap: Bool = false,
        showAllDayDetails: Bool = true,
        eventTitleLines: Int = 2
    ) {
        self.showRecurrenceIndicator = .just(showRecurrenceIndicator)
        self.forceLocalTimeZone = .just(forceLocalTimeZone)
        self.showMap = .just(showMap)
        self.showAllDayDetails = .just(showAllDayDetails)
        self.eventTitleLines = .just(eventTitleLines)
    }
}

#endif
