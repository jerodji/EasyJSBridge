//
//  JSBridge.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2020/12/21.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import "OCJSBridge.h"
#import <objc/message.h>
#import "NSObject+MJKeyValue.h"

#pragma mark - JSBridge

@interface OCJSBridge()

@end

@implementation OCJSBridge

+ (instancetype)shared {
    static OCJSBridge * b = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        b = [[super allocWithZone:nil] init];
        [b loadBridgeJS];
    });
    return b;
}
+(id)allocWithZone:(NSZone *)zone{
    return [self shared];
}
-(id)copyWithZone:(NSZone *)zone{
    return [[self class] shared];
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [[self class] shared];
}

- (void)loadBridgeJS {
    if (!_bridgeJS) {
        NSError *error;
        NSString * path = [[NSBundle mainBundle] pathForResource:@"OCJSBridge" ofType:@"js"];
        NSString * injectjs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (!error && injectjs.length > 0) {
            _bridgeJS = injectjs;
        } else {
            NSAssert(NO, @"*** OCJSBridge.js读取错误");
        }
    }
}

@end



#pragma mark - JSBridgeListener

@implementation JSBridgeListener

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (![message.name isEqualToString:EASY_JS_MSG_HANDLER]) return;
    
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

- (void)execute:(void (^)(id response, NSError *error))completionHandler {
    [self executeWithParam:nil completionHandler:^(id response, NSError *error) {
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
}

- (void)executeWithParam:(NSString *)param completionHandler:(void (^)(id response, NSError *error))completionHandler {
    [self executeWithParams:param ? @[param] : nil completionHandler:^(id response, NSError *error) {
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
}

- (void)executeWithParams:(NSArray *)params completionHandler:(void (^)(id response, NSError *error))completionHandler {
    
    NSMutableArray * args = [NSMutableArray arrayWithArray:params];
    for (int i=0; i<params.count; i++) {
        NSString* json = [params[i] mj_JSONString];
        [args replaceObjectAtIndex:i withObject:json];
    }
    
    NSMutableString* injection = [[NSMutableString alloc] init];
    [injection appendFormat:@"JSBridge._invokeCallback(\"%@\", %@", self.funcID, self.removeAfterExecute ? @"true" : @"false"];
    
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
