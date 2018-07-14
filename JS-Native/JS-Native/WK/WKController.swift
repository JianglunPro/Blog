//
//  WKController.swift
//  JS-Native
//
//  Created by 姜伦 on 2018/7/13.
//  Copyright © 2018年 JianglunPro. All rights reserved.
//

import UIKit
import WebKit

class WKController: UIViewController {
    
    var wkweb: WKWebView!
    let handlerName = "App"

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: handlerName)
        
        wkweb = WKWebView(frame: view.bounds, configuration: config)
        
        let url = Bundle.main.url(forResource: "wk", withExtension: "html")!
        let request = URLRequest(url: url)
        
        view.addSubview(wkweb)
        wkweb.load(request)
    }
    
    @objc func callNative(_ parameter: String) {
        print(parameter)
    }

}

extension WKController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
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
