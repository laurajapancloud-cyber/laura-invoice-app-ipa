import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
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
