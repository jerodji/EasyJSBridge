//
//  IOSInterface.h
//  WKEasyJSWebView
//
//  Created by Jerod on 2021/1/6.
//  Copyright © 2021 JIJIUDONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCJSBridge.h"

@interface IOSInterface : NSObject

- (void)log:(NSString *)json;

- (void)testWithParams;

@end
