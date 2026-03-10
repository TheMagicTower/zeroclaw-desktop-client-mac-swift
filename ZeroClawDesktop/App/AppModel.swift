import Foundation
import Combine

/// Root model that owns all child ViewModels.
@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsViewModel
    let chat: ChatViewModel
    let status: StatusViewModel
    let notifications: NotificationService

    private var cancellables = Set<AnyCancellable>()

    init() {
        let s = SettingsViewModel()
        let ns = NotificationService()
        let c = ChatViewModel(settings: s, notificationService: ns)
        let st = StatusViewModel(settings: s)
        settings = s
        chat = c
        status = st
        notifications = ns
        ns.requestAuthorization()
        st.start()
        if s.isPaired { c.connect() }

        // Reconnect when active profile or pairing state changes
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
