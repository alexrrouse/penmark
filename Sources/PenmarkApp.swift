import SwiftUI

@main
struct PenmarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState(rootDirectory: PenmarkApp.initialDirectory())
    @StateObject private var favoritesStore = FavoritesStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(favoritesStore)
                .frame(minWidth: 700, minHeight: 500)
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") {
                    openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("New Window…") {
                    openNewWindow()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(after: .toolbar) {
                Button("Toggle Rendered/Raw") {
                    appState.viewMode = appState.viewMode == .rendered ? .raw : .rendered
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Find in File") {
                    appState.isContentSearchVisible = true
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }

    private static func initialDirectory() -> URL? {
        let args = ProcessInfo.processInfo.arguments
        for arg in args.dropFirst() {
            if arg.hasPrefix("-") { continue }
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: arg, isDirectory: &isDir), isDir.boolValue {
                return URL(fileURLWithPath: arg).standardized
            }
        }
        return nil  // No default — user must explicitly open a folder
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder to open in Penmark"
        if panel.runModal() == .OK, let url = panel.url {
            appState.changeDirectory(to: url)
        }
    }

    private func openNewWindow() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a directory to open in a new window"
        if panel.runModal() == .OK, let url = panel.url {
            guard let appURL = Bundle.main.bundleURL.absoluteURL as URL? else { return }
            let config = NSWorkspace.OpenConfiguration()
            config.arguments = [url.path]
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config)
        }
    }
}

// MARK: - AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }
}
