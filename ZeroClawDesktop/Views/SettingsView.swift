import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: SettingsViewModel
    @EnvironmentObject var status: StatusViewModel

    @State private var showAddSheet = false

    var body: some View {
        Form {
            serversSection
            if vm.activeProfile != nil {
                activeProfileSection
            }
            aboutSection
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showAddSheet) {
            AddServerSheet { name, endpoint in
                vm.addProfile(name: name, endpointURL: endpoint)
            }
        }
    }

    // MARK: - Sections

    private var serversSection: some View {
        Section {
            ForEach(vm.profiles) { profile in
                ProfileRow(
                    profile: profile,
                    isActive: vm.activeProfileID == profile.id,
                    isPaired: KeychainService.shared.loadToken(for: profile.id) != nil
                ) {
                    vm.setActive(profile)
                }
            }
            .onDelete { indices in
                indices.map { vm.profiles[$0] }.forEach { vm.deleteProfile($0) }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Add Server", systemImage: "plus.circle")
            }
        } header: {
            Text("Servers")
        }
    }

    private var activeProfileSection: some View {
        Section {
            // Name
            LabeledContent("Name") {
                TextField("Server name", text: Binding(
                    get: { vm.activeProfile?.name ?? "" },
                    set: { vm.updateActiveName($0) }
                ))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
            }

            // Endpoint
            VStack(alignment: .leading, spacing: 4) {
                TextField("Endpoint", text: Binding(
                    get: { vm.activeProfile?.endpointURL ?? "" },
                    set: { vm.updateActiveEndpoint($0) }
                ))
                .textFieldStyle(.roundedBorder)
            }

            // Submit mode
            Picker("전송 단축키", selection: Binding(
                get: { vm.activeProfile?.submitMode ?? .cmdEnter },
                set: { vm.updateActiveSubmitMode($0) }
            )) {
                ForEach(SubmitMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Auth
            if vm.isPaired {
                pairedRow
            } else {
                unpairRow
            }
        } header: {
            Text(vm.activeProfile?.name ?? "Active Server")
        }
    }

    private var pairedRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Paired", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Spacer()
                Button("Unpair") {
                    vm.unpair()
                }
                .foregroundStyle(.red)
                .buttonStyle(.plain)
            }
            if let token = vm.token {
                HStack {
                    Text("Token")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(token.prefix(8)) + "••••••••")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }

    private var unpairRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pairing Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Code shown by ZeroClaw daemon", text: $vm.pairingCode)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await vm.pair() } }
            }

            if let err = vm.pairingError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button {
                Task { await vm.pair() }
            } label: {
                HStack {
                    if vm.isPairing { ProgressView().controlSize(.mini) }
                    Text(vm.isPairing ? "Pairing..." : "Pair with ZeroClaw")
                }
            }
            .disabled(vm.isPairing || vm.pairingCode.isEmpty)
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "0.1.0")
            LabeledContent("Backend", value: "ZeroClaw daemon")
            LabeledContent("Protocol", value: "REST (webhook)")
        }
    }
}

// MARK: - ProfileRow

struct ProfileRow: View {
    let profile: ConnectionProfile
    let isActive: Bool
    let isPaired: Bool
    let onActivate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status dot
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                Text(profile.displayHost)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if isActive {
                Text("Active")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Button("Select") { onActivate() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if !isActive { onActivate() } }
    }

    private var dotColor: Color {
        if isActive { return isPaired ? .green : .orange }
        return .secondary.opacity(0.4)
    }
}

// MARK: - AddServerSheet

struct AddServerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String) -> Void

    @State private var name = ""
    @State private var endpoint = "http://"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Server")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. Production", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Endpoint").font(.caption).foregroundStyle(.secondary)
                TextField("http://host:port", text: $endpoint)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Add") {
                    onAdd(name.isEmpty ? "New Server" : name, endpoint)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(endpoint.count < 7)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
