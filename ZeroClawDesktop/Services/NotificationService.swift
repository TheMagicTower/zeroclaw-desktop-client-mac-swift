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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { print("[NotificationService] auth error: \(error)") }
        }
    }

    func notifyResponseComplete(serverName: String, content: String) {
        guard !NSApp.isActive else { return }

        let preview = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = preview.isEmpty ? "" : String(preview.prefix(30)) + (preview.count > 30 ? "…" : "")

        let n = UNMutableNotificationContent()
        n.title = "\(serverName) — 응답 완료"
        n.body = body
        n.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: n, trigger: nil)
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
        completionHandler([])
    }
}
