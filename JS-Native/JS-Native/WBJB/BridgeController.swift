//
//  BridgeController.swift
//  JS-Native
//
//  Created by 姜伦 on 2018/7/18.
//  Copyright © 2018年 JianglunPro. All rights reserved.
//

import UIKit

class BridgeController: UIViewController {
    
    var uiweb: UIWebView!
    var bridge: WebViewJavascriptBridge!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(play))
        navigationItem.rightBarButtonItem = item

        uiweb = UIWebView(frame: view.bounds)
        
        let url = Bundle.main.url(forResource: "bridge", withExtension: "html")!
        let request = URLRequest(url: url)
        
        view.addSubview(uiweb)
        uiweb.loadRequest(request)
        
        bridge = WebViewJavascriptBridge(forWebView: uiweb)
        bridge.registerHandler("callNative") { (data, responseCallback) in
            print("call native")
            if let data = data {
                print("with params: \(data)")
            }
            if let responseCallback = responseCallback {
                let p: [String: Any] = [
                    "p1": 1,
                    "p2": ["1", "2", "3"]
                ]
                responseCallback(p)
            }
        }
    }
    
    @objc func play() {
        let params: [String: Any] = [
            "p1": 1,
            "p2": ["1", "2", "3"]
        ]
        bridge.callHandler("callJS", data: params, responseCallback: { (data) in
            if let data = data {
                print("js call back: \(data)")
            }
        })
    }

}
