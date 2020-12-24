//
//  AboutViewController.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Cocoa
import RxSwift

class AboutViewController: NSViewController, SettingsUI {

    private let quitButton: NSButton
    private let linkView: NSTextView
    private let autoUpdater: AutoUpdater

    private let disposeBag = DisposeBag()

    init(autoUpdater: AutoUpdater) {
        self.autoUpdater = autoUpdater

        quitButton = NSButton(title: Strings.quit, target: NSApp, action: #selector(NSApp.terminate))
        quitButton.refusesFirstResponder = true

        linkView = NSTextView()
        linkView.string = "https://github.com/pakerwreah"
        linkView.backgroundColor = .clear
        linkView.linkTextAttributes?[.underlineColor] = NSColor.clear
        linkView.isAutomaticLinkDetectionEnabled = true
        linkView.checkTextInDocument(nil)
        linkView.isEditable = false
        linkView.alignment = .center
        linkView.height(equalTo: 15)

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()
        setUpBindings()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        let stackView = NSStackView(views: [
            Label(text: "CalX", font: .systemFont(ofSize: 16, weight: .semibold), align: .center),
            .spacer(height: 0),
            Label(text: BuildConfig.appVersion, font: .systemFont(ofSize: 13), align: .center),
            Label(text: "\(BuildConfig.date) - \(BuildConfig.time)", color: .secondaryLabelColor, align: .center),
            .spacer(height: 4),
            Label(text: #"¯\_(ツ)_/¯"#, font: .systemFont(ofSize: 16), align: .center),
            .spacer(height: 4),
            Label(text: "© 2020 - \(BuildConfig.date.suffix(4)) Carlos Enumo", align: .center),
            linkView,
            .spacer(height: 2),
            quitButton
        ])
        .with(insets: .init(bottom: 8))
        .with(orientation: .vertical)

        view.addSubview(stackView)

        stackView.edges(equalTo: view)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.About.view)

        quitButton.setAccessibilityElement(true)
        quitButton.setAccessibilityRole(.button)
        quitButton.setAccessibilityIdentifier(Accessibility.Settings.About.quitBtn)
    }

    private func setUpBindings() {

        autoUpdater.error.observe(on: MainScheduler.instance).bind { error in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.icon = NSImage(named: NSImage.cautionName)
            alert.messageText = error.title
            alert.informativeText = error.message
            alert.runModal()
        }
        .disposed(by: disposeBag)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
