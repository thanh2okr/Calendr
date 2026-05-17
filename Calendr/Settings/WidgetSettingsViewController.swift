//
//  WidgetSettingsViewController.swift
//  Calendr
//

import Cocoa
import RxSwift
import WidgetKit

/// Main app ghi vào UserDefaults.standard (br.paker.CalX.plist),
/// widget đọc lại qua suiteName "br.paker.CalX" — cùng file trên macOS
let CalXWidgetFrequencyKey = "widget_quote_frequency"

class WidgetSettingsViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    // MARK: - UI

    private let frequencyLabel = Label(text: "Tần suất đổi quote")
    private let frequencyDropdown = Dropdown()

    private let frequencies: [(title: String, value: String)] = [
        ("Mỗi ngày",  "daily"),
        ("Mỗi 6 giờ", "every6h"),
        ("Mỗi 3 giờ", "every3h"),
    ]

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func loadView() {
        // Tạo row: label + dropdown
        frequencyDropdown.addItems(withTitles: frequencies.map(\.title))
        frequencyDropdown.target = self
        frequencyDropdown.action = #selector(frequencyChanged)
        loadCurrentValue()

        let row = NSStackView(views: [frequencyLabel, frequencyDropdown])
            .with(orientation: .horizontal)
            .with(spacing: 8)

        let (sectionView, sectionDisposable) = makeSection(title: "Quotes Widget", content: row).unwrap()
        sectionDisposable.disposed(by: disposeBag)

        let stack = NSStackView(views: [sectionView])
            .with(orientation: .vertical)
            .with(spacing: 0)
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        view = stack
    }

    // MARK: - Logic

    private func loadCurrentValue() {
        let saved = UserDefaults.standard.string(forKey: CalXWidgetFrequencyKey) ?? "daily"
        let idx = frequencies.firstIndex(where: { $0.value == saved }) ?? 0
        frequencyDropdown.selectItem(at: idx)
    }

    @objc private func frequencyChanged() {
        let selected = frequencies[frequencyDropdown.indexOfSelectedItem]
        UserDefaults.standard.set(selected.value, forKey: CalXWidgetFrequencyKey)
        UserDefaults.standard.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
