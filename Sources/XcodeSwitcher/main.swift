import AppKit
import SwiftUI

// 既定の Xcode（xcode-select）を確認・切り替え・追加するツール
// ウィンドウと Dock アイコンで操作し、メニューバーにも現在の Xcode を出す

@MainActor
enum HelpWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = t("使い方", "Help")
            window.contentView = NSHostingView(rootView: HelpView())
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = XcodeStore()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var window: NSWindow?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.reload()
        setupStatusItem()
        showWindow()
        // ターミナルから xcode-select を変えた場合や、xip のダウンロード完了にも追従する
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.store.reload()
                self?.refreshTitle()
            }
        }
    }

    // Dock アイコンをクリックしたらウィンドウを出す
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    @objc private func showWindow() {
        if window == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Xcode Switcher"
            window.contentView = NSHostingView(rootView: ContentView(store: store))
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        store.reload()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - メニューバー

    private func setupStatusItem() {
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshTitle()
    }

    private func refreshTitle() {
        let warning = store.isDefault ? "" : "⚠️ "
        statusItem.button?.title = "\(warning)Xcode \(store.current?.version ?? "?")"
    }

    func menuWillOpen(_ menu: NSMenu) {
        store.reload()
        refreshTitle()
        menu.removeAllItems()
        let open = NSMenuItem(title: t("ウィンドウを開く", "Open Window"), action: #selector(showWindow), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: t("終了", "Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
