import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var chat: ChatViewModel
    @EnvironmentObject var status: StatusViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var tab: Tab = .chat

    enum Tab: String, CaseIterable {
        case chat    = "Chat"
        case events  = "Events"
        case status  = "Status"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .chat:     return "bubble.left.and.bubble.right"
            case .events:   return "bolt.fill"
            case .status:   return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabPicker
            Divider()
            content
        }
        .frame(width: 420, height: 600)
        .background(.background)
    }

    @Environment(\.openWindow) private var openWindow

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(.purple)
                .font(.title3)
            Text("ZeroClaw")
                .font(.headline)

            Button {
                openWindow(id: "chat-window")
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open in window")

            Spacer()

            // Profile switcher
            if settings.profiles.count > 0 {
                Menu {
                    ForEach(settings.profiles) { profile in
                        Button {
                            settings.setActive(profile)
                        } label: {
                            if settings.activeProfileID == profile.id {
                                Label(profile.name, systemImage: "checkmark")
                            } else {
                                Text(profile.name)
                            }
                        }
                    }
                    Divider()
                    Button("Manage Servers") { tab = .settings }
                } label: {
                    HStack(spacing: 3) {
                        Text(settings.activeProfile?.name ?? "No Server")
                            .font(.caption)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .menuStyle(.button)
                .menuIndicator(.hidden)
            }

            // Online indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(status.isOnline ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(status.isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    tab = t
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 12))
                        Text(t.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(tab == t ? Color.accentColor.opacity(0.12) : Color.clear)
                    .foregroundStyle(tab == t ? Color.accentColor : Color.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .chat:     ChatView()
        case .events:   EventsView()
        case .status:   StatusView()
        case .settings: SettingsView()
        }
    }
}
