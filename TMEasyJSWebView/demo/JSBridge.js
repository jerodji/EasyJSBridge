!function () {
    if (window.YBJSBridge) {
        return;
    }
    window.YBJSBridge = {
        msgCallbackMap: {},
        eventCallMap: {},
        // call
        invoke: function (action, params, callback) {
            var msgBody = {};
            msgBody.action = action;
            msgBody.params = params;
            if (callback && typeof (callback) === 'function') {
                var callbackId = "__ybcb" + (+new Date) + Math.random();
                this.msgCallbackMap[callbackId] = callback;
                msgBody.callbackId = callbackId;
            }
            window.webkit.messageHandlers.YBLinkingListener.postMessage(msgBody);
        },

        // invokeCallback
        invokeCallback: function (callbackId, resultjson) {
            var callback = this.msgCallbackMap[callbackId];
            if (callback && typeof (callback) === 'function') {
                var resultObj = resultjson ? JSON.parse(resultjson) : {};
                callback(resultObj);
            }
        },
        on: function (eventName, handler) {
            if (handler !== undefined) {
                this.eventCallMap[eventName] = handler;
            }
        },
        eventDispatcher: function (eventName, resultjson) {
            var handler = this.eventCallMap[eventName];
            if (handler && typeof (handler) === 'function') {
                var resultObj = resultjson ? JSON.parse(resultjson) : {};
                var returnData = handler(resultObj);
                return returnData;
            }
        }
    };
    var event = window.document.createEvent('Events');
    event.initEvent('YBJSBridgeReady');
    event.bridge = YBJSBridge;
    window.document.dispatchEvent(event);
}()