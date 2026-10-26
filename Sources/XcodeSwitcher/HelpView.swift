import AppKit
import SwiftUI

// 使い方の Q&A 画面
// 各回答には SF Symbols で描いた図を付ける

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(t("使い方 Q&A", "Help")).font(.title.bold())
                Text(t("項目をクリックすると開きます", "Click a question to expand it")).font(.caption).foregroundStyle(.secondary)

                QAItem(question: t("このツールは何をするもの？", "What does this app do?"), initiallyExpanded: true) {
                    Text(t(
                        "Mac 全体で使う「既定の Xcode」（xcode-select）を切り替えます。IDE やコマンドライン（xcodebuild, flutter など）は、この既定の Xcode でビルドします。",
                        "It switches the Mac-wide default Xcode (xcode-select). IDEs and command line tools (xcodebuild, flutter, etc.) build with this default Xcode."
                    ))
                    StepFlow(steps: [
                        Step(symbol: "chevron.left.forwardslash.chevron.right", label: t("IDE\nCLI", "IDE\nCLI")),
                        Step(symbol: "arrow.triangle.branch", label: t("既定の\nXcode", "Default\nXcode")),
                        Step(symbol: "hammer.fill", label: t("選んだ Xcode\nでビルド", "Builds with\nthat Xcode")),
                    ])
                }

                QAItem(question: t("Xcode を追加したい", "How do I add an Xcode?")) {
                    StepFlow(steps: [
                        Step(symbol: "safari", label: t("①「サイトを開く」\nで xip を取得", "① \"Open site\"\nget the xip")),
                        Step(symbol: "archivebox", label: t("② 一覧の\n「追加」", "② Press\n\"Add\"")),
                        Step(symbol: "folder.badge.plus", label: t("③ 自動で\n/Applications へ", "③ Placed in\n/Applications")),
                    ])
                    Text(t(
                        "~/Downloads にある Xcode の xip は自動で一覧に出ます。展開には 10〜20 分かかります。/Applications/Xcode-<バージョン>.app という名前で置かれます。",
                        "Xcode xips in ~/Downloads are listed automatically. Expanding takes 10–20 minutes. The app is placed as /Applications/Xcode-<version>.app."
                    ))
                    Button(t("Apple Developer のダウンロードページを開く", "Open the Apple Developer download page")) {
                        NSWorkspace.shared.open(downloadPageURL)
                    }
                    .buttonStyle(.link)
                }

                QAItem(question: t("追加した Xcode を初めて使う前に", "Before using a newly added Xcode")) {
                    Text(t("ライセンス同意と初回セットアップ、iOS プラットフォームの追加が必要です。", "Accept the license, run first launch, and download the iOS platform."))
                    CommandBox(command: "sudo DEVELOPER_DIR=/Applications/Xcode-26.0.1.app/Contents/Developer xcodebuild -license accept")
                    CommandBox(command: "DEVELOPER_DIR=/Applications/Xcode-26.0.1.app/Contents/Developer xcodebuild -runFirstLaunch")
                    CommandBox(command: "DEVELOPER_DIR=/Applications/Xcode-26.0.1.app/Contents/Developer xcodebuild -downloadPlatform iOS")
                    Note(text: t("パスは使う Xcode に合わせて変えてください。", "Replace the path with the Xcode you use."))
                }

                QAItem(question: t("別の Xcode でビルドしたい", "How do I build with another Xcode?")) {
                    StepFlow(steps: [
                        Step(symbol: "arrow.left.arrow.right", label: t("①「切り替え」", "① \"Switch\"")),
                        Step(symbol: "lock.fill", label: t("② Mac の\nパスワード", "② Mac\npassword")),
                        Step(symbol: "power", label: t("③ IDE を\n再起動", "③ Restart\nthe IDE")),
                        Step(symbol: "trash", label: t("④ ビルド\nキャッシュ削除", "④ Clean the\nbuild cache")),
                        Step(symbol: "play.fill", label: t("⑤ ビルド", "⑤ Build")),
                    ])
                    Text(t("③ を飛ばすと、IDE が切り替え前の Xcode を覚えたままになります。", "If you skip ③, the IDE keeps using the previous Xcode."))
                    Note(text: t(
                        "環境変数 DEVELOPER_DIR だけで切り替えると、ビルドの一部に元の Xcode の SDK が混ざることがあります。このツールで既定ごと切り替えるのが確実です。",
                        "Switching only with the DEVELOPER_DIR environment variable can mix in the other Xcode's SDK. Switching the default with this app is more reliable."
                    ))
                }

                QAItem(question: t("古い Xcode の画面を開きたい", "How do I open an older Xcode?")) {
                    Text(t(
                        "新しい macOS では、Finder や Dock から古い Xcode を開くと止められます。このツールの「起動」ボタンは本体を直接実行するので開けます。",
                        "Newer macOS blocks older Xcode versions opened from Finder or the Dock. The \"Open\" button runs the binary directly, so it works."
                    ))
                    Compare(
                        bad: Step(symbol: "folder", label: t("Finder から\nダブルクリック", "Double-click\nin Finder")),
                        good: Step(symbol: "play.circle.fill", label: t("このツールの\n「起動」", "\"Open\" in\nthis app"))
                    )
                }

                QAItem(question: t("確認が終わったら？（戻し忘れ防止）", "When I'm done? (don't forget to switch back)")) {
                    Text(t(
                        "Xcode.app 以外を選んでいる間は、画面上部が ⚠️ オレンジ色になり、メニューバーにも ⚠️ が付きます。終わったら Xcode.app の「切り替え」を押して戻してください。",
                        "While anything other than Xcode.app is selected, the banner turns orange with ⚠️, and so does the menu bar. Press \"Switch\" on Xcode.app to go back."
                    ))
                    HStack(spacing: 16) {
                        Banner(isDefault: false, version: "26.0.1")
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        Banner(isDefault: true, version: "27.1")
                    }
                    .frame(maxWidth: .infinity)
                }

                QAItem(question: t("エラー: unknown architecture / linker command failed", "Error: unknown architecture / linker command failed")) {
                    Text(t("前の Xcode でビルドしたキャッシュが残っていて、Xcode が混ざっています。", "Build caches from the previous Xcode are being mixed in."))
                    StepFlow(steps: [
                        Step(symbol: "trash", label: t("ビルド\nキャッシュ削除", "Clean the\nbuild cache")),
                        Step(symbol: "xmark.bin", label: t("DerivedData\nを削除", "Delete\nDerivedData")),
                        Step(symbol: "arrow.clockwise", label: t("もう一度\nビルド", "Build\nagain")),
                    ])
                    Text(t("DerivedData はメイン画面の「DerivedData を削除…」で消せます。", "Use \"Delete DerivedData…\" on the main window."))
                }

                QAItem(question: t("エラー: iOS xx is not installed", "Error: iOS xx is not installed")) {
                    Text(t("その Xcode に iOS プラットフォームが入っていません。Xcode 26 以降は本体と別ダウンロードです。", "That Xcode has no iOS platform. Since Xcode 26 it is a separate download."))
                    CommandBox(command: "xcodebuild -downloadPlatform iOS")
                    Text(t("既定の Xcode に対して実行されます。Xcode の Settings → Components からも入れられます。", "Runs against the default Xcode. You can also use Xcode > Settings > Components."))
                }
            }
            .padding(20)
        }
        .frame(width: 620, height: 700)
    }
}

// MARK: - 部品

private struct QAItem<Content: View>: View {
    let question: String
    @State private var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    init(question: String, initiallyExpanded: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.question = question
        self._isExpanded = State(initialValue: initiallyExpanded)
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        } label: {
            Label(question, systemImage: "questionmark.circle.fill")
                .font(.headline)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { isExpanded.toggle() } }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
    }
}

private struct Step {
    let symbol: String
    let label: String
}

private struct StepIcon: View {
    let step: Step
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: step.symbol)
                .font(.system(size: 22))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(Circle().fill(tint.opacity(0.15)))
            Text(step.label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .fixedSize()
        }
    }
}

private struct StepFlow: View {
    let steps: [Step]

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                StepIcon(step: step)
                if index < steps.count - 1 {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct Compare: View {
    let bad: Step
    let good: Step

    var body: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                StepIcon(step: bad, tint: .red)
                Label("NG", systemImage: "xmark.circle.fill").font(.caption.bold()).foregroundStyle(.red)
            }
            VStack(spacing: 4) {
                StepIcon(step: good, tint: .green)
                Label("OK", systemImage: "checkmark.circle.fill").font(.caption.bold()).foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct Banner: View {
    let isDefault: Bool
    let version: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isDefault ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isDefault ? .green : .orange)
            Text("Xcode \(version)").font(.callout.bold())
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill((isDefault ? Color.green : Color.orange).opacity(0.15)))
    }
}

private struct CommandBox: View {
    let command: String
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top) {
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(copied ? t("コピー済み", "Copied") : t("コピー", "Copy")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
                copied = true
            }
            .controlSize(.small)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.06)))
    }
}

private struct Note: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "lightbulb.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
