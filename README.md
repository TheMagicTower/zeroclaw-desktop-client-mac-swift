# ZeroClaw Desktop — macOS Client

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

<p align="center">
  <a href="#english">English</a> •
  <a href="#한국어">한국어</a> •
  <a href="#日本語">日本語</a> •
  <a href="#中文简体">中文简体</a> •
  <a href="#中文繁體">中文繁體</a> •
  <a href="#deutsch">Deutsch</a> •
  <a href="#español">Español</a> •
  <a href="#français">Français</a> •
  <a href="#português">Português</a> •
  <a href="#русский">Русский</a> •
  <a href="#العربية">العربية</a> •
  <a href="#हिन्दी">हिन्दी</a>
</p>

---

## English

A native macOS menu bar client for [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), built with SwiftUI.

### Features
- **Menu bar app** — lives in the system menu bar, always one click away
- **Window mode** — expandable full window for complex conversations
- **Real-time streaming** via WebSocket (`/ws/chat`)
- **Markdown rendering** — headers, lists, blockquotes, tables, code blocks, Mermaid diagrams
- **Image support** — paste, drag & drop, or attach images
- **Tool call display** — collapsible tool call / result bubbles
- **Multi-server profiles** — manage multiple ZeroClaw connections
- **Per-profile submit mode** — `Cmd+Return` or `Return` to send, toggle with `⌘⇧↩`
- **Input history** — `Shift+↑/↓` to navigate previously sent messages
- **Persistent chat history** — per-profile, survives app restarts
- **Korean/CJK IME support** — correct composition in NSTextView
- **Keychain token storage** — secure, no repeated auth prompts

### Requirements
- macOS 14.0 (Sonoma) or later
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) running locally or remotely
- Xcode 15+ and [xcodegen](https://github.com/yonaskolb/XcodeGen) for building

### Build & Run
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Setup
1. Launch the app — a paw print icon appears in the menu bar
2. Open **Settings**, add your ZeroClaw server endpoint
3. Enter the pairing code shown by the ZeroClaw daemon and click **Pair**
4. Start chatting

### Architecture
```
ZeroClawDesktop/
├── App/           ZeroClawApp.swift, AppModel.swift
├── Models/        ChatMessage, ConnectionProfile, ServerModels
├── ViewModels/    ChatViewModel, SettingsViewModel, StatusViewModel
├── Views/         MenuBarView, ChatView, ChatWindowView, ChatInputBar,
│                  MultilineTextInput, MarkdownMessageView, MermaidView,
│                  SettingsView, StatusView
└── Services/      WebSocketService, ZeroClawClient, KeychainService
```

---

## 한국어

[ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) 전용 네이티브 macOS 메뉴바 클라이언트입니다. SwiftUI로 제작됐습니다.

### 주요 기능
- **메뉴바 앱** — 시스템 메뉴바에 상주하며 언제든 한 번의 클릭으로 접근 가능
- **창 모드** — 복잡한 대화를 위한 전체 창 모드 지원
- **실시간 스트리밍** — WebSocket(`/ws/chat`) 기반 토큰 스트리밍
- **마크다운 렌더링** — 헤더, 목록, 블록쿼트, 테이블, 코드 블록, Mermaid 다이어그램
- **이미지 지원** — 붙여넣기, 드래그 앤 드롭, 파일 첨부 지원
- **툴 콜 표시** — 접기/펼치기 가능한 툴 콜/결과 버블
- **다중 서버 프로필** — 여러 ZeroClaw 서버 연결 관리
- **전송 모드 설정** — `Cmd+Return` 또는 `Return`으로 전송, `⌘⇧↩`로 전환
- **입력 히스토리** — `Shift+↑/↓`로 이전 전송 메시지 탐색
- **대화 이력 영구 저장** — 프로필별 저장, 앱 재시작 후에도 유지
- **한국어/CJK IME 지원** — NSTextView에서 올바른 조합 처리
- **Keychain 토큰 저장** — 안전한 인증, 반복 인증 팝업 없음

### 요구사항
- macOS 14.0 (Sonoma) 이상
- [ZeroClaw 데몬](https://github.com/zeroclaw-labs/zeroclaw) (로컬 또는 원격)
- Xcode 15+ 및 [xcodegen](https://github.com/yonaskolb/XcodeGen)

### 빌드 및 실행
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### 설정 방법
1. 앱 실행 — 메뉴바에 발바닥 아이콘이 표시됩니다
2. **Settings**를 열고 ZeroClaw 서버 엔드포인트를 추가합니다
3. ZeroClaw 데몬이 표시하는 페어링 코드를 입력하고 **Pair**를 클릭합니다
4. 대화를 시작합니다

---

## 日本語

[ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) 向けのネイティブ macOS メニューバークライアントです。SwiftUI で構築されています。

### 主な機能
- **メニューバーアプリ** — システムメニューバーに常駐し、いつでもワンクリックでアクセス可能
- **ウィンドウモード** — 複雑な会話のための全画面ウィンドウモード
- **リアルタイムストリーミング** — WebSocket（`/ws/chat`）によるトークンストリーミング
- **Markdown レンダリング** — 見出し、リスト、引用、テーブル、コードブロック、Mermaid 図
- **画像サポート** — 貼り付け、ドラッグ＆ドロップ、ファイル添付
- **ツールコール表示** — 折りたたみ可能なツールコール／結果バブル
- **マルチサーバープロファイル** — 複数の ZeroClaw サーバー接続を管理
- **送信モード設定** — `Cmd+Return` または `Return` で送信、`⌘⇧↩` で切り替え
- **入力履歴** — `Shift+↑/↓` で過去のメッセージを呼び出し
- **チャット履歴の永続保存** — プロファイルごとに保存、再起動後も維持
- **日本語／CJK IME 対応** — NSTextView での正確な変換処理
- **Keychain トークン保管** — 安全な認証、認証プロンプトの繰り返しなし

### 必要環境
- macOS 14.0 (Sonoma) 以降
- [ZeroClaw デーモン](https://github.com/zeroclaw-labs/zeroclaw)（ローカルまたはリモート）
- Xcode 15+ および [xcodegen](https://github.com/yonaskolb/XcodeGen)

### ビルド方法
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### セットアップ
1. アプリを起動 — メニューバーに肉球アイコンが表示されます
2. **Settings** を開き、ZeroClaw サーバーのエンドポイントを追加します
3. ZeroClaw デーモンが表示するペアリングコードを入力し、**Pair** をクリックします
4. チャットを開始します

---

## 中文简体

适用于 [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) 的原生 macOS 菜单栏客户端，使用 SwiftUI 构建。

### 主要功能
- **菜单栏应用** — 常驻系统菜单栏，随时一键访问
- **窗口模式** — 支持全窗口展开，适合复杂对话
- **实时流式传输** — 基于 WebSocket（`/ws/chat`）的 Token 流式响应
- **Markdown 渲染** — 标题、列表、引用、表格、代码块、Mermaid 图表
- **图片支持** — 粘贴、拖放或附件上传
- **工具调用展示** — 可折叠的工具调用/结果气泡
- **多服务器配置** — 管理多个 ZeroClaw 服务器连接
- **发送模式设置** — `Cmd+Return` 或 `Return` 发送，`⌘⇧↩` 切换
- **输入历史** — `Shift+↑/↓` 浏览历史消息
- **聊天记录持久化** — 按配置文件保存，重启后仍可恢复
- **中文/CJK 输入法支持** — NSTextView 中正确处理输入法组合
- **Keychain 令牌存储** — 安全认证，无需重复授权

### 环境要求
- macOS 14.0 (Sonoma) 或更高版本
- [ZeroClaw 守护进程](https://github.com/zeroclaw-labs/zeroclaw)（本地或远程）
- Xcode 15+ 及 [xcodegen](https://github.com/yonaskolb/XcodeGen)

### 构建方法
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### 配置步骤
1. 启动应用 — 菜单栏出现爪印图标
2. 打开 **Settings**，添加 ZeroClaw 服务器地址
3. 输入 ZeroClaw 守护进程显示的配对码，点击 **Pair**
4. 开始聊天

---

## 中文繁體

適用於 [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) 的原生 macOS 選單列用戶端，以 SwiftUI 構建。

### 主要功能
- **選單列應用程式** — 常駐系統選單列，隨時一鍵存取
- **視窗模式** — 支援全視窗展開，適合複雜對話
- **即時串流傳輸** — 基於 WebSocket（`/ws/chat`）的 Token 串流回應
- **Markdown 渲染** — 標題、清單、引用、表格、程式碼區塊、Mermaid 圖表
- **圖片支援** — 貼上、拖放或附件上傳
- **工具呼叫展示** — 可折疊的工具呼叫/結果氣泡
- **多伺服器設定檔** — 管理多個 ZeroClaw 伺服器連線
- **傳送模式設定** — `Cmd+Return` 或 `Return` 傳送，`⌘⇧↩` 切換
- **輸入歷程** — `Shift+↑/↓` 瀏覽歷史訊息
- **聊天記錄持久化** — 依設定檔儲存，重新啟動後仍可還原
- **中文/CJK 輸入法支援** — NSTextView 中正確處理輸入法組合
- **Keychain 權杖儲存** — 安全認證，無需重複授權

### 環境需求
- macOS 14.0 (Sonoma) 或更新版本
- [ZeroClaw 常駐程式](https://github.com/zeroclaw-labs/zeroclaw)（本機或遠端）
- Xcode 15+ 及 [xcodegen](https://github.com/yonaskolb/XcodeGen)

### 建置方法
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### 設定步驟
1. 啟動應用程式 — 選單列出現爪印圖示
2. 開啟 **Settings**，新增 ZeroClaw 伺服器位址
3. 輸入 ZeroClaw 常駐程式顯示的配對碼，點選 **Pair**
4. 開始聊天

---

## Deutsch

Ein nativer macOS-Menüleisten-Client für [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), entwickelt mit SwiftUI.

### Funktionen
- **Menüleisten-App** — lebt in der Systemmenüleiste, immer einen Klick entfernt
- **Fenstermodus** — erweitertes Vollbildfenster für komplexe Gespräche
- **Echtzeit-Streaming** — WebSocket-basiertes Token-Streaming (`/ws/chat`)
- **Markdown-Rendering** — Überschriften, Listen, Zitate, Tabellen, Codeblöcke, Mermaid-Diagramme
- **Bildunterstützung** — Einfügen, Drag & Drop oder Dateianhang
- **Tool-Aufruf-Anzeige** — ein-/ausklappbare Tool-Call/Ergebnis-Blasen
- **Multi-Server-Profile** — mehrere ZeroClaw-Verbindungen verwalten
- **Sendemodus-Einstellung** — `Cmd+Return` oder `Return` zum Senden, `⌘⇧↩` zum Umschalten
- **Eingabeverlauf** — `Shift+↑/↓` zum Durchsuchen gesendeter Nachrichten
- **Persistenter Chat-Verlauf** — profilbasiert gespeichert, überlebt App-Neustarts
- **Koreanisch/CJK-IME-Unterstützung** — korrekte Komposition in NSTextView
- **Keychain-Token-Speicherung** — sicher, keine wiederholten Authentifizierungsdialoge

### Voraussetzungen
- macOS 14.0 (Sonoma) oder neuer
- [ZeroClaw-Daemon](https://github.com/zeroclaw-labs/zeroclaw) (lokal oder remote)
- Xcode 15+ und [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Build & Ausführen
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Einrichtung
1. App starten — ein Pfotensymbol erscheint in der Menüleiste
2. **Settings** öffnen und ZeroClaw-Server-Endpunkt hinzufügen
3. Den vom ZeroClaw-Daemon angezeigten Pairing-Code eingeben und auf **Pair** klicken
4. Chat starten

---

## Español

Un cliente nativo de macOS para la barra de menús de [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), desarrollado con SwiftUI.

### Características
- **App de barra de menús** — vive en la barra de menús del sistema, siempre a un clic
- **Modo ventana** — ventana completa expandible para conversaciones complejas
- **Streaming en tiempo real** — streaming de tokens vía WebSocket (`/ws/chat`)
- **Renderizado Markdown** — encabezados, listas, citas, tablas, bloques de código, diagramas Mermaid
- **Soporte de imágenes** — pegar, arrastrar y soltar o adjuntar archivos
- **Visualización de llamadas a herramientas** — burbujas plegables de tool call/resultado
- **Perfiles multi-servidor** — gestiona múltiples conexiones a ZeroClaw
- **Modo de envío por perfil** — `Cmd+Return` o `Return` para enviar, `⌘⇧↩` para alternar
- **Historial de entrada** — `Shift+↑/↓` para navegar mensajes anteriores
- **Historial de chat persistente** — guardado por perfil, sobrevive a reinicios
- **Soporte de IME coreano/CJK** — composición correcta en NSTextView
- **Almacenamiento seguro de tokens** — Keychain, sin diálogos de autenticación repetidos

### Requisitos
- macOS 14.0 (Sonoma) o posterior
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (local o remoto)
- Xcode 15+ y [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Compilar y ejecutar
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Configuración
1. Inicia la app — aparece un icono de huella en la barra de menús
2. Abre **Settings** y añade el endpoint de tu servidor ZeroClaw
3. Introduce el código de emparejamiento que muestra el daemon y haz clic en **Pair**
4. ¡Empieza a chatear!

---

## Français

Un client macOS natif pour la barre de menus de [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), développé avec SwiftUI.

### Fonctionnalités
- **Application dans la barre de menus** — toujours accessible en un clic depuis la barre système
- **Mode fenêtre** — fenêtre plein écran extensible pour les conversations complexes
- **Streaming en temps réel** — streaming de tokens via WebSocket (`/ws/chat`)
- **Rendu Markdown** — titres, listes, citations, tableaux, blocs de code, diagrammes Mermaid
- **Support des images** — coller, glisser-déposer ou joindre des fichiers
- **Affichage des appels d'outils** — bulles repliables pour les tool calls et résultats
- **Profils multi-serveurs** — gérez plusieurs connexions ZeroClaw
- **Mode d'envoi par profil** — `Cmd+Return` ou `Return` pour envoyer, `⌘⇧↩` pour basculer
- **Historique de saisie** — `Shift+↑/↓` pour naviguer dans les messages précédents
- **Historique de chat persistant** — sauvegardé par profil, conservé après redémarrage
- **Support IME coréen/CJK** — composition correcte dans NSTextView
- **Stockage sécurisé des tokens** — Keychain, sans invites d'authentification répétées

### Prérequis
- macOS 14.0 (Sonoma) ou version ultérieure
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (local ou distant)
- Xcode 15+ et [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Compilation et exécution
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Configuration
1. Lancez l'app — une icône de patte apparaît dans la barre de menus
2. Ouvrez **Settings** et ajoutez l'endpoint de votre serveur ZeroClaw
3. Entrez le code d'appairage affiché par le daemon et cliquez sur **Pair**
4. Commencez à discuter

---

## Português

Um cliente nativo macOS para a barra de menus do [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), desenvolvido com SwiftUI.

### Funcionalidades
- **App na barra de menus** — reside na barra de menus do sistema, sempre acessível
- **Modo janela** — janela expandida para conversas complexas
- **Streaming em tempo real** — streaming de tokens via WebSocket (`/ws/chat`)
- **Renderização Markdown** — títulos, listas, citações, tabelas, blocos de código, diagramas Mermaid
- **Suporte a imagens** — colar, arrastar e soltar ou anexar arquivos
- **Exibição de chamadas de ferramentas** — bolhas recolhíveis de tool call/resultado
- **Perfis multi-servidor** — gerencie múltiplas conexões ZeroClaw
- **Modo de envio por perfil** — `Cmd+Return` ou `Return` para enviar, `⌘⇧↩` para alternar
- **Histórico de entrada** — `Shift+↑/↓` para navegar em mensagens anteriores
- **Histórico de chat persistente** — salvo por perfil, sobrevive a reinicializações
- **Suporte IME coreano/CJK** — composição correta no NSTextView
- **Armazenamento seguro de tokens** — Keychain, sem prompts de autenticação repetidos

### Requisitos
- macOS 14.0 (Sonoma) ou posterior
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (local ou remoto)
- Xcode 15+ e [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Compilar e executar
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Configuração
1. Inicie o app — um ícone de pegada aparece na barra de menus
2. Abra **Settings** e adicione o endpoint do seu servidor ZeroClaw
3. Insira o código de pareamento exibido pelo daemon e clique em **Pair**
4. Comece a conversar

---

## Русский

Нативный клиент macOS для панели меню [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw), разработанный на SwiftUI.

### Возможности
- **Приложение в строке меню** — всегда в системной строке меню, доступно в один клик
- **Оконный режим** — расширенное полноэкранное окно для сложных разговоров
- **Стриминг в реальном времени** — потоковая передача токенов через WebSocket (`/ws/chat`)
- **Рендеринг Markdown** — заголовки, списки, цитаты, таблицы, блоки кода, диаграммы Mermaid
- **Поддержка изображений** — вставка, перетаскивание или вложение файлов
- **Отображение вызовов инструментов** — сворачиваемые пузыри tool call/результата
- **Мультисерверные профили** — управление несколькими подключениями ZeroClaw
- **Режим отправки по профилю** — `Cmd+Return` или `Return` для отправки, `⌘⇧↩` для переключения
- **История ввода** — `Shift+↑/↓` для навигации по предыдущим сообщениям
- **Постоянная история чата** — сохраняется по профилям, переживает перезапуски
- **Поддержка IME корейского/CJK** — корректная обработка в NSTextView
- **Хранение токенов в Keychain** — безопасно, без повторных запросов авторизации

### Требования
- macOS 14.0 (Sonoma) или новее
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (локально или удалённо)
- Xcode 15+ и [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Сборка и запуск
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### Настройка
1. Запустите приложение — в строке меню появится значок лапы
2. Откройте **Settings** и добавьте адрес вашего сервера ZeroClaw
3. Введите код сопряжения, показанный демоном, и нажмите **Pair**
4. Начните общение

---

## العربية

عميل macOS أصلي لشريط القوائم لـ [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw)، مبني باستخدام SwiftUI.

### المميزات
- **تطبيق شريط القوائم** — يعيش في شريط قوائم النظام، متاح دائمًا بنقرة واحدة
- **وضع النافذة** — نافذة كاملة قابلة للتوسيع للمحادثات المعقدة
- **بث في الوقت الفعلي** — بث الرموز عبر WebSocket (`/ws/chat`)
- **عرض Markdown** — عناوين، قوائم، اقتباسات، جداول، كتل أكواد، مخططات Mermaid
- **دعم الصور** — لصق، سحب وإفلات أو إرفاق الملفات
- **عرض استدعاءات الأدوات** — فقاعات قابلة للطي لاستدعاء الأدوات والنتائج
- **ملفات تعريف متعددة الخوادم** — إدارة اتصالات ZeroClaw متعددة
- **وضع الإرسال لكل ملف تعريف** — `Cmd+Return` أو `Return` للإرسال، `⌘⇧↩` للتبديل
- **سجل الإدخال** — `Shift+↑/↓` للتنقل بين الرسائل السابقة
- **سجل محادثة دائم** — محفوظ لكل ملف تعريف، يبقى بعد إعادة التشغيل
- **دعم IME الكورية/CJK** — معالجة صحيحة في NSTextView
- **تخزين رموز Keychain** — آمن، بدون مطالبات تحقق متكررة

### المتطلبات
- macOS 14.0 (Sonoma) أو أحدث
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (محلي أو عن بُعد)
- Xcode 15+ و [xcodegen](https://github.com/yonaskolb/XcodeGen)

### البناء والتشغيل
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### الإعداد
1. شغّل التطبيق — تظهر أيقونة مخلب في شريط القوائم
2. افتح **Settings** وأضف عنوان خادم ZeroClaw
3. أدخل رمز الإقران الذي يعرضه الخادم وانقر **Pair**
4. ابدأ الدردشة

---

## हिन्दी

[ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) के लिए एक नेटिव macOS मेनू बार क्लाइंट, SwiftUI के साथ निर्मित।

### मुख्य विशेषताएं
- **मेनू बार ऐप** — सिस्टम मेनू बार में रहता है, हमेशा एक क्लिक दूर
- **विंडो मोड** — जटिल बातचीत के लिए पूरी विंडो में विस्तार
- **रीयल-टाइम स्ट्रीमिंग** — WebSocket (`/ws/chat`) के माध्यम से टोकन स्ट्रीमिंग
- **Markdown रेंडरिंग** — हेडर, सूचियाँ, उद्धरण, तालिकाएँ, कोड ब्लॉक, Mermaid डायग्राम
- **इमेज सपोर्ट** — पेस्ट, ड्रैग & ड्रॉप या फ़ाइल अटैच करें
- **टूल कॉल डिस्प्ले** — फोल्ड/अनफोल्ड करने योग्य टूल कॉल/परिणाम बुलबुले
- **मल्टी-सर्वर प्रोफ़ाइल** — कई ZeroClaw कनेक्शन प्रबंधित करें
- **प्रोफ़ाइल-वार सेंड मोड** — `Cmd+Return` या `Return` से भेजें, `⌘⇧↩` से टॉगल करें
- **इनपुट इतिहास** — `Shift+↑/↓` से पिछले संदेश नेविगेट करें
- **स्थायी चैट इतिहास** — प्रोफ़ाइल-वार सहेजा गया, ऐप रीस्टार्ट के बाद भी बना रहता है
- **कोरियाई/CJK IME सपोर्ट** — NSTextView में सही कंपोज़िशन
- **Keychain टोकन स्टोरेज** — सुरक्षित, बार-बार ऑथ प्रॉम्प्ट नहीं

### आवश्यकताएं
- macOS 14.0 (Sonoma) या बाद का संस्करण
- [ZeroClaw daemon](https://github.com/zeroclaw-labs/zeroclaw) (लोकल या रिमोट)
- Xcode 15+ और [xcodegen](https://github.com/yonaskolb/XcodeGen)

### बिल्ड और रन
```bash
git clone https://github.com/TheMagicTower/zeroclaw-desktop-client-mac-swift.git
cd zeroclaw-desktop-client-mac-swift
brew install xcodegen
xcodegen generate
xcodebuild -scheme ZeroClawDesktop -configuration Debug build
```

### सेटअप
1. ऐप लॉन्च करें — मेनू बार में एक पंजा आइकन दिखाई देगा
2. **Settings** खोलें और ZeroClaw सर्वर एंडपॉइंट जोड़ें
3. ZeroClaw daemon द्वारा दिखाया गया पेयरिंग कोड दर्ज करें और **Pair** क्लिक करें
4. चैट शुरू करें

---

## License

MIT — © [The Magic Tower](https://github.com/TheMagicTower)
