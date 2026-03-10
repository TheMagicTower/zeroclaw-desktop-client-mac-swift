# macOS Notifications Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱이 백그라운드일 때 응답 완료 시 "[서버 이름] — 응답 완료: [첫 30자...]" 알림을 표시하고, 클릭 시 창 모드(이미 열린 경우 포커스, 아니면 새로 열기).

**Architecture:** `NotificationService`가 UNUserNotificationCenter를 감싸고, `AppModel`이 소유 및 `ChatViewModel`에 주입. `ZeroClawApp`이 SwiftUI `openWindow` 환경 액션을 통해 창 열기 처리.

**Tech Stack:** SwiftUI, UserNotifications framework, Combine, macOS 14+

---

## Chunk 1: NotificationService 생성

### Task 1: NotificationService 파일 생성

**Files:**
- Create: `ZeroClawDesktop/Services/NotificationService.swift`

- [ ] **Step 1: NotificationService 클래스 작성**

```swift
// ZeroClawDesktop/Services/NotificationService.swift
import UserNotifications
import AppKit

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    static let openWindowNotification = Notification.Name("ZeroClawOpenChatWindow")

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { print("[NotificationService] auth error: \(error)") }
        }
    }

    func notifyResponseComplete(serverName: String, content: String) {
        guard !NSApp.isActive else { return }  // 백그라운드일 때만

        let preview = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = preview.isEmpty ? "" : String(preview.prefix(30)) + (preview.count > 30 ? "…" : "")

        let n = UNMutableNotificationContent()
        n.title = "\(serverName) — 응답 완료"
        n.body = body
        n.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: n,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            // 창이 이미 열려 있으면 포커스, 아니면 새로 열기
            if let win = NSApp.windows.first(where: {
                $0.identifier?.rawValue == "chat-window" && $0.isVisible
            }) {
                win.makeKeyAndOrderFront(nil)
            } else {
                NotificationCenter.default.post(name: NotificationService.openWindowNotification, object: nil)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 포그라운드에서는 표시하지 않음 (notifyResponseComplete에서 이미 guard함)
        completionHandler([])
    }
}
```

- [ ] **Step 2: AppModel에 NotificationService 추가**

`ZeroClawDesktop/App/AppModel.swift` 수정:

```swift
import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsViewModel
    let chat: ChatViewModel
    let status: StatusViewModel
    let notifications: NotificationService  // 추가

    private var cancellables = Set<AnyCancellable>()

    init() {
        let s = SettingsViewModel()
        let ns = NotificationService()          // 추가
        let c = ChatViewModel(settings: s, notificationService: ns)  // 주입
        let st = StatusViewModel(settings: s)
        settings = s
        chat = c
        status = st
        notifications = ns                      // 추가
        ns.requestAuthorization()               // 추가: 권한 요청
        st.start()
        if s.isPaired { c.connect() }

        s.connectionChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.chat.disconnect()
                    self.status.stop()
                    self.status.start()
                    if self.settings.isPaired { self.chat.connect() }
                    await self.status.refresh()
                }
            }
            .store(in: &cancellables)
    }
}
```

- [ ] **Step 3: ChatViewModel에 notificationService 주입**

`ZeroClawDesktop/ViewModels/ChatViewModel.swift`의 init 시그니처와 stored property 수정:

```swift
// stored property 추가
private let notificationService: NotificationService

// init 수정
init(settings: SettingsViewModel, notificationService: NotificationService) {
    self.settings = settings
    self.notificationService = notificationService
    // ... 기존 코드 유지
}
```

- [ ] **Step 4: handle(.done)에서 알림 전송**

`handle(_ msg: WebSocketMessage)`의 `.done` 케이스 끝부분(isSending = false 바로 위)에 추가:

```swift
case .done(let full):
    let (cleanText, toolCalls) = parseToolCallXML(from: full)
    // ... 기존 버블 처리 코드 유지 ...

    // 알림 전송 (추가)
    let serverName = settings.activeProfile?.name ?? "ZeroClaw"
    notificationService.notifyResponseComplete(serverName: serverName, content: cleanText)

    isSending = false
    sendContinuation?.resume(); sendContinuation = nil
```

- [ ] **Step 5: ZeroClawApp에서 openWindow 연동**

`ZeroClawDesktop/App/ZeroClawApp.swift` 수정:

```swift
import SwiftUI

@main
struct ZeroClawApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(model.settings)
                .environmentObject(model.chat)
                .environmentObject(model.status)
        } label: {
            Image(systemName: "pawprint.fill")
        }
        .menuBarExtraStyle(.window)

        Window("ZeroClaw", id: "chat-window") {
            ChatWindowView()
                .environmentObject(model.settings)
                .environmentObject(model.chat)
                .environmentObject(model.status)
                .onReceive(NotificationCenter.default.publisher(
                    for: NotificationService.openWindowNotification
                )) { _ in
                    openWindow(id: "chat-window")
                }
        }
        .defaultSize(width: 700, height: 600)
        .defaultPosition(.center)
    }
}
```

- [ ] **Step 6: project.yml에 NotificationService.swift 등록 확인 후 xcodegen**

```bash
cd /Users/caspar/Projects/TheMagicTower/zeroclaw-desktop-client-mac-swift
grep -r "NotificationService" project.yml || echo "xcodegen auto-discovers"
xcodegen generate
```

- [ ] **Step 7: 빌드**

```bash
xcodebuild -scheme ZeroClawDesktop -configuration Debug build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 설치 및 수동 테스트**

```bash
cp -R "/Users/caspar/Library/Developer/Xcode/DerivedData/ZeroClawDesktop-dyzevogcihgqnkfwedduolznxzyw/Build/Products/Debug/ZeroClawDesktop.app" "/Applications/ZeroClawDesktop.app"
pkill -x ZeroClawDesktop; sleep 0.5; open "/Applications/ZeroClawDesktop.app"
```

테스트:
1. 앱 실행 → 알림 권한 팝업 승인
2. 메시지 전송 → 다른 앱으로 전환 (Cmd+Tab)
3. 응답 완료 시 알림 확인
4. 알림 클릭 → 창 모드 열리는지 확인

- [ ] **Step 9: 커밋**

```bash
git add ZeroClawDesktop/Services/NotificationService.swift \
        ZeroClawDesktop/App/AppModel.swift \
        ZeroClawDesktop/App/ZeroClawApp.swift \
        ZeroClawDesktop/ViewModels/ChatViewModel.swift
git commit -m "feat: macOS notifications for background response completion"
```
