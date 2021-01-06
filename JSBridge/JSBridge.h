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

@interface JSBridge : NSObject

/// 本地 js 桥接脚本
+ (NSString*)BRIDGE_SCRIPT;

/// 缓存交互类与方法
+ (NSMutableDictionary<NSString*, NSArray*>*)cacheDictionary;

+ (NSString*)cacheMethodsInjectString;

/// 建议缓存, 可提高 js 加载速度
+ (void)cacheWithInterfaces:(NSArray<Class>*)interfaces;

@end



#pragma mark - JSBridgeListener

@interface JSBridgeListener : NSObject<WKNavigationDelegate,WKScriptMessageHandler>
@property (nonatomic) NSDictionary<NSString*, NSObject*> *javascriptInterfaces;
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
