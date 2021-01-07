//
//  JSBridgeWebView.m
//  WKEasyJSWebView
//
//  Created by Jerod on  2020/12/21.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import "JSBridgeWebView.h"
#import "OCJSBridge.h"
#import "NSObject+MJKeyValue.h"

@implementation JSBridgeWebView

/**
 初始化WKWwebView,并将交互类的方法注入JS
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration interfaces:(NSDictionary<NSString*, NSObject*>*)interfaces
{
    // 注入桥接js
    if (!configuration) configuration = [[WKWebViewConfiguration alloc] init];
    if (!configuration.userContentController) configuration.userContentController = [[WKUserContentController alloc] init];
    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[OCJSBridge shared].bridgeJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
        
    // 添加js发送信息监听者
    JSBridgeListener *listener = [[JSBridgeListener alloc] init];
    listener.interfaces = interfaces;
    [configuration.userContentController addScriptMessageHandler:listener name:EASY_JS_MSG_HANDLER];
    
    
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
    }
    return self;
}


- (void)invokeJSFunction:(NSString*)jsFuncName params:(id)params completionHandler:(void (^)(id response, NSError *error))completionHandler {
    
    NSString *paramJson = @"";
    if (params) {  paramJson = [params mj_JSONString]; }
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
     paramJson = [paramJson stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString *script = [NSString stringWithFormat:@"%@('%@', '%@')", @"window.JSBridge._invokeJS", jsFuncName,  paramJson];
    [self main_evaluateJavaScript:script completionHandler:completionHandler];
}


- (void)main_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    
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
