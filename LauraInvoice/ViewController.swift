import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    
    // ==========================================
    // ここにあなたのアプリのURLをセットしてください
    // ==========================================
    let appURL = "https://laura-invoice-app.onrender.com/" 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        loadApp()
        
        // 背景色をアプリに合わせる（例：ダークモード対応なら黒）
        view.backgroundColor = .systemBackground
    }
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true // スワイプで戻る/進むを有効化
        
        // 画面いっぱいに広げる
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func loadApp() {
        if let url = URL(string: appURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // ステータスバーの色などを調整（必要に応じて）
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
