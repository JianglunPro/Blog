;(function() {
    
    if (window.WebViewJavascriptBridge) {
        return;
    }
    if (!window.onerror) {
        window.onerror = function(msg, url, line) {
            console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
        }
    }
  
    // 专门用来发消息的 iframe (iframe.src = '')
    var messagingIframe;
    // 消息队列，储存‘快速’‘连续’发送的消息实体，注意⚠️: 消息并不会在 url 中，url 只用来通知 native 有“一些”消息来了
    var sendMessageQueue = [];
    // 这是 native call js 用的
    var messageHandlers = {};

    // 下面两个组合用来表示这是一个发消息的 fake url
    var CUSTOM_PROTOCOL_SCHEME = 'https';
    var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';

    // 这是 js call native 用的
    // 回调字典，回调不会包含在消息实体中，而是为回调生成一个回调 id，放在消息实体中，后面用这个 id 来取回调函数
    var responseCallbacks = {};

    var uniqueId = 1;

    // setTimeOut(xxx, 0)
    var dispatchMessagesWithTimeoutSafety = true;

    // 注册一个 handler, native call js 用
    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }
    
    // js call native
    function callHandler(handlerName, data, responseCallback) {
        // 这个判断保证参数的正确性而已
        if (arguments.length == 2 && typeof data == 'function') {
            responseCallback = data;
            data = null;
        }
        _doSend({ handlerName: handlerName, data: data }, responseCallback);
    }

    function disableJavscriptAlertBoxSafetyTimeout() {
        dispatchMessagesWithTimeoutSafety = false;
    }
    
    function _fetchQueue() {
        var messageQueueString = JSON.stringify(sendMessageQueue);
        sendMessageQueue = [];
        return messageQueueString;
    }
    
    function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
    }

    // 这个对象是桥的核心-桥墩
    window.WebViewJavascriptBridge = {
        registerHandler: registerHandler,
        callHandler: callHandler,
        disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
        _fetchQueue: _fetchQueue, // 用这个方法拿到消息 js call native，发送假请求告诉 native 有消息来了，native 从这里取消息
        _handleMessageFromObjC: _handleMessageFromObjC
    };

    // 两种情况走这个方法 1. native call js  2.js call native 然后 native 走回调
    function _dispatchMessageFromObjC(messageJSON) {
        if (dispatchMessagesWithTimeoutSafety) {
            setTimeout(_doDispatchMessageFromObjC);
        } else {
            _doDispatchMessageFromObjC();
        }

        function _doDispatchMessageFromObjC() {
            var message = JSON.parse(messageJSON);
            var messageHandler;
            var responseCallback;
            
            // 如果是 native 走回调
            if (message.responseId) {
                responseCallback = responseCallbacks[message.responseId];
                if (!responseCallback) {
                    return;
                }
                responseCallback(message.responseData);
                delete responseCallbacks[message.responseId];
            } else {
                // 不是走回调的话，那就是 native call js 主动调用了
                // 如果有回调
                if (message.callbackId) {
                    var callbackResponseId = message.callbackId;
                    responseCallback = function(responseData) {
                        // 注意 responseId 这个键是 native call js 的回调 message 特有的
                        _doSend({ handlerName: message.handlerName, responseId: callbackResponseId, responseData: responseData });
                    };
                }
                var handler = messageHandlers[message.handlerName];
                if (!handler) {
                    console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
                } else {
                    handler(message.data, responseCallback);
                }
            }
        }
    }
    
    // js call native 核心方法
    function _doSend(message, responseCallback) {
        // 如果有回调，生成一个 id，这个 id 放到 message 中，回调放到 responseCallbacks 字典中
        // message 结构 { handlerName:  data:  callbackId: }
        if (responseCallback) {
            var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
            responseCallbacks[callbackId] = responseCallback;
            message['callbackId'] = callbackId;
        }
        // 把消息塞到队列(数组)里
        sendMessageQueue.push(message);
        // 通知 native: 有消息来啦...
        messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    }

    messagingIframe = document.createElement('iframe');
    messagingIframe.style.display = 'none';
    messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    document.documentElement.appendChild(messagingIframe);

    registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);

    // 下面的东西和 copy 到网页中初始化 bridge 的代码合起来看，就能明白在干啥了
    setTimeout(_callWVJBCallbacks, 0);

    function _callWVJBCallbacks() {
        var callbacks = window.WVJBCallbacks;
        delete window.WVJBCallbacks;
        for (var i = 0; i < callbacks.length; i++) {
            callbacks[i](WebViewJavascriptBridge);
        }
    }
})();
