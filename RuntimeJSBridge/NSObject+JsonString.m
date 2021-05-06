//
//  NSObject+JsonString.m
//  AIPracticeToB
//
//  Created by Jerod on 2019/8/13.
//

#import "NSObject+JsonString.h"

@implementation NSObject (JsonString)


- (NSString*)JSONString
{
    id obj = self;
    
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString*)obj;
    }
    
    if ([self isKindOfClass:[NSDictionary class]] || [self isKindOfClass:[NSArray class]]) {
        
        NSString *jsonString = @"";
        NSError * error;
        jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error] encoding:NSUTF8StringEncoding];
        
        if (!error) {
            return jsonString;
        } else {
            return @"";
        }
        
    } else {
        return @"";
    }
    
}

@end
