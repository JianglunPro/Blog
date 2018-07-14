# iOS 与 JS 的交互

## 通用方法

### JS 调用 Native

自定义协议头，拦截请求

```html
jscallnative://methodName/parameter1/parameter2
```

实现 `UIWebViewDelegate` 的代理方法，拦截请求

```swift
func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    // 判断是否是自定义协议头
    if let url = request.url, url.scheme == "jscallnative" {
        // 获取 js 想要调用的方法名和参数
        let method = url.host
        var parameters = url.pathComponents
        let p1 = parameters[1]
        let p2 = parameters[2]
        
        return false
    }
    return true
}
```

实现 `WKNavigationDelegate` 的代理方法，拦截请求

```swift
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
// 判断是否是自定义协议头
    if let url = navigationAction.request.url, url.scheme == "jscallnative" {
        // 获取 js 想要调用的方法名和参数
        let method = url.host
        var parameters = url.pathComponents
        let p1 = parameters[1]
        let p2 = parameters[2]
        
        decisionHandler(.cancel)
        return
    }
    decisionHandler(.allow)
}
```

### Native 调用 JS

比如 `js` 中定义了这个方法

```javascript
function nativeCallJS(message) {
    return message
}
```
调用的话很简单

```swift
// UIWebView
uiweb.stringByEvaluatingJavaScript(from: "nativeCallJS('parameter')")
// WKWebView
wkweb.evaluateJavaScript("nativeCallJS('parameter')", completionHandler: nil)
```


## 使用 JavascriptCore
### 简单上手
JSContext 和 JSValue 让我们可以很容易的运行 JS 代码并且和原生衔接

```swift
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

// 方便的调试
context?.exceptionHandler = {(context, exception) in
    if let error = exception?.toString() {
        print("JS error: \(error)")
    }
}
_ = context?.evaluateScript("add(3)")
```

### JS 调用 Native
思路是当网页加载完毕后，获取网页的 `JSContext`，注入对象和方法。

因为 `WKWebView` 无法获取到 `JSContext`，所以只对 `UIWebView` 适用
#### 使用 JSExport
声明一个协议，继承自 `JSExport`, 创建一个类遵守该协议

```swift
// 协议和对象都必须声明 @objc
@objc protocol ModelJSExport: JSExport {
    // 必须没有形参
    func callNative(_ parameter: String)
}

@objc class JSModel: NSObject, ModelJSExport {
    func callNative(_ parameter: String) {
        print("js call native with parameter :\(parameter)")
    }
}
```

在 `webViewDidFinishLoad` 方法中注入模型

```swift
// 获取网页的 JSContext
let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext

// 注入模型
let model = JSModel()
context.setObject(model, forKeyedSubscript: "App" as NSCopying & NSObjectProtocol)
```

然后在 JS 中就可以这样调用

```javascript
App.callNative('hello world')
```

#### 使用 OC Block
也可以直接注入 block

```swift
let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext

let callNative: @convention(block) (String) -> () = { [weak self] input in
    self?.doSomething()
    print("js call native with parameter :\(input)")
}
context.setObject(unsafeBitCast(callNative, to: AnyObject.self), forKeyedSubscript: "callNative" as NSCopying & NSObjectProtocol)
```
在 JS 中这样调用

```javascript
callNative('hello world (using oc block)')
```

### Native 调用 JS
比如 `js` 中定义了这个方法

```javascript
function nativeCallJS(message) {
    return message
}
```
这样调用

```swift
// 方式一
let value = context.evaluateScript("nativeCallJS('plan A')")

// 方式二
let jsMethod = context.objectForKeyedSubscript("nativeCallJS")!
let value = jsMethod.call(withArguments: ["plan B"])
```

## WKWebView 特性

### JS 调用 Native

注册消息处理

```swift
let handlerName = "App"

let config = WKWebViewConfiguration()
config.userContentController.add(self, name: handlerName)

wkweb = WKWebView(frame: view.bounds, configuration: config)
```

实现 `WKScriptMessageHandler` 代理方法，处理 `js` 消息

```swift
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
```

`js` 中发送消息

```javascript
var body = {
    method: "callNative:",
    parameter: "wow"
}
window.webkit.messageHandlers.App.postMessage(body)
```


