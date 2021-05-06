//
//  NativeMethods.m
//  WKEasyJSBridgeWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import "NativeMethods.h"

@implementation NativeMethods

- (void)testWithParams:(NSString*)json callback:(JSBridgeDataFunction*)func
{
    //接收h5 参数
    NSLog(@"H5 调 native, 参数 : %@", json);
    
    NSString *letter = [NSString stringWithFormat:@"%C", (unichar)(arc4random_uniform(26) + 'A')];
    NSDictionary* p1 = @{@"letter": letter, @"b": @"bb", @"c": @"cc"};
    NSString* p2 = @"param_p2";
    NSString* p3 = @"param_p3";
    NSArray* nativeParams = @[p1, p2, p3];
    //回调h5
    [func callbackJSWithParams:nativeParams completionHandler:^(id response, NSError *error) {
        NSLog(@"completionHandler");
    }];
}

- (void)testWithParams:(NSString *)json :(id)func {
    //接收h5 参数
    NSLog(@">>> 1 : JS 执行 native, 参数 : %@", json);
    
    NSString *letter = [NSString stringWithFormat:@"%C", (unichar)(arc4random_uniform(26) + 'A')];
    NSDictionary* p1 = @{@"letter": letter, @"b": @"bb", @"c": @"cc"};
    NSString* p2 = @"param_p2";
    NSString* p3 = @"param_p3";
    NSArray* nativeParams = @[p1, p2, p3];
    //回调h5
    [func callbackJSWithParams:nativeParams completionHandler:^(id response, NSError *error) {
        NSLog(@">>> 3 : Native 回调 JS 完成");
    }];
}


@end
