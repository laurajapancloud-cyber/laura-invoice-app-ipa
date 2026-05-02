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
        webView.uiDelegate = self // ここが重要
        webView.allowsBackForwardNavigationGestures = true
        
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

    // MARK: - WKUIDelegate (JavaScriptダイアログの処理)
    
    // alert() の対応
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    // confirm() の対応
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }

    // prompt() の対応
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = defaultText
        }
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
