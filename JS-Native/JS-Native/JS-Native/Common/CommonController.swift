//
//  InterceptController.swift
//  JS-Native
//
//  Created by 姜伦 on 2018/7/13.
//  Copyright © 2018年 JianglunPro. All rights reserved.
//

import UIKit
import WebKit

class CommonController: UIViewController {
    
    var uiweb: UIWebView!
    var wkweb: WKWebView!
    
    // 选择使用 UIWebView 还是 WKWebView
    var type: WebViewType = .UI
    enum WebViewType {
        case UI
        case WK
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(callJS))
        navigationItem.rightBarButtonItem = item

        uiweb = UIWebView(frame: view.bounds)
        uiweb.delegate = self
        
        wkweb = WKWebView(frame: view.bounds)
        wkweb.navigationDelegate = self
        
        let url = Bundle.main.url(forResource: "common", withExtension: "html")!
        let request = URLRequest(url: url)
            
        switch type {
        case .UI:
            view.addSubview(uiweb)
            uiweb.loadRequest(request)
        case .WK:
            view.addSubview(wkweb)
            wkweb.load(request)
        }
    }
    
    @objc func callJS() {
        switch type {
        case .UI:
            let result = uiweb.stringByEvaluatingJavaScript(from: "nativeCallJS('parameter')")
            print(String(describing: result))
        case .WK:
            wkweb.evaluateJavaScript("nativeCallJS('parameter')", completionHandler: { (result, error) in
                if let error = error { print(error.localizedDescription) }
                if let result = result { print(result) }
            })
        }
    }
    
    func callNative(_ p1: String, _ p2: String) {
        print("js call native with parameters: \(p1), \(p2)")
    }

}

extension CommonController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url, url.scheme == "jscallnative" {
            let method = url.host!
            var parameters = url.pathComponents
            let p1 = parameters[1]
            let p2 = parameters[2]
            
            if method == "callNative" {
                callNative(p1, p2)
            }
            
            return false
        }
        return true
    }
}

extension CommonController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "jscallnative" {
            
            if let method = url.host, method == "callNative" {
                var parameters = url.pathComponents
                let p1 = parameters[1]
                let p2 = parameters[2]
                callNative(p1, p2)
            }

            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
