import Foundation

// 日本語環境なら日本語、それ以外は英語を返す
let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

func t(_ ja: String, _ en: String) -> String {
    isJapanese ? ja : en
}
