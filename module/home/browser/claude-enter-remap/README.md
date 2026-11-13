# Claude Enter Remap

claude.ai (Web) のキー割り当てを変更する最小構成の Chrome 拡張 (Manifest V3)。

| キー | 動作 |
|---|---|
| Enter | 改行 |
| Shift+Enter / Alt+Enter | 改行（元の挙動のまま） |
| Ctrl+Enter / Cmd+Enter | 送信 |
| IME 変換中の Enter | 介入しない（変換確定のみ） |

## インストール
Home Manager（`module/home/browser.nix`）が `~/.local/share/chrome-extensions/claude-enter-remap` に配置する。

1. `chrome://extensions` を開き、右上の「デベロッパーモード」を ON にする
2. 「パッケージ化されていない拡張機能を読み込む」で上記のフォルダを選ぶ（初回のみ）
3. claude.ai をリロードする

ソースを変更して rebuild した後は、`chrome://extensions` で拡張の再読み込みボタンを押す。

権限は `https://claude.ai/*` への content script のみ。ネットワーク通信やストレージは使わない。

## 仕組み
- capture フェーズの keydown で Enter を横取りする
- 改行は、Shift+Enter の合成イベントをエディタ (ProseMirror) に渡して実現する
- 送信は、送信ボタン（`aria-label="Send message"`）をクリックする。見つからない場合は通常の Enter を合成する
- `isComposing` / keyCode 229 の場合は何もしない

## 既知のリスク
- claude.ai の DOM（エディタ実装や送信ボタンの aria-label）が変わると動かなくなる
- UI の言語設定によって aria-label が変わる場合は、`SEND_SELECTORS` に追加する
- Firefox では `about:debugging` から一時的に読み込める（永続化には署名が必要）
