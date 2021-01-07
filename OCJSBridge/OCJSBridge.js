!function () {
    if (window.JSBridge) {
        return;
    }
    window.JSBridge = {
        __callbacks: {},
        __events: {},
        call: function (api = '', param = '', callback) {
            let formatArgs = [api, param];
            if (callback && typeof callback === 'function') {
                const cbID = '__cb' + (+new Date) + Math.random();
                JSBridge.__callbacks[cbID] = callback;
                formatArgs.push(cbID);
            } else {
                formatArgs.push('');
            }
            const msg = JSON.stringify(formatArgs);
            window.webkit.messageHandlers.NativeListener.postMessage(msg);
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
        _invokeJS: function (funcName, paramsJson) {
            let handler = JSBridge.__events[funcName];
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
                console.log(funcName + '函数未定义');
            }
        }
    };
}()
