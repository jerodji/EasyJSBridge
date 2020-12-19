!function () {
    if (window.EasyJS) {
        return;
    }
    window.EasyJS = {
        __callbacks: {},
        __events: {},
        mount: function (funcName, handler) {
            EasyJS.__events[funcName] = handler;
        },
        invokeJS: function (funcID, paramsJson) {
            let handler = EasyJS.__events[funcID];
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
        },
        invokeCallback: function (cbID, removeAfterExecute) {
            let args = Array.prototype.slice.call(arguments);
            args.shift();
            args.shift();
            for (let i = 0, l = args.length; i < l; i++) {
                args[i] = decodeURIComponent(args[i]);
            }
            let cb = EasyJS.__callbacks[cbID];
            if (removeAfterExecute) {
                EasyJS.__callbacks[cbID] = undefined;
            }
            return cb.apply(null, args);
        },
        call: function (obj, functionName, args) {
            let formattedArgs = [];
            for (let i = 0, l = args.length; i < l; i++) {
                if (typeof args[i] == 'function') {
                    formattedArgs.push('f');
                    let cbID = '__cb' + (+new Date) + Math.random();
                    EasyJS.__callbacks[cbID] = args[i];
                    formattedArgs.push(cbID);
                } else {
                    formattedArgs.push('s');
                    formattedArgs.push(encodeURIComponent(args[i]));
                }
            }
            let argStr = (formattedArgs.length > 0 ? ':' + encodeURIComponent(formattedArgs.join(':')) : '');
            window.webkit.messageHandlers.NativeListener.postMessage(obj + ':' + encodeURIComponent(functionName) + argStr);
            let ret = EasyJS.retValue;
            EasyJS.retValue = undefined;
            if (ret) {
                return decodeURIComponent(ret);
            }
        },
        inject: function (obj, methods) {
            window[obj] = {};
            let jsObj = window[obj];
            for (let i = 0, l = methods.length; i < l; i++) {
                (function () {
                    let method = methods[i];
                    let jsMethod = method.replace(new RegExp(':', 'g'), '');
                    jsObj[jsMethod] = function () {
                        return EasyJS.call(obj, method, Array.prototype.slice.call(arguments));
                    };
                })();
            }
        }
    };
}()
