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
                )) { _ in openWindow(id: "chat-window") }
        }
        .defaultSize(width: 700, height: 600)
        .defaultPosition(.center)
    }
}
