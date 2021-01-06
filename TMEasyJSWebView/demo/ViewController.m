//
//  ViewController.m
//  TMEasyJSBridgeWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import "ViewController.h"
#import "MJExtension.h"

#import "JSBridge.h"
#import "NativeMethods.h"
#import "JSMethods.h"

@interface ViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) JSBridgeWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    CGRect rect = CGRectMake(20, 88, self.view.bounds.size.width-40, self.view.bounds.size.height-300);
//    self.webView = [[JSBridgeWebView alloc] initWithFrame:rect configuration:[WKWebViewConfiguration new] scripts:nil javascriptInterfaces:@{@"native":[NativeMethods new]}];
    
    self.webView = [[JSBridgeWebView alloc] initWithFrame:rect
                                            configuration:[[WKWebViewConfiguration alloc] init]
                                                  scripts:nil
                                     javascriptInterfaces:@[[NativeMethods class]]];
    
//    self.webView = [[JSBridgeWebView alloc] initUsingCacheWithFrame:rect configuration:nil];
    
    self.webView.navigationDelegate = self;
   [self.view addSubview:self.webView];
    
    NSString* _urlStr = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:_urlStr]];
    [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UILabel* l = [UILabel new];
    l.text = @"灰色这里是原生界面";
    l.frame = CGRectMake(20, self.view.bounds.size.height - 150, 310, 20);
    [self.view addSubview:l];
    
    UIButton * b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.backgroundColor = [UIColor yellowColor];
    [b setTitle:@"黄色是原生按钮" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b addTarget:self action:@selector(nativeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    b.frame = CGRectMake(20, self.view.bounds.size.height-100, 300, 50);
    [self.view addSubview:b];
}

- (void)nativeButtonClicked {
    NSLog(@"点击了原生按钮");
    [self.webView invokeJSFunction:JS_CHANGE_COLOR params:@{@"color": [self Ox_randomColor]} completionHandler:^(id response, NSError *error) {
        NSLog(@"回调: 原生调用JS方法完成.");
    }];
}

- (NSMutableString*)Ox_randomColor {
    NSMutableString* color = [[NSMutableString alloc] initWithString:@"#"];
    NSArray * STRING = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"A",@"B",@"C",@"D",@"E",@"F"];
    for (int i=0; i<6; i++) {
        NSInteger index = arc4random_uniform((uint32_t)STRING.count);
        NSString *c = [STRING objectAtIndex:index];
        [color appendString:c];
    }
    return color;
}

@end
