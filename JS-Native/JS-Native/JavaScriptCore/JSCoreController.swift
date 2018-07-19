//
//  JSCoreController.swift
//  JS-Native
//
//  Created by 姜伦 on 2018/7/13.
//  Copyright © 2018年 JianglunPro. All rights reserved.
//

import UIKit
import JavaScriptCore

// 协议和对象都必须声明 @objc
@objc protocol ModelJSExport: JSExport {
    
    // 必须没有实参标签
    func callNative(_ parameter: String)
    
}

@objc class JSModel: NSObject, ModelJSExport {
    
    func callNative(_ parameter: String) {
        print("js call native with parameter :\(parameter)")
    }
    
}

class JSCoreController: UIViewController {

    var uiweb: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(callJS))
        navigationItem.rightBarButtonItem = item

        uiweb = UIWebView(frame: view.bounds)
        uiweb.delegate = self

        let url = Bundle.main.url(forResource: "core", withExtension: "html")!
        let request = URLRequest(url: url)

        view.addSubview(uiweb)
        uiweb.loadRequest(request)
        
    }
    
    // 简单上手 JSContext 和 JSValue
    func simpleBegin() {
        let context = JSContext()

        _ = context?.evaluateScript("var num = 1 + 2")
        _ = context?.evaluateScript("var names = ['Jay','Jolin','JJ']")
        _ = context?.evaluateScript("var triple = function(value) { return value * 3 }")
        let tripleNum = context?.evaluateScript("triple(1)")

        print("result: " + String(describing: tripleNum?.toInt32()))

        let names = context?.objectForKeyedSubscript("names")
        let firstName = names?.objectAtIndexedSubscript(0)
        print("firstName: " + String(describing: firstName?.toString()))

        let function = context?.objectForKeyedSubscript("triple")
        let result = function?.call(withArguments: [10])
        print("result: " + String(describing: result?.toNumber()))

        context?.exceptionHandler = {(context, exception) in
            if let error = exception?.toString() {
                print("JS error: \(error)")
            }
        }
        _ = context?.evaluateScript("add(3)")
    }
    
    @objc func callJS() {
        // 方式1
        uiweb.stringByEvaluatingJavaScript(from: "nativeCallJS('plan A')")
        
        let context = uiweb.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        // 方式2
        context.evaluateScript("nativeCallJS('plan B')")

        // 方式3
        let jsMethod = context.objectForKeyedSubscript("nativeCallJS")!
        jsMethod.call(withArguments: ["plan C"])
    }
    
    func doSomething() {
        
    }
}


extension JSCoreController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        // 使用 JSExport
        let model = JSModel()
        context.setObject(model, forKeyedSubscript: "App" as NSCopying & NSObjectProtocol)
        
        // 使用 OC Block
        let callNative: @convention(block) (String) -> () = { [weak self] input in
            self?.doSomething()
            print("js call native with parameter :\(input)")
        }
        context.setObject(unsafeBitCast(callNative, to: AnyObject.self), forKeyedSubscript: "callNative" as NSCopying & NSObjectProtocol)
    }
}
