//
//  JSBridge.h
//  WKEasyJSWebView
//
//  Created by Jerod on 2020/12/21.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSBridgeWebView.h"

static NSString * const EASY_JS_MSG_HANDLER = @"NativeListener";


#pragma mark - JSBridge

@interface OCJSBridge : NSObject

+ (instancetype)shared;

/**
 存放本地 js 脚本
 */
@property (nonatomic, copy) NSString  *bridgeJS;

/**
 缓存交互类与方法, 以下面的结构组装数据
 
 {
    "className0" : [class, "JSBridge._inject(\"NativeMethods\", [\"testWithParams:callback:\", \"log:\"]);"],
    "className1" : [class, "JSBridge._inject(\"NativeMethods\", [\"testWithParams:callback:\", \"log:\"]);"]
 }
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSArray*> *cacheMap;

/**
 交互方法 js string
 */
@property (nonatomic, copy) NSMutableString *methodsInjectString;

/**
 建议缓存, 可提高 js 加载速度
 */
- (void)cacheWithInterfaces:(NSArray<Class>*)interfaces;

@end



#pragma mark - JSBridgeListener

@interface JSBridgeListener : NSObject<WKNavigationDelegate,WKScriptMessageHandler>
@property (nonatomic) NSDictionary<NSString*, NSArray*> *interfaces;
@end



#pragma mark - JSBridgeDataFunction

@interface JSBridgeDataFunction : NSObject

@property (nonatomic, copy) NSString* funcID;
@property (nonatomic, strong) JSBridgeWebView *webView;
@property (nonatomic, assign) BOOL removeAfterExecute;

- (instancetype)initWithWebView:(JSBridgeWebView*)webView;

// 回调JS
- (void)execute:(void (^)(id response, NSError* error))completionHandler;
- (void)executeWithParam:(NSString *)param completionHandler:(void (^)(id response, NSError* error))completionHandler;
- (void)executeWithParams:(NSArray *)params completionHandler:(void (^)(id response, NSError* error))completionHandler;

@end
