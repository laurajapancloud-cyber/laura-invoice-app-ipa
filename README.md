# Laura Invoice iOS App (TrollStore Edition)

このフォルダは、Laura Invoice AppをiOSネイティブアプリ（IPA）として自動ビルドするためのソースコードです。

## 使い方

1. **GitHubで新しいリポジトリを作成**
   - 名前は何でもOK（例: `laura-ios-app`）
   - **Public** でも **Private** でも大丈夫です。

2. **このフォルダのファイルをアップロード**
   - `ios_build` フォルダの中身（`.github`, `LauraInvoice`, `project.yml`）をリポジトリのルートにプッシュしてください。

3. **URLの変更**
   - `LauraInvoice/ViewController.swift` の `appURL` 変数を、あなたのアプリのURLに書き換えてください。

4. **自動ビルド開始**
   - GitHubにプッシュすると、自動的に **Actions** タブでビルドが始まります。
   - 数分待つと、ビルド結果（Artifacts）の中に `LauraInvoice-IPA` という名前のZIPが生成されます。

5. **インストール**
   - 生成された `LauraInvoice.ipa` をiPhoneに送り、**TrollStore** でインストールしてください。

## カスタマイズ
- **アイコン:** `LauraInvoice` フォルダ内に `Assets.xcassets` を作成してアイコンを追加するか、XcodeGenのドキュメントに従って設定してください。
- **スワイプ戻る:** `ViewController.swift` で `webView.allowsBackForwardNavigationGestures = true` に設定済みです。
