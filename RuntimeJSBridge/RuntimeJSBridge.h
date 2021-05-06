//
//  JSBridge.h
//  WKEasyJSWebView
//
//  Created by Jerod on 2019/8/13.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKWebView+RuntimeJSBridge.h"


extern NSString * const BRIDGE_JS_FORMAT;


#pragma mark - JSBridgeListener

@interface JSBridgeListener : NSObject<WKNavigationDelegate,WKScriptMessageHandler>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary<NSString*, NSObject*> *interfaces;
@end



#pragma mark - JSBridgeDataFunction

@interface JSBridgeDataFunction : NSObject

@property (nonatomic, copy) NSString* funcID;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL removeAfterExecute;

- (instancetype)initWithWebView:(WKWebView*)webView;

// 回调JS
- (void)callbackJS:(void (^)(id response, NSError* error))completionHandler;
- (void)callbackJSWithParam:(NSString *)param completionHandler:(void (^)(id response, NSError* error))completionHandler;
- (void)callbackJSWithParams:(NSArray *)params completionHandler:(void (^)(id response, NSError* error))completionHandler;

@end
