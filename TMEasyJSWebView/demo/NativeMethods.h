//
//  NativeMethods.h
//  WKEasyJSBridgeWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RuntimeJSBridge.h"

@interface NativeMethods : NSObject

/// 这种方式定义接口是不行的, 因为机制原因`callback`无法匹配, 除非js入参就传入`testWithParams:callback:`
- (void)testWithParams:(NSString*)json callback:(JSBridgeDataFunction*)func;

/// 建议以这种方式定义接口名`testWithParams::`
- (void)testWithParams:(NSString*)json :(JSBridgeDataFunction*)func;


@end
