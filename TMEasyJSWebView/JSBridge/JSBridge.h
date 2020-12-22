//
//  JSBridge.h
//  WKEasyJSWebView
//
//  Created by Jerod on 2020/12/21.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "JSBridgeWebView.h"
#import <WebKit/WebKit.h>


#pragma mark - JSBridgeWebView

@interface JSBridgeWebView : WKWebView

- (instancetype)initUsingCacheWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration;

//- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration  javascriptInterfaces:(NSDictionary*)interfaces;


/// 初始化
/// @param frame 位置
/// @param configuration 配置
/// @param scripts js字符串
/// @param interfaces 没有缓存过的 JS 交互类
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration scripts:(NSArray<NSString*>*)scripts javascriptInterfaces:(NSArray*)interfaces;

/// 主线程执行js
- (void)main_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

/// native 调用 h5 方法
- (void)invokeJSFunction:(NSString*)jsFuncName params:(id)params completionHandler:(void (^)(id response, NSError *error))completionHandler;

@end



#pragma mark - JSBridge

@interface JSBridge : NSObject

@property (nonatomic, copy, readonly) NSString  *bridgeJS;

@property (nonatomic, copy, readonly) NSString  *cachedScripts;///< cache scripts
@property (nonatomic, copy, readonly) NSArray   *cachedInterfaces;///< cache interfaces

@property (nonatomic, copy, readonly) NSMutableDictionary *interfaces;

+ (instancetype)shared;

/// 建议缓存, 可提高 js 加载速度
- (void)cacheScriptsWithInterfaces:(NSArray<NSObject*>*)interfaces;

- (NSString*)injectScriptWithInterfaces:(NSArray<NSObject*>*)interfaces;

@end



#pragma mark - JSBridgeListener

@interface JSBridgeListener : NSObject<WKNavigationDelegate,WKScriptMessageHandler>
@property (nonatomic) NSDictionary *javascriptInterfaces;
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
