//
//  WKWebView+RuntimeJSBridge.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2019/8/13.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import "WKWebView+RuntimeJSBridge.h"
#import "RuntimeJSBridge.h"
#import "NSObject+JsonString.h"

@implementation WKWebView (EasyJSBridge)

/**
 初始化WKWwebView,并将交互类的方法注入JS
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration listenerName:(NSString*)listenerName services:(NSDictionary<NSString*, NSObject*>*)interfaces
{
    if (!configuration) configuration = [[WKWebViewConfiguration alloc] init];
    if (!configuration.userContentController) configuration.userContentController = [[WKUserContentController alloc] init];
    
    // 注入桥接js
    NSString * BridgeJS = [NSString stringWithFormat:BRIDGE_JS_FORMAT, listenerName];
    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:BridgeJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    
    // 添加js发送信息监听者
    JSBridgeListener *listener = [[JSBridgeListener alloc] init];
    listener.interfaces = interfaces;
    listener.name = listenerName;
    [configuration.userContentController addScriptMessageHandler:listener name:listenerName];
    
    self = [self initWithFrame:frame configuration:configuration];
    return self;
}


- (void)invokeJSFunction:(NSString*)jsFuncName params:(id)params completionHandler:(void (^)(id response, NSError *error))completionHandler {
    
    NSString *paramJson = @"";
    if (params) {  paramJson = [params JSONString]; }
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString *script = [NSString stringWithFormat:@"%@('%@', '%@')", @"window.JSBridge._invokeJS", jsFuncName,  paramJson];
    [self mainThreadEvaluateJavaScript:script completionHandler:completionHandler];
}


- (void)mainThreadEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    
    if ([NSThread isMainThread]) {
        [self evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {completionHandler(response, error);}
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                if (completionHandler) {completionHandler(response, error);}
            }];
        });
    }
}


@end
