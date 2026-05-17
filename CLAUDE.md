# CalX — Project Memory

## Tổng quan
Fork của [Calendr](https://github.com/pakerwreah/Calendr) — macOS menu bar calendar app.
Target: macOS 26 (Liquid Glass). Bundle ID: `br.paker.CalX`.

## Build
```bash
xcodebuild -scheme CalX -configuration Debug build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Deploy
DERIVED_DATA=~/Library/Developer/Xcode/DerivedData/Calendr-bppsixpgyylfhieddzefoitcqxpo
pkill -x "CalX" 2>/dev/null; pkill -x "Calendr" 2>/dev/null; sleep 1
rm -rf /Applications/CalX.app
cp -R "$DERIVED_DATA/Build/Products/Debug/CalX.app" /Applications/CalX.app

# Sign widget extension (required for pluginkit to register it)
cat > /tmp/widget.entitlements << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.app-sandbox</key><true/></dict></plist>
PLIST
codesign --force --sign "Apple Development: openthanh@gmail.com (5J9DN62KXP)" \
  --entitlements /tmp/widget.entitlements \
  /Applications/CalX.app/Contents/PlugIns/CalXExtension.appex
codesign --force --sign "Apple Development: openthanh@gmail.com (5J9DN62KXP)" \
  /Applications/CalX.app
pluginkit -e use -i br.paker.CalX.CalXExtension

open /Applications/CalX.app
```
DerivedData: `~/Library/Developer/Xcode/DerivedData/Calendr-bppsixpgyylfhieddzefoitcqxpo`

## Kiến trúc quan trọng

### Pattern hosting SwiftUI vào NSWindow
- `HostingWindowController<RootView>` — `NSHostingController` + `NSWindowDelegate`
- `windowConfiguration: ((NSWindow) -> Void)?` — callback sau first layout để config window
- Dùng `presentAsModalWindow()` từ `MainViewController`

### macOS 26 floating glass dialog
```swift
viewController.windowConfiguration = { window in
    window.styleMask = [.fullSizeContentView]  // KHÔNG dùng .titled — sẽ hiện traffic lights
    window.backgroundColor = .clear
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.standardWindowButton(.closeButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
}
```

### CalendarServiceProviding protocol
Đã thêm (so với upstream):
```swift
func createReminder(title:calendar:date:isAllDay:notes:priority:) -> Completable
func createEvent(title:notes:calendar:startDate:endDate:isAllDay:) -> Completable
func calendars(forNew type: CalendarEntityType) -> Single<[CalendarModel]>
func defaultCalendar(forNew type: CalendarEntityType) -> CalendarModel?
```

## Files đã thay đổi (so với upstream)

### Calendr/Editors/
- **`ReminderDialog.swift`** ← FILE MỚI (toàn bộ create dialog)
  - `ReminderKind` (reminder/event), `ReminderPriority`, `DialogCalendarItem`, `ReminderDialogResult`
  - DatePicker dùng `.field` style (không dùng `.compact` — sẽ mở inline calendar)
  - Dialog kích thước 420×460, background `.regularMaterial`, rounded corners 16pt
  - Notes/description có trong dialog và được gửi đến Apple apps khi save
- **`ReminderEditorViewModel.swift`** ← Rewritten
  - Load cả reminder + event calendars qua `Single.zip`
  - `save(result: ReminderDialogResult)` dispatch đến createReminder hoặc createEvent
  - `requestWindowClose()` luôn trả về `true`
- **`ReminderEditorViewController.swift`** ← Rewritten
  - Chỉ host `ReminderDialog` SwiftUI view
  - Alert lỗi qua `$viewModel.isErrorVisible`

### Calendr/Main/
- **`MainViewController.swift`**
  - Nút `+` mở thẳng `openReminderEditor()` (không qua menu)
  - Không còn `openCalendarForNewEvent()` hay menu Apple Reminders/Calendar

### Calendr/Components/
- **`HostingWindowController.swift`**
  - Thêm `var windowConfiguration: ((NSWindow) -> Void)?`
  - Gọi trong `windowDidResize` (first layout) sau `window.center()`

### Calendr/Events/EventList/
- **`EventViewModel.swift`**
  - **Xóa** notes fallback subtitle — description không hiển thị trong event list chính
  - Chỉ giữ location và meeting link làm subtitle

### Calendr/Providers/
- **`CalendarServiceProvider.swift`**
  - `createReminder` thêm `notes` và `priority` params → set vào EKReminder
  - `createEvent` mới dùng EKEvent

### Calendr/Mocks/
- **`MockCalendarServiceProvider.swift`** — cập nhật signatures mới

## Design decisions

| Quyết định | Lý do |
|---|---|
| Notes KHÔNG hiển thị ở event list | User yêu cầu — chỉ gửi đến Apple apps |
| Notes CÓ trong create dialog | User yêu cầu — để nhập và gửi đến Reminders/Calendar |
| DatePicker `.field` thay `.compact` | `.compact` mở inline calendar, chiếm không gian |
| `styleMask = [.fullSizeContentView]` | Loại bỏ traffic lights; `.titled` luôn hiện chúng |
| X button tự render trong dialog | Không dùng system close button |

## Gotchas / Lỗi thường gặp

- **Label conflict**: Project có `class Label: NSTextField`, trong SwiftUI dùng `SwiftUI.Label { } icon: { }`
- **Async calendar loading**: Calendar IDs rỗng khi dialog mở → dùng `.onChange(of: reminderCalendars)` để set
- **Stale build**: Nếu không thấy thay đổi → `xcodebuild clean build` rồi xóa app cũ
- **Traffic lights vẫn hiện**: Phải dùng `styleMask = [.fullSizeContentView]` (không insert vào mask cũ)
- **PBXFileSystemSynchronizedRootGroup**: File drop vào `Calendr/Editors/` tự sync, không cần sửa `.pbxproj`

## Tests
`CalendrTests/ReminderEditorViewModelTests.swift` — cover save reminder/event, error handling, calendar loading
