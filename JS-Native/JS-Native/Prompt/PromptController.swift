//
//  TestController.swift
//  JS-Native
//
//  Created by 姜伦 on 2018/7/17.
//  Copyright © 2018年 JianglunPro. All rights reserved.
//

import UIKit
import WebKit

class PromptController: UIViewController {

    var wkweb: WKWebView!
    let handlerName = "App"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: handlerName)
        
        wkweb = WKWebView(frame: view.bounds, configuration: config)
        wkweb.uiDelegate = self
        
        let url = Bundle.main.url(forResource: "prompt", withExtension: "html")!
        let request = URLRequest(url: url)
        
        view.addSubview(wkweb)
        wkweb.load(request)
        
    }
    
    @objc func callNative(_ parameter: String) {
        print(parameter)
    }

}

extension PromptController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        if message.name == handlerName {
            if let body = message.body as? [String: Any], let method = body["method"] as? String, let parameter = body["parameter"] as? String {
                let selector = Selector(method)
                if responds(to: selector) {
                    self.perform(selector, with: parameter)
                }
            }
        }
    }
}

extension PromptController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        self.alert(message: message, completionHandler: completionHandler)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        self.confirm(message: message, completionHandler: completionHandler)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        // 拦截弹窗示例
        
        // 判断信息是否是一个字典
        if let jsonData = prompt.data(using: .utf8), let json = (try? JSONSerialization.jsonObject(with: jsonData, options: [])) as? [String: Any] {
            // 判断要调用的方法
            let action = json["action"] as! String
            if action == "callNative" {
                // 拿到参数
                let p = json["params"] as! String
                print(p)
                // 同步给出返回值
                completionHandler("from native: \(p)")
            }
        }
        else {
            self.prompt(message: prompt, defaultText: defaultText, completionHandler: completionHandler)
        }
    }
}

extension UIViewController {
    
    func alert(message: String, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { (action) in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func confirm(message: String, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { (action) in
            completionHandler(true)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func prompt(message: String, defaultText: String?, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { (action) in
            let input = alertController.textFields?.first?.text
            completionHandler(input)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
}
