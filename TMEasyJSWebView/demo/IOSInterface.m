//
//  IOSInterface.m
//  WKEasyJSWebView
//
//  Created by Jerod on 2021/1/6.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import "IOSInterface.h"

@implementation IOSInterface

- (void)log:(NSString *)json {
    NSLog(@"[JS LOG] : %@", json);
}

- (void)testWithParams {
    NSLog(@"testWithParams");
}

@end
