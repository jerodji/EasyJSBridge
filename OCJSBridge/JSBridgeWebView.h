//
//  JSBridgeWebView.h
//  WKEasyJSWebView
//
//  Created by Jerod on  2020/12/21.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import <WebKit/WebKit.h>


@interface JSBridgeWebView : WKWebView

/// 初始化
/// @param frame 位置
/// @param configuration 配置
/// @param interfaces JS 交互类
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration interfaces:(NSDictionary<NSString*, NSObject*>*)interfaces;


/// native 调用 h5 方法
- (void)invokeJSFunction:(NSString*)jsFuncName params:(id)params completionHandler:(void (^)(id response, NSError *error))completionHandler;


/// 主线程执行js
- (void)main_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;


@end
