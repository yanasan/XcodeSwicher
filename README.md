# Xcode Switcher

A small macOS app to see, switch, add, and open multiple Xcode versions.

- **See** which Xcode is the current default (`xcode-select`). A ⚠️ warning is shown while anything other than `/Applications/Xcode.app` is selected, so you don't forget to switch back.
- **Switch** the default Xcode with one click (asks for your Mac password via the standard macOS dialog).
- **Add** an Xcode from a downloaded `.xip`: it is expanded and placed as `/Applications/Xcode-<version>.app`.
- **Open** an older Xcode even on a newer macOS that refuses to launch it from Finder (the app runs the binary directly).
- **Delete DerivedData** and read a built-in Q&A for common errors after switching.

The UI is shown in Japanese on Japanese systems and in English otherwise.

## Requirements

- macOS 13 or later
- Xcode or the Command Line Tools (to build)

## Build & install

```sh
git clone https://github.com/yanasan/XcodeSwicher.git
cd XcodeSwicher
./scripts/build-app.sh
open ~/Applications/XcodeSwitcher.app
```

To start it at login, add `~/Applications/XcodeSwitcher.app` in System Settings → General → Login Items.

## Usage

1. Press **Open site** and download an Xcode `.xip` from Apple Developer.
2. Xcode xips in `~/Downloads` appear in the list. Press **Add** (expanding takes 10–20 minutes).
3. Press **Switch** on the Xcode you want to use, then restart your IDE and clean the build cache.
4. When you're done, switch back to `Xcode.app`.

Before building with a newly added Xcode for the first time:

```sh
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
```

## Notes

- Switching only with the `DEVELOPER_DIR` environment variable can mix in the SDK of another Xcode (`unknown architecture` linker errors). Switching the default is more reliable.
- Launching an Xcode version that Apple no longer supports on your macOS is unsupported by Apple; some features may not work.

## License

MIT
