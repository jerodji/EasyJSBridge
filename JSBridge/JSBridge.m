//
//  JSBridge.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2020/12/21.
//  Copyright © 2020 JIJIUDONG. All rights reserved.
//

#import "JSBridge.h"
#import <objc/runtime.h>
#import "NSObject+MJKeyValue.h"

#pragma mark - JSBridge

@interface JSBridge()

@end

@implementation JSBridge

+ (instancetype)shared {
    static JSBridge * b = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        b = [[super allocWithZone:nil] init];
        [b loadBridgeJS];
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

- (void)loadBridgeJS {
    if (!_bridgeJS) {
        NSError *error;
        NSString * path = [[NSBundle mainBundle] pathForResource:@"JSBridge" ofType:@"js"];
        NSString * injectjs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (!error && injectjs.length > 0) {
            _bridgeJS = injectjs;
        } else {
            NSAssert(NO, @"*** JSBridge.js读取错误");
        }
    }
}

- (void)cacheWithInterfaces:(NSArray<Class>*)interfaces
{
    if (interfaces && [interfaces isKindOfClass:[NSArray class]] && interfaces.count > 0)
    {
        for(Class objCls in interfaces)
        {
            NSMutableString* injectString = [[NSMutableString alloc] init];
            NSString *  objName = NSStringFromClass(objCls);
            NSObject *  obj     = [[objCls alloc] init];
            Class       cls     = objCls;
            
            // _inject: function (obj, methods) {}
            [injectString appendString:@"JSBridge._inject(\""];
            [injectString appendString:objName];
            [injectString appendString:@"\", ["];
            if ([obj isKindOfClass:[NSObject class]]) {
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
            [injectString appendString:@"]);"];
            
            [[JSBridge shared].cacheMap setObject:@[objCls, injectString] forKey:objName];
            [[JSBridge shared].methodsInjectString appendString:injectString];
        }   
    }
}

- (NSMutableDictionary<NSString *,NSArray *> *)cacheMap {
    if (!_cacheMap) {
        _cacheMap = [NSMutableDictionary dictionary];
    }
    return _cacheMap;
}

- (NSMutableString *)methodsInjectString {
    if (!_methodsInjectString) {
        _methodsInjectString = [NSMutableString string];
    }
    return _methodsInjectString;
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
        Class objClass = [[self.interfaces objectForKey:obj] objectAtIndex:0];
        NSObject* interface = [[objClass alloc] init];
        
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
