!function () {
    if (window.JSBridge) {
        return;
    }
    window.JSBridge = {
        __callbacks: {},
        __events: {},
        __nativeObject: {},
        _inject: function (obj, methods) {
            for (let i = 0 , l = methods.length; i < l; i++) {
                let method = methods[i];
                let jsMethod = method.replace(new RegExp(':', 'g'), '');
                JSBridge[jsMethod] = function () {
                    return JSBridge._postMessage(obj, method, Array.prototype.slice.call(arguments));
                };
            }
        },
        _injectNativeObject: function (objs) {
            JSBridge.__nativeObject = objs;
        },
        _postMessage: function (obj, functionName, args) {
            let formattedArgs = [];
            for (let i = 0, l = args.length; i < l; i++) {
                if (typeof args[i] == 'function') {
                    formattedArgs.push('func');
                    let cbID = '__cb' + (+new Date) + Math.random();
                    JSBridge.__callbacks[cbID] = args[i];
                    formattedArgs.push(cbID);
                } else {
                    formattedArgs.push('arg');
                    formattedArgs.push(encodeURIComponent(args[i]));
                }
            }
            let argStr = (formattedArgs.length > 0 ? ':' + encodeURIComponent(formattedArgs.join(':')) : '');
            window.webkit.messageHandlers.NativeListener.postMessage(obj + ':' + encodeURIComponent(functionName) + argStr);

            let ret = JSBridge.retValue;
            JSBridge.retValue = undefined;

            if (ret) {
                return decodeURIComponent(ret);
            }
        },
        call: function (methodName, callback) {
            let obj = JSBridge.__nativeObject;
            if (obj && typeof (obj) === 'object') {
                JSBridge._postMessage(obj, methodName, callback);
            }
        },
        _invokeCallback: function (cbID, removeAfterExecute) {
            let args = Array.prototype.slice.call(arguments);
            args.shift();
            args.shift();

            for (let i = 0, l = args.length; i < l; i++) {
                args[i] = decodeURIComponent(args[i]);
            }

            let cb = JSBridge.__callbacks[cbID];
            if (removeAfterExecute) {
                JSBridge.__callbacks[cbID] = undefined;
            }
            return cb.apply(null, args);
        },
        registor: function (funcName, handler) {
            JSBridge.__events[funcName] = handler;
        },
        _invokeJS: function (funcID, paramsJson) {
            let handler = JSBridge.__events[funcID];
            if (handler && typeof (handler) === 'function') {
                let args = '';
                try {
                    if (typeof JSON.parse(paramsJson) == 'object') {
                        args = JSON.parse(paramsJson);
                    } else {
                        args = paramsJson;
                    }
                    return handler(args);
                } catch (error) {
                    console.log(error);
                    args = paramsJson;
                    return handler(args);
                }
            } else {
                console.log(funcID + '函数未定义');
            }
        }
    };
}()
