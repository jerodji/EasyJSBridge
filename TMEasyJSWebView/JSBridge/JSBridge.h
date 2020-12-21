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

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration scripts:(NSArray<NSString*>*)scripts javascriptInterfaces:(NSDictionary*)interfaces;

/// 主线程执行js
- (void)main_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

/// native 调用 h5 方法
- (void)invokeJSFunction:(NSString*)jsFuncName params:(id)params completionHandler:(void (^)(id response, NSError *error))completionHandler;

@end



#pragma mark - JSBridge

@interface JSBridge : NSObject

@property (nonatomic, copy, readonly) NSString *cachedScripts;///< cache scripts
@property (nonatomic, copy, readonly) NSDictionary *cachedInterfaces;///< cache interfaces

+ (instancetype)shared;
- (void)cacheScriptsWithInterfaces:(NSDictionary*)interfaces;

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
