//
//  MockEventListSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

class MockEventListSettings: MockEventSettings, EventListSettings {

    let showPastEvents: Observable<Bool>
    let showOverdueReminders: Observable<Bool>
    let showEventListSummary: Observable<Bool>
    let showVideoCallOnly: Observable<Bool>

    init(showPastEvents: Bool = true, showOverdueReminders: Bool = true, showAllDayDetails: Bool = true, showVideoCallOnly: Bool = false) {

        self.showPastEvents = .just(showPastEvents)
        self.showOverdueReminders = .just(showOverdueReminders)
        self.showEventListSummary = .just(true)
        self.showVideoCallOnly = .just(showVideoCallOnly)

        super.init(showAllDayDetails: showAllDayDetails)
    }
}

#endif
