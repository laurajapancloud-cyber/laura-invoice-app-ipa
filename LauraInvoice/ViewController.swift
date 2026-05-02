import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    
    // ==========================================
    // アプリのURL設定
    // ==========================================
    let appURLString = "https://laura-invoice-app.onrender.com/" 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        setupUI()
        loadApp()
        
        view.backgroundColor = .systemBackground
    }
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // JS Bridge の登録 (ダウンロード用)
        let contentController = WKUserContentController()
        contentController.add(self, name: "download")
        webConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // Pull-to-refresh (引っ張って更新) の追加
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // Safe Area を考慮したレイアウト
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setupUI() {
        // ローディングインジケーター
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    func loadApp() {
        guard let url = URL(string: appURLString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc func refreshWebView(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
    
    // MARK: - WKScriptMessageHandler
    // JS からのメッセージ受け取り (window.webkit.messageHandlers.download.postMessage)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "download", let dict = message.body as? [String: String] {
            let fileName = dict["filename"] ?? "document"
            
            // URL方式（推奨: 大きなファイルでも確実に動く）
            if let urlString = dict["url"], let url = URL(string: urlString) {
                downloadFromURL(url: url, fileName: fileName)
                return
            }
            
            // Base64方式（フォールバック: 小さいファイル用）
            if let base64String = dict["base64"] {
                handleBase64Download(base64: base64String, fileName: fileName)
            }
        }
    }
    
    private func downloadFromURL(url: URL, fileName: String) {
        // 認証ヘッダーを取得（WebViewのCookieを使う）
        var request = URLRequest(url: url)
        
        // WebViewの認証情報をコピー
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Basic認証のヘッダーをWebViewから取得して付与
        webView.evaluateJavaScript("document.cookie") { [weak self] _, _ in
            // URLSessionでダウンロード
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    print("Download failed: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                DispatchQueue.main.async {
                    self.presentShareSheet(data: data, fileName: fileName)
                }
            }
            task.resume()
        }
    }
    
    private func handleBase64Download(base64: String, fileName: String) {
        // 改行・空白を除去してからデコード
        let cleaned = base64.replacingOccurrences(of: "\n", with: "")
                            .replacingOccurrences(of: "\r", with: "")
                            .replacingOccurrences(of: " ", with: "")
        
        guard let data = Data(base64Encoded: cleaned) else {
            print("Failed to decode base64 for file: \(fileName)")
            return
        }
        
        presentShareSheet(data: data, fileName: fileName)
    }
    
    private func presentShareSheet(data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // iPad 対応
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            present(activityVC, animated: true)
            
        } catch {
            print("Failed to save file: \(error)")
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError(error)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "読み込みエラー", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "再試行", style: .default) { [weak self] _ in self?.loadApp() })
        alert.addAction(UIAlertAction(title: "閉じる", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - WKUIDelegate
    
    // target="_blank" のリンクを現在のWebViewで開く
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // iOS 15+ でカメラ・マイクの許可プロンプトを自動許可する
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
    
    // アラート (サイト名を表示)
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let host = webView.url?.host ?? "サイト"
        let alert = UIAlertController(title: host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }
    
    // 確認ダイアログ
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let host = webView.url?.host ?? "サイト"
        let alert = UIAlertController(title: host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
