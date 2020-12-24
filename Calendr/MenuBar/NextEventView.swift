//
//  EventStatusItemView.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import Cocoa
import RxSwift

class NextEventView: NSView {

    private let disposeBag = DisposeBag()

    private let updateSubject = PublishSubject<Void>()
    let viewUpdated: Observable<Void>

    private let viewModel: NextEventViewModel

    private let glassPill = NSGlassEffectView()
    private let colorBar = NSView()
    private let nextEventTitle: Label
    private let nextEventTime: Label

    init(viewModel: NextEventViewModel) {

        self.viewModel = viewModel

        viewUpdated = updateSubject
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .share()
            .startWith(())

        let scaling = viewModel.textScaling.track(with: updateSubject)

        let font = NSFont.systemFont(ofSize: 10)
        nextEventTitle = Label(font: font, scaling: scaling)
        nextEventTime = Label(font: font, scaling: scaling)

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        wantsLayer = true
        height(equalTo: Constants.height)

        // Liquid Glass pill background for the menu bar item
        glassPill.cornerRadius = Constants.height / 2
        glassPill.style = .regular
        addSubview(glassPill)
        glassPill.edges(equalTo: self)

        let stackView = NSStackView().with(spacing: 5)

        [.dummy, colorBar, nextEventTitle, nextEventTime, .dummy].forEach(stackView.addArrangedSubview)

        colorBar.wantsLayer = true
        colorBar.layer?.cornerRadius = 2
        colorBar.width(equalTo: 3)
        colorBar.height(equalTo: Constants.height - 6)

        nextEventTitle.textColor = .headerTextColor
        nextEventTitle.lineBreakMode = .byTruncatingTail
        nextEventTitle.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextEventTitle.setContentHuggingPriority(.required, for: .horizontal)

        nextEventTime.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        nextEventTime.textColor = .headerTextColor
        nextEventTime.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextEventTime.setContentHuggingPriority(.required, for: .horizontal)

        forAutoLayout()

        setContentHuggingPriority(.required, for: .horizontal)
        stackView.setContentHuggingPriority(.required, for: .horizontal)
        stackView.setHuggingPriority(.required, for: .horizontal)

        addSubview(stackView)

        stackView.edges(equalTo: self)
    }

    private func setUpBindings() {

        Observable.combineLatest(
            viewModel.barStyle,
            viewModel.barColor.map(\.cgColor)
        )
        .track(with: updateSubject)
        .bind(to: colorBar.layer!.rx.eventBarStyle)
        .disposed(by: disposeBag)

        viewModel.backgroundColor
            .track(with: updateSubject)
            .bind { [glassPill] color in
                // Tint the glass pill with the event color for a subtle branded look
                glassPill.tintColor = color.withAlphaComponent(0.4)
            }
            .disposed(by: disposeBag)

        viewModel.isPending
            .track(with: updateSubject)
            .wait(for: rx.updateLayer)
            .bind { [glassPill] isPending in
                glassPill.style = isPending ? .clear : .regular
            }
            .disposed(by: disposeBag)

        viewModel.title
            .track(with: updateSubject)
            .bind(to: nextEventTitle.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.time
            .track(with: updateSubject)
            .bind(to: nextEventTime.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.hasEvent
            .map(!)
            .track(with: updateSubject)
            .bind(to: rx.isHidden)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ObservableType {

    func track<T: ObserverType>(with observer: T) -> Observable<Element> where T.Element == Void {

        self.do(afterNext: { _ in
            observer.onNext(())
        })
    }

    func wait<T: ObservableType>(for observable: T) -> Observable<Element> where T.Element == Void {

        self.flatMapLatest(observable.map)
    }
}

private extension Reactive where Base: CALayer {

    var eventBarStyle: Binder<(EventBarStyle, CGColor)> {

        Binder(self.base) { layer, values in
            let (style, color) = values

            switch style {
            case .filled:
                layer.borderWidth = 0
                layer.borderColor = nil
                layer.backgroundColor = color

            case .bordered:
                layer.borderWidth = 1
                layer.borderColor = color
                layer.backgroundColor = nil
            }
        }
    }
}

private enum Constants {

    static let height: CGFloat = 22
}
