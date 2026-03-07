import SwiftUI

struct EventsView: View {
    @EnvironmentObject var vm: StatusViewModel

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            eventList
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Live Events")
                .font(.subheadline.bold())
            Spacer()
            if !vm.events.isEmpty {
                Text("\(vm.events.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button {
                vm.clearEvents()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear events")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var eventList: some View {
        if vm.events.isEmpty {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "bolt.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Waiting for events...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List(vm.events) { event in
                EventRow(event: event)
                    .listRowSeparator(.visible)
                    .listRowInsets(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            }
            .listStyle(.plain)
        }
    }
}

struct EventRow: View {
    let event: SSEEvent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: event.iconName)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 14)

            Text(event.description)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(event.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .llmRequest:              return .blue
        case .toolCall, .toolCallStart: return .orange
        case .agentStart:              return .green
        case .agentEnd:                return .purple
        case .error:                   return .red
        case .unknown:                 return .secondary
        }
    }
}
