//
//  CURLDEMO.h
//  CURLTest
//
//  Created by 刘欢欢 on 2018/6/27.
//  Copyright © 2018年 刘欢欢. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CurlDelegate <NSObject>

@required
/*返回信息，结果，接口，参数等*/
- (void)CurlDebugCallback:(NSDictionary *)result urlId:(NSInteger)Id;

@optional
/*登陆后返回结果的PHPSession*/
- (void)CurlSesstionback:(NSString *)session;

@end

@interface CURLDEMO : NSObject

@property (nonatomic,weak) id<CurlDelegate> delegate;

/*初始化*/
-(void) curlinit;
/*基础参数，url，类型（get、post），参数*/
-(void) performCurlWithURL:(NSString *)urlString parame:(NSDictionary *)parame isPost:(BOOL)isPost urlId:(NSInteger)Id;
/*超时时间， long数值类型，设置函数执行的最长时间，时间单位为s*/
-(void) setcurlTimeOut:(long)time;
/*链接服务器超时时间,long数值类型，设置连接服务器最长时间，时间单位为s；当置为0时表示无限长*/
-(void) setcurlConnectTimeOut:(long)time;
/*设置头文件 Session*/
-(void) setSessionValue:(NSString *) session;
/*设置接口 host*/
-(void) setHost:(NSString *) host;

/*开始执行*/
- (void)curlperform;
/*关闭、清楚Curl*/
- (void)curlClean;

@end
