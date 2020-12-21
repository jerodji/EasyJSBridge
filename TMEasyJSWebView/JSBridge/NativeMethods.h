//
//  NativeMethods.h
//  WKEasyJSBridgeWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSBridge.h"

@interface NativeMethods : NSObject
- (void)testWithParams:(NSString*)_params callback:(JSBridgeDataFunction*)_callback;
- (void)log:(NSString*)params;
@end
