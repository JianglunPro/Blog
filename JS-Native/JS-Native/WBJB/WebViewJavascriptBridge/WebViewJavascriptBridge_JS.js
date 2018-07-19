;(function() {
    
    if (window.WebViewJavascriptBridge) {
        return;
    }
    if (!window.onerror) {
        window.onerror = function(msg, url, line) {
            console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
        }
    }
  
    // 专门用来发消息的 iframe
    var messagingIframe;
    // 消息队列，储存‘快速’‘连续’发送的消息实体，注意⚠️: 消息
    var sendMessageQueue = [];
    var messageHandlers = {};
    var CUSTOM_PROTOCOL_SCHEME = 'https';
    var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
    var responseCallbacks = {};
    var uniqueId = 1;
    var dispatchMessagesWithTimeoutSafety = true;

    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }
    
    function callHandler(handlerName, data, responseCallback) {
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
        _fetchQueue: _fetchQueue,
        _handleMessageFromObjC: _handleMessageFromObjC
    };


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
            
            if (message.responseId) {
                responseCallback = responseCallbacks[message.responseId];
                if (!responseCallback) {
                    return;
                }
                responseCallback(message.responseData);
                delete responseCallbacks[message.responseId];
            } else {
                if (message.callbackId) {
                    var callbackResponseId = message.callbackId;
                    responseCallback = function(responseData) {
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
    
    function _doSend(message, responseCallback) {
        if (responseCallback) {
            var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
            responseCallbacks[callbackId] = responseCallback;
            message['callbackId'] = callbackId;
        }
        sendMessageQueue.push(message);
        messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    }

    messagingIframe = document.createElement('iframe');
    messagingIframe.style.display = 'none';
    messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    document.documentElement.appendChild(messagingIframe);

    registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
    setTimeout(_callWVJBCallbacks, 0);

    function _callWVJBCallbacks() {
        var callbacks = window.WVJBCallbacks;
        delete window.WVJBCallbacks;
        for (var i = 0; i < callbacks.length; i++) {
            callbacks[i](WebViewJavascriptBridge);
        }
    }
})();