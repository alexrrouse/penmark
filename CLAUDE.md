# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Penmark uses [Tuist](https://tuist.io/) to generate the Xcode project. Full Xcode.app (not just Command Line Tools) is required to run `tuist generate`.

```bash
# Generate Xcode project (requires Xcode.app installed)
tuist generate

# Then open in Xcode and build with ⌘B / run with ⌘R
open Penmark.xcodeproj
```

## Testing

Unit tests live in `Tests/` and cover `MarkdownRenderer`, `FileItem`/`FileTreeBuilder`, `FavoritesStore`, and `AppState`. After running `tuist generate`:

```bash
# Run tests in Xcode
# ⌘U

# Or from the command line
xcodebuild test -scheme Penmark -destination 'platform=macOS'
```

The `PenmarkTests` target in `Project.swift` depends on the main `Penmark` app target and uses `@testable import Penmark`.

## Architecture

**State management**: A single `AppState` ObservableObject is the source of truth, injected as an `@EnvironmentObject` into the entire view hierarchy from `PenmarkApp`. `FavoritesStore` is a separate singleton also injected as an environment object.

**Data flow**:
- `PenmarkApp.swift` reads the launch directory from `ProcessInfo.processInfo.arguments[1]` and initializes `AppState(rootDirectory:)`
- `AppState` holds `fileTree: [FileItem]`, `openTabs: [FileTab]`, `activeTabID`, `viewMode`, search state, and color scheme
- File tree is rebuilt asynchronously via `FileTreeBuilder.build()` on a background queue with 150ms debounce whenever `rootDirectory` or `fileSearchQuery` changes
- `FileItem` is a recursive value type (struct) with optional `children` for directories; the tree only includes `.md`/`.markdown`/`.mdown`/`.mkd` files

**Rendering pipeline**: `MarkdownRenderer.renderHTML(_:isDark:searchQuery:)` converts markdown to a full HTML document with inline CSS. The result is loaded into a `WKWebView` (wrapped in `WebView.swift` as an `NSViewRepresentable`). Search highlighting is done via JavaScript injected into the HTML document.

**Multiple windows**: Each `penmark .` CLI invocation calls `open -n Penmark.app --args /abs/path`, forcing a new process. New windows from within the app use `NSWorkspace.shared.openApplication(at:configuration:)` with `createsNewApplicationInstance = true`.

**View structure**:
- `ContentView` — `NavigationSplitView` with sidebar + detail pane; toolbar controls
- `FileBrowserView` — sidebar with filter bar, Favorites section, and recursive `FileRowView` tree
- `MarkdownPaneView` — tab bar (`TabBarView`) + content area that switches between `WebView` (rendered) and `MarkdownEditorView` (raw) based on `AppState.viewMode`

## Key conventions

- All Swift source lives in `Sources/`. The directory was renamed from `Penmark/` to avoid a case-insensitive filesystem conflict with the `penmark` CLI script at the repo root.
- `Derived/` contains Tuist-generated asset/bundle accessors — do not edit manually.
- `Penmark.xcodeproj` is gitignored; regenerate with `tuist generate`.
- Favorites are persisted to `UserDefaults` keyed by URL path strings. `FavoritesStore.favorites(under:)` filters the stored set to only URLs within the current root directory.
