//
//  WeekNumberCellView.swift
//  Calendr
//
//  Created by Paker on 11/02/2021.
//

import Cocoa
import RxSwift

class WeekNumberCellView: NSView {

    private let disposeBag = DisposeBag()

    private let label: Label

    init(weekNumber: Observable<Int>, scaling: Observable<Double>) {

        label = Label(font: .systemFont(ofSize: Constants.fontSize), scaling: scaling)

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        weekNumber
            .map(String.init)
            .observe(on: MainScheduler.instance)
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.Calendar.weekNumber)
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(label)

        label.textColor = .secondaryLabelColor
        // Offset upward to align with date labels (which sit above center due to event dots below)
        label.center(in: self, offset: CGPoint(x: -2, y: 3))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let fontSize: CGFloat = 10
}
