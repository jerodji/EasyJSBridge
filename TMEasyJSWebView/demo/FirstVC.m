//
//  FirstVC.m
//  TMEasyJSWebView
//
//  Created by 吉久东(EX-JIJIUDONG001) on 2019/12/31.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import "FirstVC.h"
#import <WebKit/WebKit.h>
#import "ViewController.h"

@interface FirstVC ()

@end

@implementation FirstVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebView* web = [[WKWebView alloc] init];
    web.backgroundColor = [UIColor yellowColor];
    web.frame = CGRectMake(0, 0, 200, 200);
    [self.view addSubview:web];
    
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.navigationController pushViewController:[ViewController new] animated:YES];
}

@end
