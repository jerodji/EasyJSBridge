//
//  JSInterface.m
//  WKEasyJSWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import "JSInterface.h"
#import "MJExtension.h"
@implementation JSInterface
- (void)testWithParams:(NSString*)_params callback:(WKJSDataFunction*)_callback
{
    //接收h5 参数
    NSLog(@"H5 调 native, 参数 : %@", _params);
    
    NSString *letter = [NSString stringWithFormat:@"%C", (unichar)(arc4random_uniform(26) + 'A')];
    NSDictionary* p1 = @{@"letter": letter, @"b": @"bb", @"c": @"cc"};
    NSString* p2 = @"param_p2";
    NSString* p3 = @"param_p3";
    NSArray* nativeParams = @[p1, p2, p3];
    //回调h5
    [_callback executeWithParams:nativeParams completionHandler:^(id response, NSError *error) {
        NSLog(@"completionHandler");
    }];
}
@end
