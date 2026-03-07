import Foundation
import Combine

@MainActor
final class StatusViewModel: ObservableObject {
    @Published private(set) var statusDisplay: ServerStatusDisplay?
    @Published private(set) var costDisplay: CostDisplay?
    @Published private(set) var events: [SSEEvent] = []
    @Published private(set) var isOnline = false
    @Published private(set) var statusError: String?

    private let settings: SettingsViewModel
    private var sseTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private static let maxEvents = 100
    private static let pollInterval: Duration = .seconds(10)
    private static let sseReconnectDelay: Duration = .seconds(3)

    init(settings: SettingsViewModel) {
        self.settings = settings
    }

    func start() {
        startPolling()
    }

    func stop() {
        pollTask?.cancel()
        sseTask?.cancel()
        pollTask = nil
        sseTask = nil
    }

    func refresh() async {
        guard let client = settings.makeClient() else { return }
        do {
            // Try /api/status first; fall back to /health if HTTP error (endpoint not found etc.)
            let statusData: [String: Any]
            do {
                statusData = try await client.status()
            } catch ZeroClawError.serverError {
                // Server is reachable but endpoint missing — try /health
                statusData = (try? await client.health()) ?? [:]
            }
            async let costData = client.cost()
            let cost = (try? await costData) ?? [:]
            statusDisplay = ServerStatusDisplay(json: statusData)
            costDisplay = cost.isEmpty ? nil : CostDisplay(json: cost)
            isOnline = true
            statusError = nil
        } catch {
            isOnline = false
            statusError = error.localizedDescription
        }
    }

    func clearEvents() {
        events.removeAll()
    }

    // MARK: - Private

    private func startPolling() {
        pollTask?.cancel()
        // detached: polling loop runs on cooperative thread pool, not main actor.
        // refresh() hops back to @MainActor for UI updates.
        pollTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: StatusViewModel.pollInterval)
            }
        }
    }

    private func startSSE() {
        sseTask?.cancel()
        sseTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                guard let client = await self.settings.makeClient() else {
                    try? await Task.sleep(for: StatusViewModel.sseReconnectDelay)
                    continue
                }
                do {
                    for try await event in client.eventStream() {
                        if Task.isCancelled { break }
                        await MainActor.run {
                            self.events.insert(event, at: 0)
                            if self.events.count > StatusViewModel.maxEvents {
                                self.events = Array(self.events.prefix(StatusViewModel.maxEvents))
                            }
                        }
                    }
                } catch {
                    // Connection closed or error — will reconnect after delay
                }
                if !Task.isCancelled {
                    try? await Task.sleep(for: StatusViewModel.sseReconnectDelay)
                }
            }
        }
    }
}
