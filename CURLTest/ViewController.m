//
//  ViewController.m
//  CURLTest
//
//  Created by 刘欢欢 on 2018/6/27.
//  Copyright © 2018年 刘欢欢. All rights reserved.
//

#define POSTURL @"/api-user/login"
#define POSTURL2 @"/api-user/getshaker"

//#define POSTURL @"http://js.anpeinet.com/news/personLoginApp"
//#define POSTFIELDS @"userName=lslsls1&password=888888"


#import "ViewController.h"

#import "CURLDEMO.h"

@interface ViewController ()
<CurlDelegate>
{
    CURLDEMO *_curl;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    button.center = self.view.center;
    [button setBackgroundColor:[UIColor greenColor]];
    [button addTarget:self action:@selector(actionButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //    NSString *
    if (self) {
        _curl = [[CURLDEMO alloc] init];
      [_curl setHost:@"deepken.f3322.net:8089"];
    }
    _curl.delegate = self;
}

- (void)actionButton
{
    NSDictionary *parame = @{
                             @"ApiLoginForm[username]" : @"18015560166",
                             @"ApiLoginForm[password]" : @"asdfgh"
                             };
    [_curl curlinit];
    [_curl performCurlWithURL:POSTURL parame:parame isPost:YES urlId:1];
    
    NSDictionary *parame2 = @{
                             @"ApiShakerForm[shakercode]" : @"Shaker_B6002"
                             };
    [_curl curlinit];
    [_curl performCurlWithURL:POSTURL2 parame:parame2 isPost:YES urlId:2];

}

// delegata方法
-(void)CurlDebugCallback:(NSDictionary *)result urlId:(NSInteger)Id
{
//    NSLog(@"\n result  %d   %@\n\n",type,result);
    
    NSLog(@"result = %@",result);
}

- (void)CurlSesstionback:(NSString *)session
{
    [_curl setSessionValue:session];
}

@end

