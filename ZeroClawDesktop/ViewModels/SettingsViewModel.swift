import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published

    @Published var profiles: [ConnectionProfile] = [] {
        didSet { saveProfiles() }
    }
    @Published var activeProfileID: UUID? {
        didSet {
            guard oldValue != activeProfileID else { return }
            UserDefaults.standard.set(activeProfileID?.uuidString, forKey: "active_profile_id")
            updateDerivedState()
            connectionChanged.send()
        }
    }

    // Derived from active profile — kept as @Published for SwiftUI bindings
    @Published private(set) var isPaired = false
    @Published private(set) var token: String?

    // Pairing UI state
    @Published var pairingCode: String = ""
    @Published private(set) var pairingError: String?
    @Published private(set) var isPairing = false

    /// Fires when the active profile changes or pairing state changes.
    /// AppModel observes this to reconnect everything.
    let connectionChanged = PassthroughSubject<Void, Never>()

    // MARK: - Computed

    var activeProfile: ConnectionProfile? {
        profiles.first { $0.id == activeProfileID }
    }

    var baseURL: URL? { activeProfile?.baseURL }

    func makeClient() -> ZeroClawClient? {
        guard let url = baseURL else { return nil }
        return ZeroClawClient(baseURL: url, token: token)
    }

    // MARK: - Init

    init() {
        loadProfiles()
        loadActiveProfileID()
        updateDerivedState()
    }

    // MARK: - Profile management

    func addProfile(name: String, endpointURL: String) {
        let p = ConnectionProfile(name: name, endpointURL: endpointURL)
        profiles.append(p)
        if profiles.count == 1 {
            activeProfileID = p.id
        }
    }

    func deleteProfile(_ profile: ConnectionProfile) {
        KeychainService.shared.deleteToken(for: profile.id)
        profiles.removeAll { $0.id == profile.id }
        if activeProfileID == profile.id {
            activeProfileID = profiles.first?.id
        }
    }

    func setActive(_ profile: ConnectionProfile) {
        activeProfileID = profile.id
    }

    /// Update the active profile's endpoint URL in-place.
    func updateActiveEndpoint(_ url: String) {
        guard let id = activeProfileID,
              let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].endpointURL = url
    }

    /// Update the active profile's name in-place.
    func updateActiveName(_ name: String) {
        guard let id = activeProfileID,
              let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].name = name
    }

    /// Update the active profile's submit mode in-place.
    func updateActiveSubmitMode(_ mode: SubmitMode) {
        guard let id = activeProfileID,
              let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].submitMode = mode
    }

    // MARK: - Pairing

    func pair() async {
        guard let client = makeClient() else {
            pairingError = "Invalid URL"
            return
        }
        pairingError = nil
        isPairing = true
        defer { isPairing = false }

        do {
            let t = try await client.pair(code: pairingCode)
            if let id = activeProfileID {
                KeychainService.shared.saveToken(t, for: id)
            }
            pairingCode = ""
            updateDerivedState()
            connectionChanged.send()
        } catch {
            pairingError = error.localizedDescription
        }
    }

    func unpair() {
        if let id = activeProfileID {
            KeychainService.shared.deleteToken(for: id)
        }
        updateDerivedState()
        connectionChanged.send()
    }

    // MARK: - Persistence

    private func updateDerivedState() {
        if let id = activeProfileID {
            let t = KeychainService.shared.loadToken(for: id)
            if let t {
                // Re-save with permissive ACL so future launches don't prompt.
                // One-time migration from app-signature-locked ACL to open ACL.
                KeychainService.shared.saveToken(t, for: id)
            }
            token = t
            isPaired = t != nil
        } else {
            token = nil
            isPaired = false
        }
    }

    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: "connection_profiles")
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: "connection_profiles"),
           let decoded = try? JSONDecoder().decode([ConnectionProfile].self, from: data) {
            profiles = decoded
            return
        }
        // First launch: migrate legacy single-connection settings
        let legacyEndpoint = UserDefaults.standard.string(forKey: "endpoint_url")
            ?? "http://localhost:7300"
        let defaultProfile = ConnectionProfile(name: "Default", endpointURL: legacyEndpoint)
        profiles = [defaultProfile]
        // Migrate legacy token
        if let oldToken = KeychainService.shared.loadToken() {
            KeychainService.shared.saveToken(oldToken, for: defaultProfile.id)
            KeychainService.shared.deleteToken()
        }
        saveProfiles()
    }

    private func loadActiveProfileID() {
        if let idStr = UserDefaults.standard.string(forKey: "active_profile_id"),
           let id = UUID(uuidString: idStr),
           profiles.contains(where: { $0.id == id }) {
            activeProfileID = id
        } else {
            activeProfileID = profiles.first?.id
        }
    }
}
