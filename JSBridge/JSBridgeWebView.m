//
//  JSBridgeWebView.m
//  WKEasyJSWebView
//
//  Created by Jerod on  2020/12/21.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import "JSBridgeWebView.h"
#import "JSBridge.h"

@implementation JSBridgeWebView

/**
 初始化WKWwebView,并将交互类的方法注入JS
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration interfaces:(NSArray<Class>*)interfaces
{
    // 踢除已缓存的交互类
    NSMutableArray<Class> *interfacesArray = [NSMutableArray arrayWithArray:interfaces];
    [[JSBridge cacheDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull obj, BOOL * _Nonnull stop) {
        NSLog(@"%@ %@",key,obj);
        if (obj.count == 2) {
            Class objClass = [obj objectAtIndex:0];
            if (objClass && [interfacesArray containsObject:objClass]) {
                [interfacesArray removeObject:objClass];
            }
        }
    }];
    
    // 将新的交互类添加到缓存
    if (interfacesArray.count > 0) {
        [JSBridge cacheWithInterfaces:interfacesArray];        
    }
    
    // 注入桥接js
    if (!configuration) configuration = [[WKWebViewConfiguration alloc] init];
    if (!configuration.userContentController) configuration.userContentController = [[WKUserContentController alloc] init];
    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[JSBridge BRIDGE_SCRIPT] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    
    // 注入交互方法
    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[JSBridge cacheMethodsInjectString] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    
    
//    if (scripts) {
//        for (NSString* script in scripts) {
//            if (script) {
//                [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
//            }
//        }
//    }
    
//    if (interfaces) {
//        // 使用缓存可避免这段循环代码,加快执行速度
//        if (![JSBridge shared].cachedInterfaces) {
//            NSString * injectString = [[JSBridge shared] injectScriptWithInterfaces:interfaces];
//            [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:injectString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
//        }
//
//
//        // add message handler
//        JSBridgeListener *listener = [[JSBridgeListener alloc] init];
//        listener.javascriptInterfaces = [JSBridge shared].interfaces;
//        [configuration.userContentController addScriptMessageHandler:listener name:EASY_JS_MSG_HANDLER];
//    }
    
    // 监听js发送的信息
    JSBridgeListener *listener = [[JSBridgeListener alloc] init];
    listener.javascriptInterfaces = [JSBridge shared].interfaces;
    [configuration.userContentController addScriptMessageHandler:listener name:EASY_JS_MSG_HANDLER];
    
    self = [super initWithFrame:frame configuration:configuration];
    return self;
}

//- (WKWebViewConfiguration*)_handleConfiguration:(WKWebViewConfiguration*)configuration scripts:(NSArray<NSString*>*)scripts javascriptInterfaces:(NSArray<Class>*)interfaces {
//    if (!configuration) {
//        configuration = [[WKWebViewConfiguration alloc] init];
//    }
//    if (!configuration.userContentController) {
//        configuration.userContentController = [[WKUserContentController alloc] init];
//    }
//
//    // add script
//    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[JSBridge BRIDGE_SCRIPT] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
//
//    if (scripts) {
//        for (NSString* script in scripts) {
//            if (script) {
//                [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
//            }
//        }
//    }
//
//    if (interfaces) {
//        // 使用缓存可避免这段循环代码,加快执行速度
//        if (![JSBridge shared].cachedInterfaces) {
//            NSString * injectString = [[JSBridge shared] injectScriptWithInterfaces:interfaces];
//            [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:injectString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
//        }
//
//
//        // add message handler
//        JSBridgeListener *listener = [[JSBridgeListener alloc] init];
//        listener.javascriptInterfaces = [JSBridge shared].interfaces;
//        [configuration.userContentController addScriptMessageHandler:listener name:EASY_JS_MSG_HANDLER];
//    }
//
//    return configuration;
//}

- (void)main_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                if (completionHandler) {completionHandler(response, error);}
            }];
        });
    } else {
        [self evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {completionHandler(response, error);}
        }];
    }
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


@end
