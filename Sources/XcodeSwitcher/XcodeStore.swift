import AppKit

// /Applications/Xcode.app を「既定」として扱う。それ以外を選んでいる間は警告を出す
let defaultXcodePath = "/Applications/Xcode.app"
let downloadPageURL = URL(string: "https://developer.apple.com/download/all/?q=Xcode")!

struct XcodeApp: Identifiable {
    let path: String
    let version: String
    var id: String { path }
    var name: String { (path as NSString).lastPathComponent }
}

enum InstallError: LocalizedError {
    case command(String)
    case appNotFound
    case versionNotFound
    case alreadyExists(String)

    var errorDescription: String? {
        switch self {
        case .command(let output): return output
        case .appNotFound: return t("xip の中に Xcode が見つかりませんでした。", "No Xcode app was found in the xip.")
        case .versionNotFound: return t("Xcode のバージョンを読み取れませんでした。", "Could not read the Xcode version.")
        case .alreadyExists(let path): return t("\(path) が既にあります。", "\(path) already exists.")
        }
    }
}

@MainActor
final class XcodeStore: ObservableObject {
    @Published private(set) var xcodes: [XcodeApp] = []
    @Published private(set) var currentPath: String?
    @Published private(set) var downloadedXips: [URL] = []
    /// 展開中の xip と、その進捗メッセージ
    @Published private(set) var installing: [URL: String] = [:]
    /// 中止できるよう、展開中の xip プロセスを持っておく
    @Published private var expandProcesses: [URL: Process] = [:]

    var current: XcodeApp? { xcodes.first { $0.path == currentPath } }
    var isDefault: Bool { currentPath == defaultXcodePath }

    func reload() {
        xcodes = Self.scanXcodes()
        currentPath = Self.readCurrentPath()
        downloadedXips = Self.scanDownloadedXips()
    }

    // MARK: - 読み取り

    private static func scanXcodes() -> [XcodeApp] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: "/Applications")) ?? []
        return names
            .filter { $0.hasPrefix("Xcode") && $0.hasSuffix(".app") }
            .compactMap { name in
                let path = "/Applications/\(name)"
                guard let version = readVersion(appPath: path) else { return nil }
                return XcodeApp(path: path, version: version)
            }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
    }

    private static func scanDownloadedXips() -> [URL] {
        let downloads = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        let files = (try? FileManager.default.contentsOfDirectory(at: downloads, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "xip" && $0.lastPathComponent.hasPrefix("Xcode") }
            .sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending }
    }

    nonisolated private static func readVersion(appPath: String) -> String? {
        let plist = NSDictionary(contentsOfFile: "\(appPath)/Contents/Info.plist")
        return plist?["CFBundleShortVersionString"] as? String
    }

    private static func readCurrentPath() -> String? {
        let output = try? run("/usr/bin/xcode-select", ["-p"])
        return output?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "/Contents/Developer").first
    }

    nonisolated private static func run(_ executable: String, _ arguments: [String], in directory: URL? = nil) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let directory { process.currentDirectoryURL = directory }
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self)
        guard process.terminationStatus == 0 else { throw InstallError.command(output) }
        return output
    }

    // MARK: - 切り替え・起動

    func select(_ xcode: XcodeApp) {
        // 管理者パスワードは macOS 標準のダイアログで入力する
        let script = "do shell script \"/usr/bin/xcode-select -s '\(xcode.path)'\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        reload()
        if let error {
            // -128 はユーザーがキャンセルしたとき
            if (error[NSAppleScript.errorNumber] as? Int) != -128 {
                showAlert(t("切り替えに失敗しました", "Failed to switch"), "\(error[NSAppleScript.errorMessage] ?? "")")
            }
            return
        }
        showAlert(
            t("Xcode \(xcode.version) に切り替えました", "Switched to Xcode \(xcode.version)"),
            t("開いている IDE（VS Code など）を再起動し、ビルドキャッシュを消してからビルドしてください。",
              "Restart your IDE (e.g. VS Code) and clean the build cache before building.")
        )
    }

    func launch(_ xcode: XcodeApp) {
        // 本体を直接実行して、新しい macOS での古い Xcode の起動制限を回避する
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "\(xcode.path)/Contents/MacOS/Xcode")
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            showAlert(t("起動に失敗しました", "Failed to launch"), error.localizedDescription)
        }
    }

    // MARK: - 追加

    func chooseXipAndInstall() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "xip")!]
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        install(url)
    }

    /// xip を展開し、/Applications/Xcode-<バージョン>.app に置く
    func install(_ xip: URL) {
        guard installing[xip] == nil else { return }
        installing[xip] = t("展開中…（10〜20分かかります）", "Expanding… (takes 10–20 min)")
        let workDir = FileManager.default.temporaryDirectory.appendingPathComponent("xcode-switcher-\(UUID().uuidString)")
        let expand = Process()
        expand.executableURL = URL(fileURLWithPath: "/usr/bin/xip")
        expand.arguments = ["-x", xip.path]
        expand.currentDirectoryURL = workDir
        expand.standardOutput = FileHandle.nullDevice
        expand.standardError = FileHandle.nullDevice
        expandProcesses[xip] = expand

        Task.detached {
            do {
                try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
                try expand.run()
                expand.waitUntilExit()
                if expand.terminationReason == .uncaughtSignal { throw CancellationError() }
                guard expand.terminationStatus == 0 else {
                    throw InstallError.command(t("xip の展開に失敗しました。", "Failed to expand the xip."))
                }

                let contents = try FileManager.default.contentsOfDirectory(atPath: workDir.path)
                guard let appName = contents.first(where: { $0.hasSuffix(".app") }) else { throw InstallError.appNotFound }
                let appPath = workDir.appendingPathComponent(appName).path
                guard let version = Self.readVersion(appPath: appPath) else { throw InstallError.versionNotFound }
                let destination = "/Applications/Xcode-\(version).app"
                guard !FileManager.default.fileExists(atPath: destination) else { throw InstallError.alreadyExists(destination) }

                try await MainActor.run {
                    self.expandProcesses[xip] = nil
                    self.installing[xip] = t("/Applications に配置中…", "Moving to /Applications…")
                    try self.move(appPath, to: destination)
                }
                try? FileManager.default.removeItem(at: workDir)
                await MainActor.run {
                    self.installing[xip] = nil
                    self.reload()
                    self.showAlert(
                        t("Xcode \(version) を追加しました", "Added Xcode \(version)"),
                        t("一覧の「切り替え」で使えます。初回はライセンス同意と iOS プラットフォームの追加が必要な場合があります。",
                          "Use \"Switch\" in the list. On first use you may need to accept the license and download the iOS platform.")
                    )
                }
            } catch {
                try? FileManager.default.removeItem(at: workDir)
                await MainActor.run {
                    self.expandProcesses[xip] = nil
                    self.installing[xip] = nil
                    if !(error is CancellationError) {
                        self.showAlert(t("追加に失敗しました", "Failed to add Xcode"), error.localizedDescription)
                    }
                }
            }
        }
    }

    /// 展開を中止する。途中まで展開したファイルは install 側で削除される
    func cancelInstall(_ xip: URL) {
        // 起動前の Process に terminate() すると例外になるので、実行中のときだけ止める
        guard let process = expandProcesses[xip], process.isRunning else { return }
        process.terminate()
    }

    func canCancelInstall(_ xip: URL) -> Bool {
        expandProcesses[xip] != nil
    }

    private func move(_ source: String, to destination: String) throws {
        do {
            try FileManager.default.moveItem(atPath: source, toPath: destination)
        } catch CocoaError.fileWriteNoPermission {
            // /Applications に書き込み権限がない場合は管理者権限で移動する
            let script = "do shell script \"/bin/mv '\(source)' '\(destination)'\" with administrator privileges"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            if let error { throw InstallError.command("\(error[NSAppleScript.errorMessage] ?? "")") }
        }
    }

    // MARK: - キャッシュ

    func clearDerivedData() {
        let alert = NSAlert()
        alert.messageText = t("DerivedData を削除しますか？", "Delete DerivedData?")
        alert.informativeText = t(
            "~/Library/Developer/Xcode/DerivedData を削除します。全プロジェクトの次回ビルドが遅くなります。",
            "This deletes ~/Library/Developer/Xcode/DerivedData. The next build of every project will be slower."
        )
        alert.addButton(withTitle: t("削除", "Delete"))
        alert.addButton(withTitle: t("キャンセル", "Cancel"))
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        do {
            try FileManager.default.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            // 既に無い
        } catch {
            showAlert(t("削除に失敗しました", "Failed to delete"), error.localizedDescription)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
