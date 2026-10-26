import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: XcodeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentBanner

            Text(t("インストール済みの Xcode", "Installed Xcode")).font(.headline)
            VStack(spacing: 8) {
                ForEach(store.xcodes) { xcode in
                    installedRow(xcode)
                }
            }

            Divider()

            addSection

            Divider()

            HStack {
                Button(t("DerivedData を削除…", "Delete DerivedData…")) { store.clearDerivedData() }
                Spacer()
                Button {
                    HelpWindow.show()
                } label: {
                    Label(t("使い方", "Help"), systemImage: "questionmark.circle")
                }
                Button(t("再読み込み", "Reload")) { store.reload() }
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    // MARK: - 現在の Xcode

    private var currentBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: store.isDefault ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(store.isDefault ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(t("現在の既定の Xcode", "Current default Xcode")).font(.caption).foregroundStyle(.secondary)
                Text(store.current.map { "Xcode \($0.version)" } ?? t("不明", "Unknown"))
                    .font(.title2.bold())
                if !store.isDefault {
                    Text(t("確認が終わったら Xcode.app に戻してください", "Switch back to Xcode.app when you are done"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill((store.isDefault ? Color.green : Color.orange).opacity(0.12))
        )
    }

    private func installedRow(_ xcode: XcodeApp) -> some View {
        let isCurrent = xcode.path == store.currentPath
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Xcode \(xcode.version)").font(.body.bold())
                Text(xcode.name).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(t("起動", "Open")) { store.launch(xcode) }
            if isCurrent {
                Text(t("使用中", "In use"))
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.2)))
            } else {
                Button(t("切り替え", "Switch")) { store.select(xcode) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.accentColor : Color.secondary.opacity(0.3))
        )
    }

    // MARK: - 追加

    private var addSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("Xcode を追加", "Add Xcode")).font(.headline)

            HStack(spacing: 8) {
                StepBadge(number: 1)
                Text(t("Apple Developer で xip をダウンロード", "Download an xip from Apple Developer"))
                Spacer()
                Button {
                    NSWorkspace.shared.open(downloadPageURL)
                } label: {
                    Label(t("サイトを開く", "Open site"), systemImage: "safari")
                }
            }

            HStack(alignment: .top, spacing: 8) {
                StepBadge(number: 2)
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("展開して /Applications に追加", "Expand and add to /Applications"))
                    if store.downloadedXips.isEmpty {
                        Text(t("~/Downloads に Xcode の xip はありません", "No Xcode xip found in ~/Downloads"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.downloadedXips, id: \.self) { xip in
                        xipRow(xip)
                    }
                    Button(t("他の xip を選ぶ…", "Choose another xip…")) { store.chooseXipAndInstall() }
                        .buttonStyle(.link)
                }
            }
        }
    }

    private func xipRow(_ xip: URL) -> some View {
        HStack {
            Image(systemName: "archivebox").foregroundStyle(.secondary)
            Text(xip.lastPathComponent).font(.callout).lineLimit(1).truncationMode(.middle)
            Spacer()
            if let status = store.installing[xip] {
                ProgressView().controlSize(.small)
                Text(status).font(.caption).foregroundStyle(.secondary)
                if store.canCancelInstall(xip) {
                    Button(t("中止", "Cancel")) { store.cancelInstall(xip) }
                }
            } else {
                Button(t("追加", "Add")) { store.install(xip) }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
    }
}

private struct StepBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.accentColor))
    }
}
