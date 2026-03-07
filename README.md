# ZeroClaw Desktop — macOS Client

A native macOS menu bar client for [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), built with SwiftUI.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

---

## Features

- **Menu bar app** — lives in the system menu bar, always one click away
- **Window mode** — expandable full window for complex, long-running conversations
- **Real-time streaming** via WebSocket (`/ws/chat`)
- **Markdown rendering** — headers, lists, blockquotes, tables, fenced code blocks, Mermaid diagrams
- **Image support** — paste, drag & drop, or attach images to messages
- **Tool call display** — collapsible tool call / result bubbles
- **Multi-server profiles** — manage multiple ZeroClaw server connections
- **Per-profile submit mode** — `Cmd+Return` or `Return` to send, toggle with `⌘⇧↩`
- **Input history** — `Shift+↑/↓` to navigate previously sent messages
- **Persistent chat history** — per-profile, survives restarts
- **Korean/CJK IME support** — correct composition handling in NSTextView
- **Keychain token storage** — no repeated auth prompts

## Requirements

- macOS 14.0 (Sonoma) or later
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) running locally or remotely
- [Xcode](https://developer.apple.com/xcode/) 15+ for building
- [xcodegen](https://github.com/yonaskolb/XcodeGen) for project file generation

## Build & Run

```bash
# 1. Clone
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift

# 2. Generate Xcode project
brew install xcodegen   # if not already installed
xcodegen generate

# 3. Build
xcodebuild -scheme ZeroClawDesktop -configuration Debug build

# 4. Run
open build/ZeroClawDesktop.app
```

Or open `ZeroClawDesktop.xcodeproj` in Xcode and press `⌘R`.

> **Signing**: The project uses ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`), so no Apple Developer account is required.

## Setup

1. Launch the app — a paw print icon appears in the menu bar
2. Click it and open **Settings**
3. Add your ZeroClaw server endpoint (e.g. `http://localhost:7300`)
4. Enter the pairing code shown by the ZeroClaw daemon and click **Pair**
5. Start chatting

## Architecture

```
ZeroClawDesktop/
├── App/
│   ├── ZeroClawApp.swift          # App entry, MenuBarExtra + Window scenes
│   └── AppModel.swift             # Root ViewModel owner
├── Models/
│   ├── ChatMessage.swift          # Message model (Codable)
│   ├── ConnectionProfile.swift    # Server profile + SubmitMode
│   └── ServerModels.swift         # Health/status API models
├── ViewModels/
│   ├── ChatViewModel.swift        # Chat state, WS handling, persistence
│   ├── SettingsViewModel.swift    # Profiles, pairing, Keychain
│   └── StatusViewModel.swift      # Server health polling
├── Views/
│   ├── MenuBarView.swift          # Popup panel (tabs: Chat, Status, Settings)
│   ├── ChatView.swift             # Compact chat (popup)
│   ├── ChatWindowView.swift       # Full window chat
│   ├── ChatInputBar.swift         # Shared input bar
│   ├── MultilineTextInput.swift   # NSTextView wrapper (IME, history, paste)
│   ├── MarkdownMessageView.swift  # Block-level markdown renderer
│   ├── MermaidView.swift          # Mermaid diagram (WKWebView)
│   ├── SettingsView.swift         # Settings panel
│   └── StatusView.swift           # Server status panel
└── Services/
    ├── WebSocketService.swift     # WebSocket client (/ws/chat)
    ├── ZeroClawClient.swift       # REST client (pairing, health)
    └── KeychainService.swift      # Secure token storage
```

## ZeroClaw Protocol

Connects to the ZeroClaw daemon via WebSocket at `/ws/chat?token=<bearer>`.

**Send:**
```json
{ "type": "message", "content": "Hello!" }
```

**Receive:**
| Type | Payload | Description |
|------|---------|-------------|
| `chunk` | `text` | Streaming token |
| `done` | `full_response` | Final complete response |
| `tool_call` | `name` | Tool invocation started |
| `tool_result` | `name`, `output` | Tool result |
| `error` | `message` | Error from daemon |

## License

MIT
