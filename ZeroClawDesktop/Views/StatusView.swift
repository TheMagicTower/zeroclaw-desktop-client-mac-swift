import SwiftUI

struct StatusView: View {
    @EnvironmentObject var vm: StatusViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                connectionCard
                if let s = vm.statusDisplay, !s.fields.isEmpty {
                    kvCard(title: "Server Status", fields: s.fields)
                }
                if let c = vm.costDisplay, !c.fields.isEmpty {
                    kvCard(title: "Cost", fields: c.fields)
                }
                Spacer()
            }
            .padding(12)
        }
        .onAppear { Task { await vm.refresh() } }
    }

    private var connectionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(vm.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(vm.isOnline ? "Connected" : "Disconnected")
                        .font(.subheadline)
                    Spacer()
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                if let err = vm.statusError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } label: {
            Text("Daemon")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func kvCard(title: String, fields: [(key: String, value: String)]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(fields, id: \.key) { field in
                    HStack(alignment: .top) {
                        Text(field.key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 100, alignment: .leading)
                        Spacer()
                        Text(field.value)
                            .font(.system(.caption, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                    }
                    if field.key != fields.last?.key {
                        Divider()
                    }
                }
            }
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
}
