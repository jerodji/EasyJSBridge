!function () {
    if (window.JSBridge) {
        return;
    }
    window.JSBridge = {
        /**
         * 存放JS的回调函数
         */
        __callbacks: {},

        /**
         * 存放JS注册给native的方法
         */
        __events: {},

        /**
         * JS执行此方法,将JS函数挂载到__events供原生调用
         * @param {String} funcName js方法名
         * @param {Function} handler js方法
         */
        registor: function (funcName, handler) {
            JSBridge.__events[funcName] = handler;
        },

        /**
         * 原生执行此方法 调用JS函数
         * @param {String} funcID js方法名
         * @param {JSON} paramsJson 参数
         */
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
        },

        /**
         * native通过此方法执行JS回调函数
         * @param {String} cbID 函数ID
         * @param {Boolean} removeAfterExecute 执行后是否从__callbacks中否移除此回调函数
         */
        _invokeCallback: function (cbID, removeAfterExecute) {
            let args = Array.prototype.slice.call(arguments);
            args.shift(); // __cb1577786915804
            args.shift(); // false

            for (let i = 0, l = args.length; i < l; i++) {
                args[i] = decodeURIComponent(args[i]);
            }

            let cb = JSBridge.__callbacks[cbID];
            if (removeAfterExecute) {
                JSBridge.__callbacks[cbID] = undefined;
            }
            return cb.apply(null, args);
        },

        /**
         * 调用原生obj对象的方法
         * @param {String} obj 
         * @param {String} functionName 
         * @param {Array} args 
         */
        _call: function (obj, functionName, args) {
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
            /** NativeListener 要与原生中addScriptMessageHandler的name保持一致 */
            window.webkit.messageHandlers.NativeListener.postMessage(obj + ':' + encodeURIComponent(functionName) + argStr);

            let ret = JSBridge.retValue;
            JSBridge.retValue = undefined;

            if (ret) {
                return decodeURIComponent(ret);
            }
        },

        /**
         * native用来给window添加obj的对象与方法
         * @param {String} obj 添加到window上的对象
         * @param {Array<String>} methods 添加到obj上的方法数组
         * "JSBridge._inject(\"native\", [\"testWithParams:callback:\"]);"
         */
        _inject: function (obj, methods) {
            for (let i = 0 , l = methods.length; i < l; i++) {
                let method = methods[i];
                let jsMethod = method.replace(new RegExp(':', 'g'), '');
                JSBridge[jsMethod] = function () {
                    return JSBridge._call(obj, method, Array.prototype.slice.call(arguments));
                };
            }
        }
        
    };
}()
