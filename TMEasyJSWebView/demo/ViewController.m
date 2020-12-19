//
//  ViewController.m
//  TMEasyJSWebView
//
//  Created by 吉久东 on 2019/8/13.
//  Copyright © 2019 JIJIUDONG. All rights reserved.
//

#import "ViewController.h"
#import "WKJSWebView.h"
#import "JSInterface.h"
#import "MJExtension.h"

@interface ViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) WKJSWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-150);
    self.webView = [[WKJSWebView alloc] initWithFrame:rect configuration:[WKWebViewConfiguration new] scripts:nil withJavascriptInterfaces:@{@"native":[JSInterface new]}];
    self.webView.navigationDelegate = self;
   [self.view addSubview:self.webView];
    
    NSString* _urlStr = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:_urlStr]];
    [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UILabel* l = [UILabel new];
    l.text = @"这里灰色部分是原生界面";
    l.frame = CGRectMake(5, self.view.bounds.size.height - 150, 310, 20);
    [self.view addSubview:l];
    
    UIButton * b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.backgroundColor = [UIColor yellowColor];
    [b setTitle:@"黄色是原生按钮" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b addTarget:self action:@selector(nativeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    b.frame = CGRectMake(5, self.view.bounds.size.height-100, 310, 50);
    [self.view addSubview:b];
}

- (void)nativeButtonClicked {
    NSLog(@"点击了原生按钮");
    [self.webView invokeJSFunction:@"divChangeColor" params:@{@"color": [self Ox_randomColor]} completionHandler:^(id response, NSError *error) {
        NSLog(@"原生调用JS方法完成.");
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
