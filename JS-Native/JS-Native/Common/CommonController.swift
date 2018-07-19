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
    
    // choose using UIWebView or WKWebView
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
    
    func callNative(_ p: String) {
        print("js call native with parameters: \(p)")
    }
    
}

extension CommonController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.url!
        if url.scheme == "jscallnative" {
            let method = url.host!
            var parameters = url.pathComponents
            let p = parameters[1]
            if method == "callNative" {
                callNative(p)
            }
            return false
        }
        return true
    }
}

extension CommonController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        if url.scheme == "jscallnative" {
            let method = url.host!
            var parameters = url.pathComponents
            let p = parameters[1]
            if method == "callNative" {
                callNative(p)
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
