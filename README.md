# Penmark

A native macOS markdown viewer with a focus on speed, clarity, and keyboard-friendly navigation.

![Penmark](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Launch from the command line** — `penmark .` opens the current directory
- **File browser** — Left sidebar shows only markdown files, organized by folder structure
- **Favorites** — Star any file or folder for quick access at the top of the sidebar
- **Tabs** — Open multiple files simultaneously with a tab strip
- **Rendered & raw views** — Toggle between beautiful rendered HTML and raw markdown source
- **In-file search** — ⌘F highlights matching text in both rendered and raw views
- **File filter** — Type in the sidebar search bar to filter files by name
- **Dark mode** — Respects system appearance with an override toggle (System / Light / Dark)
- **Multiple instances** — Run `penmark /path/one` and `penmark /path/two` side by side
- **New Window** — Open a new directory via ⇧⌘N or File > New Window

## Installation

### Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later (to build)

### Build

1. Clone the repository:
   ```bash
   git clone https://github.com/yourname/penmark.git
   cd penmark
   ```

2. Install Tuist (if needed):
   ```bash
   brew install tuist
   ```

3. Generate the Xcode project:
   ```bash
   tuist generate
   ```

4. Open in Xcode and build:
   ```bash
   open Penmark.xcodeproj
   ```
   Press **⌘B** to build, then **⌘R** to run.

5. Copy `Penmark.app` (from the build output) to `/Applications`.

### Testing

After generating the Xcode project, run the test suite:

- **Xcode**: Press **⌘U** to run all tests
- **Command line**: `xcodebuild test -scheme Penmark -destination 'platform=macOS'`

### CLI Setup

After installing the app, set up the `penmark` command:

```bash
# Option A: symlink from /usr/local/bin
sudo ln -sf "$(pwd)/penmark" /usr/local/bin/penmark

# Option B: add the repo directory to your PATH
echo 'export PATH="$PATH:/path/to/penmark"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```bash
# Open current directory
penmark .

# Open a specific directory
penmark ~/Documents/notes

# Open multiple directories in separate windows
penmark ~/projects/foo &
penmark ~/projects/bar
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘F | Find in file |
| ⇧⌘R | Toggle rendered / raw view |
| ⇧⌘N | New Window (choose directory) |
| ⌘W | Close window |

### Sidebar

- **Filter bar** at the top filters visible files by name as you type
- **Favorites** section appears at the top when you've starred items
- Click the **★** that appears on hover to toggle a file or folder as a favorite
- Right-click any item for the context menu (Reveal in Finder, Copy Path, etc.)
- Click a folder to expand/collapse it

### View Modes

- **Rendered** — Fully styled HTML rendering with syntax-aware code blocks, tables, and proper typography
- **Raw** — Monospaced source view with search highlighting

### Color Scheme

Click the moon/sun icon in the toolbar to cycle between System, Light, and Dark modes.

## Project Structure

```
penmark/
├── penmark              # CLI launcher script
├── Project.swift        # Tuist project manifest
├── Tuist.swift          # Tuist global config
├── Sources/             # Swift source files
│   ├── PenmarkApp.swift
│   ├── AppState.swift
│   ├── FileItem.swift
│   ├── FavoritesStore.swift
│   ├── MarkdownRenderer.swift
│   ├── WebView.swift
│   ├── ContentView.swift
│   ├── FileBrowserView.swift
│   ├── MarkdownPaneView.swift
│   ├── TabBarView.swift
│   ├── MarkdownEditorView.swift
│   ├── Info.plist
│   └── Assets.xcassets/
├── Tests/               # Unit tests
│   ├── MarkdownRendererTests.swift
│   ├── FileItemTests.swift
│   ├── FavoritesStoreTests.swift
│   └── AppStateTests.swift
└── README.md
```

## Architecture

- **SwiftUI + AppKit** — Native macOS UI using SwiftUI's `NavigationSplitView` with AppKit bridging where needed
- **WKWebView** — Rendered markdown is converted to HTML and displayed in a WebKit view for full fidelity
- **Custom markdown renderer** — Pure Swift markdown → HTML converter supporting headings, bold, italic, code blocks, tables, blockquotes, lists, links, and images
- **UserDefaults** — Favorites are persisted locally per-machine
- **Process isolation** — Each `penmark .` invocation creates a fully independent app process

## License

MIT
