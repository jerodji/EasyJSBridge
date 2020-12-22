//
//  JSBridge.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2020/12/21.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import "JSBridge.h"
#import <objc/runtime.h>
#import "MJExtension.h"


static NSString * const EASY_JS_MSG_HANDLER = @"NativeListener";


#pragma mark - JSBridgeWebView

@implementation JSBridgeWebView

/**
 初始化WKWwebView,并将交互类的方法注入JS
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration scripts:(NSArray<NSString*>*)scripts javascriptInterfaces:(NSDictionary*)interfaces
{
    //待添加缓存数据
    
    WKWebViewConfiguration *cofig =  [self handleConfiguration:[[WKWebViewConfiguration alloc] init] scripts:scripts javascriptInterfaces:interfaces];
    self = [super initWithFrame:frame configuration:cofig];
    return self;
}

- (instancetype)initUsingCacheWithFrame:(CGRect)frame
{
    if (![JSBridge shared].cachedInterfaces) {
        NSAssert(NO, @"*** cachedInterfaces不存在");
        return nil;
    }
    if (![JSBridge shared].cachedScripts) {
        NSAssert(NO, @"*** cachedScripts不存在");
        return nil;
    }
    WKWebViewConfiguration *cofig =  [self handleConfiguration:[[WKWebViewConfiguration alloc] init] scripts:@[[JSBridge shared].cachedScripts] javascriptInterfaces:[JSBridge shared].cachedInterfaces];
    self = [super initWithFrame:frame configuration:cofig];
    return self;
}

- (WKWebViewConfiguration*)handleConfiguration:(WKWebViewConfiguration*)configuration scripts:(NSArray<NSString*>*)scripts javascriptInterfaces:(NSDictionary*)interfaces {
    if (!configuration) {
        configuration = [[WKWebViewConfiguration alloc] init];
    }
    if (!configuration.userContentController) {
        configuration.userContentController = [[WKUserContentController alloc] init];
    }
    
    // add script
    [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[JSBridge shared].injectedJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    
    for (NSString* script in scripts) {
        [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    }
    
    // 使用缓存可避免这段循环代码,加快执行速度
    if (interfaces && ![JSBridge shared].cachedScripts) {
        
        NSMutableString* injectString = [[NSMutableString alloc] init];
        for(NSString *key in [interfaces allKeys]) {
            [injectString appendString:@"JSBridge._inject(\""];
            [injectString appendString:key];
            [injectString appendString:@"\", ["];
            NSObject* interfaceObj = [interfaces objectForKey:key];
            if ([interfaceObj isKindOfClass:[NSObject class]]) {
                Class cls = object_getClass(interfaceObj);
                while (cls != [NSObject class]) {
                    unsigned int mc = 0;
                    Method * mlist = class_copyMethodList(cls, &mc);
                    for (int i = 0; i < mc; i++) {
                        [injectString appendString:@"\""];
                        [injectString appendString:[NSString stringWithUTF8String:sel_getName(method_getName(mlist[i]))]];
                        [injectString appendString:@"\""];
                        if ((i != mc - 1) || (cls.superclass != [NSObject class])) {
                            [injectString appendString:@", "];
                        }
                    }
                    free(mlist);
                    cls = cls.superclass;
                }
            }
            [injectString appendString:@"]);"]; //@"JSBridge._inject(\"native\", [\"testWithParams:callback:\"]);"
        }
#ifdef DEBUG
        NSLog(@"injectString :\n%@", injectString);
#endif
        [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:injectString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    }
    
    // add message handler
    JSBridgeListener *listener = [[JSBridgeListener alloc] init];
    listener.javascriptInterfaces = interfaces;
    [configuration.userContentController addScriptMessageHandler:listener name:EASY_JS_MSG_HANDLER];
    
    return configuration;
}

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



#pragma mark - JSBridge

@implementation JSBridge

+ (instancetype)shared {
    static JSBridge * b = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        b = [[super allocWithZone:nil] init];
        [b loadInjectScript];
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

@synthesize injectedJS = _injectedJS;
@synthesize cachedScripts = _cachedScripts;
@synthesize cachedInterfaces = _cachedInterfaces;


- (void)loadInjectScript {
    if (!_injectedJS) {
        NSError *error;
        NSString * path = [[NSBundle mainBundle] pathForResource:@"JSBridge" ofType:@"js"];
        NSString * injectjs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (!error && injectjs.length > 0) {
            _injectedJS = injectjs;
        } else {
            NSAssert(NO, @"*** JSBridge.js读取错误");
        }
    }
}

- (void)cacheScriptsWithInterfaces:(NSDictionary*)interfaces
{
    [self loadInjectScript];
    
    if (interfaces && [interfaces isKindOfClass:[NSDictionary class]])
    {
        _cachedInterfaces = interfaces;
        NSMutableString* injectString = [[NSMutableString alloc] init];
        for(NSString *key in [interfaces allKeys]) {
            [injectString appendString:@"JSBridge._inject(\""];
            [injectString appendString:key];
            [injectString appendString:@"\", ["];
            NSObject* interfaceObj = [interfaces objectForKey:key];
            if ([interfaceObj isKindOfClass:[NSObject class]]) {
                Class cls = object_getClass(interfaceObj);
                while (cls != [NSObject class]) {
                    unsigned int mc = 0;
                    Method * mlist = class_copyMethodList(cls, &mc);
                    for (int i = 0; i < mc; i++) {
                        [injectString appendString:@"\""];
                        [injectString appendString:[NSString stringWithUTF8String:sel_getName(method_getName(mlist[i]))]];
                        [injectString appendString:@"\""];
                        if ((i != mc - 1) || (cls.superclass != [NSObject class])) {
                            [injectString appendString:@", "];
                        }
                    }
                    free(mlist);
                    cls = cls.superclass;
                }
            }
            [injectString appendString:@"]);"]; //@"JSBridge._inject(\"native\", [\"testWithParams:callback:\"]);"
        }
        _cachedScripts = injectString;
    }
    else
    {
        NSAssert(NO, @"*** interfaces无效");
    }
}

@end



#pragma mark - JSBridgeListener

@implementation JSBridgeListener

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSMutableArray <JSBridgeDataFunction *>* _funcs = [NSMutableArray new];
    NSMutableArray <NSString *>* _args = [NSMutableArray new];
    
    if ([message.name isEqualToString:EASY_JS_MSG_HANDLER]) {
        __weak JSBridgeWebView *webView = (JSBridgeWebView *)message.webView;
        NSString *requestString = [message body];
        // native:testWithParams%3Acallback%3A:s%3Aabc%3Af%3A__cb1577786915804
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        //NSLog(@"req: %@", requestString);
        
        NSString* obj = (NSString*)[components objectAtIndex:0];
        NSString* method = [(NSString*)[components objectAtIndex:1] stringByRemovingPercentEncoding];
        NSObject* interface = [self.javascriptInterfaces objectForKey:obj];
        
        // execute the interfacing method
        SEL selector = NSSelectorFromString(method);
        NSMethodSignature* sig = [interface methodSignatureForSelector:selector];
        if (sig.numberOfArguments == 2 && components.count > 2) {
            // 方法签名获取到实际实现的方法无参数 && js调用的方法带参数
            NSString *assertDesc = [NSString stringWithFormat:@"*** -[%@ %@]: %@",NSStringFromClass([interface class]),method,@"oc的交互方法不带参数，但是js调用的方法传了参数"];
            //  因为pod报警告，所以加上这句，实际没有意义
            assertDesc = assertDesc ? : @"";
            NSAssert(NO, assertDesc);
            return;
        }
        if (!sig) {
            NSString *assertDesc = [NSString stringWithFormat:@"*** -[%@ %@]:%@",NSStringFromClass([interface class]),method,@"method signature argument cannot be nil"];
            NSAssert(NO, assertDesc);
            return;
        }
        if (![interface respondsToSelector:selector]) {
            NSAssert(NO, @"该方法未实现");
            return;
        }
        
        NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
        invoker.selector = selector;
        invoker.target = interface;
        if ([components count] > 2)
        {
            NSString *argsAsString = [(NSString*)[components objectAtIndex:2] stringByRemovingPercentEncoding];
            NSArray* formattedArgs = [argsAsString componentsSeparatedByString:@":"];
            if ((sig.numberOfArguments - 2) != [formattedArgs count] / 2) {
                // 方法签名获取到实际实现的方法的参数个数 ≠ js调用方法时传参个数
                NSString *assertDesc = [NSString stringWithFormat:@"*** -[%@ %@]: OC的交互方法参数个数%@，js调用方法时传参个数%@",NSStringFromClass([interface class]),method,@(sig.numberOfArguments - 2),@([formattedArgs count] / 2)];
                assertDesc = assertDesc ? : @"";
                NSAssert(NO, assertDesc);
                return;
            }
            
            for (unsigned long i = 0, j = 0, l = [formattedArgs count]; i < l; i+=2, j++){
                
                NSString* type = ((NSString*) [formattedArgs objectAtIndex:i]);
                NSString* argStr = ((NSString*) [formattedArgs objectAtIndex:i + 1]);
                
                if ([type isEqualToString:@"func"]) {
                    
                    JSBridgeDataFunction *func = [[JSBridgeDataFunction alloc] initWithWebView:webView];
                    func.funcID = argStr;
                    [_funcs addObject:func];
                    [invoker setArgument:&func atIndex:(j + 2)];
                
                } else if ([type isEqualToString:@"arg"]) {
                    
                    NSString* arg = [argStr stringByRemovingPercentEncoding];
                    [_args addObject:arg];
                    [invoker setArgument:&arg atIndex:(j + 2)];
                }
            }
        }
        [invoker retainArguments];
        [invoker invoke];
        
        //return the value by using javascript
        if ([sig methodReturnLength] > 0) {
            __unsafe_unretained NSString* tmpRetValue;
            [invoker getReturnValue:&tmpRetValue];
            NSString *retValue = tmpRetValue;
            
            if (retValue == NULL || retValue == nil) {
                [webView main_evaluateJavaScript:@"JSBridge.retValue=null;" completionHandler:nil];
            } else {
                retValue = [retValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet letterCharacterSet]];
                retValue = [@"" stringByAppendingFormat:@"JSBridge.retValue=\"%@\";", retValue];
                [webView main_evaluateJavaScript:retValue completionHandler:nil];
            }
        }
    }
    
    //clean up any retained funcs/args
    [_funcs removeAllObjects];
    [_args removeAllObjects];
    
}

@end

#pragma mark - JSBridgeDataFunction

@implementation JSBridgeDataFunction

- (instancetype)initWithWebView:(JSBridgeWebView *)webView {
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
        [_webView main_evaluateJavaScript:injection completionHandler:^(id response, NSError *error) {
            if (completionHandler) {completionHandler(response, error);}
        }];
    }
}


@end
