//
//  JSBridge.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2019/8/13.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import "RuntimeJSBridge.h"
#import <objc/message.h>
#import "NSObject+JsonString.h"


// MARK: bridge.js
NSString * const BRIDGE_JS_FORMAT = @"\
!function () {\
if (window.JSBridge) {\
    return;\
}\
window.JSBridge = {\
    __callbacks: {},\
    __events: {},\
    call: function (api = '', param = '', callback) {\
        let formatArgs = [api, param];\
        if (callback && typeof callback === 'function') {\
            const cbID = '__cb' + (+new Date) + Math.random();\
            JSBridge.__callbacks[cbID] = callback;\
            formatArgs.push(cbID);\
        } else {\
            formatArgs.push('');\
        }\
        const msg = JSON.stringify(formatArgs);\
        window.webkit.messageHandlers.%@.postMessage(msg);\
    },\
    _callback: function (cbID, removeAfterExecute) {\
        let args = Array.prototype.slice.call(arguments);\
        args.shift();\
        args.shift();\
        for (let i = 0, l = args.length; i < l; i++) {\
            args[i] = decodeURIComponent(args[i]);\
        }\
        let cb = JSBridge.__callbacks[cbID];\
        if (removeAfterExecute) {\
            JSBridge.__callbacks[cbID] = undefined;\
        }\
        return cb.apply(null, args);\
    },\
    registor: function (funcName, handler) {\
        JSBridge.__events[funcName] = handler;\
    },\
    _invokeJS: function (funcName, paramsJson) {\
        let handler = JSBridge.__events[funcName];\
        if (handler && typeof (handler) === 'function') {\
            let args = '';\
            try {\
                if (typeof JSON.parse(paramsJson) == 'object') {\
                    args = JSON.parse(paramsJson);\
                } else {\
                    args = paramsJson;\
                }\
                return handler(args);\
            } catch (error) {\
                console.log(error);\
                args = paramsJson;\
                return handler(args);\
            }\
        } else {\
            console.log(funcName + '函数未定义');\
        }\
    }\
};\
}()\
";


#pragma mark - JSBridgeListener

@implementation JSBridgeListener

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (![message.name isEqualToString:self.name]) return;
    
    __weak WKWebView *webView = (WKWebView *)message.webView;
    NSString *bodyJson = message.body; // exg: "[\"testService/testWithParams:callback:\",\"abc\",\"__cb16100015743360.8558109851298374\"]"
    NSData *bodyData = [bodyJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSArray *bodyArr = [NSJSONSerialization JSONObjectWithData:bodyData options:kNilOptions error:&err];
    if (err) {
        return;
    }
    if (bodyArr.count < 3 ) {
        NSAssert(NO, @"*** 传参不符合约定");
        return;
    }
    
    NSString * api  = [bodyArr objectAtIndex:0];
    NSArray * apiArr = [api componentsSeparatedByString:@"/"];
    if (apiArr.count != 2) {
        NSAssert(NO, @"*** 传参不符合约定");
        return;
    }
    NSString * service  = [apiArr objectAtIndex:0];
    NSString * method   = [apiArr objectAtIndex:1];
    NSString * args = [bodyArr objectAtIndex:1];
    NSString * cbID = [bodyArr objectAtIndex:2];
    JSBridgeDataFunction *func = [[JSBridgeDataFunction alloc] initWithWebView:webView];
    func.funcID = cbID;
    
    if (!self.interfaces) {
        return;
    }
    
    NSObject * obj = [self.interfaces objectForKey:service];
    if (!obj || ![obj isKindOfClass:[NSObject class]]) {
        return;
    }
    
    SEL sel = NSSelectorFromString(method);
    
    NSString * method1 = [method stringByAppendingString:@":"];
    SEL sel1 = NSSelectorFromString(method1);
    
    NSString * method2 = [method stringByAppendingString:@"::"];
    SEL sel2 = NSSelectorFromString(method2);
    
    SEL selector = sel;
    if ([obj respondsToSelector:sel]) {
        selector = sel;
    } else if ([obj respondsToSelector:sel1]) {
        selector = sel1;
    } else if ([obj respondsToSelector:sel2]) {
        selector = sel2;
    } else {
        NSString *msg = [NSString stringWithFormat:@"*** %@ %@ 方法没有实现", NSStringFromClass([obj class]), method];
        NSAssert(NO, msg);
        return;
    }
    
    ((void(*)(id, SEL, id, id))objc_msgSend)(obj, selector, args, func);
}

@end

#pragma mark - JSBridgeDataFunction

@implementation JSBridgeDataFunction

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
    }
    return self;
}

- (void)callbackJS:(void (^)(id response, NSError *error))completionHandler {
    [self callbackJSWithParam:nil completionHandler:^(id response, NSError *error) {
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
}

- (void)callbackJSWithParam:(NSString *)param completionHandler:(void (^)(id response, NSError *error))completionHandler {
    [self callbackJSWithParams:param ? @[param] : nil completionHandler:^(id response, NSError *error) {
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
}

- (void)callbackJSWithParams:(NSArray *)params completionHandler:(void (^)(id response, NSError *error))completionHandler {
    
    NSMutableArray * args = [NSMutableArray arrayWithArray:params];
    for (int i=0; i<params.count; i++) {
        NSString* json = [params[i] JSONString];
        [args replaceObjectAtIndex:i withObject:json];
    }
    
    NSMutableString* injection = [[NSMutableString alloc] init];
    [injection appendFormat:@"JSBridge._callback(\"%@\", %@", self.funcID, self.removeAfterExecute ? @"true" : @"false"];
    
    if (args) {
        for (unsigned long i = 0, l = args.count; i < l; i++){
            NSString* arg = [args objectAtIndex:i];
            NSCharacterSet *chars = [NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"];
            NSString *encodedArg = [arg stringByAddingPercentEncodingWithAllowedCharacters:chars];
            [injection appendFormat:@", \"%@\"", encodedArg];
        }
    }
    
    [injection appendString:@");"];
    
    if (_webView){
        [_webView mainThreadEvaluateJavaScript:injection completionHandler:^(id response, NSError *error) {
            if (completionHandler) {completionHandler(response, error);}
        }];
    }
}


@end
