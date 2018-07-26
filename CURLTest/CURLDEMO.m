//
//  CURLDEMO.m
//  CURLTest
//
//  Created by 刘欢欢 on 2018/6/27.
//  Copyright © 2018年 刘欢欢. All rights reserved.
//

#import "CURLDEMO.h"

#import <curl/curl.h>
#import <openssl/ssl.h>

@interface CURLDEMO ()

{
    CURL *_curl;
    // CURL global data
    NSData *_dataToSend;
    size_t _dataToSendBookmark;
    NSMutableData *_dataReceived;
    
    NSString *_JSESSIONID;
    NSString *_HOST;
    NSMutableString *_resultMu;
}

@property (nonatomic,assign) NSInteger Id;

- (size_t)copyUpToThisManyBytes:(size_t)bytes intoThisPointer:(void *)pointer;
- (void)displayText:(NSString *)text;
- (void)receivedData:(NSData *)data;
- (void)delegateSoutcr:(NSString *)infoString type:(curl_infotype)type;

@end

// Curl methods to process response
int iOSCurlDebugCallback(CURL *curl, curl_infotype infotype, char *info, size_t infoLen, void *contextInfo)
{
    CURLDEMO *vc = (__bridge CURLDEMO *)contextInfo;
    
    
    NSData *infoData = [NSData dataWithBytes:info length:infoLen];
    NSString *infoStr = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
    if (infoStr) {
        infoStr = [infoStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];    // convert CR/LF to LF
        infoStr = [infoStr stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];    // convert CR to LF
        
        //        NSLog(@"%@",infoStr);
        
        switch (infotype) {
            case CURLINFO_DATA_IN:
                // 返回结果,成功反结果，失败返错误码
                NSLog(@"%@\n\n",infoStr);
                break;
            case CURLINFO_DATA_OUT:// 参数ApiShakerForm[shakercode]=Shaker_B6002
                NSLog(@"%@\n\n",infoStr);
                break;
            case CURLINFO_HEADER_IN:// 返回值类型Content-Type: text/html; charset=UTF-8
//                NSLog(@"%@\n\n",infoStr);
                break;
            case CURLINFO_HEADER_OUT:// 接口和头文件
                NSLog(@"%@\n\n",infoStr);
                break;
            case CURLINFO_TEXT:
//                NSLog(@"%@\n\n",infoStr);
                break;
            default:    // ignore the other CURLINFOs
                break;
        }
        
        [vc delegateSoutcr:infoStr type:infotype];
        
    }
    return 0;
}

size_t iOSCurlReadCallback(void *ptr, size_t size, size_t nmemb, void *userdata) {
    const size_t sizeInBytes = size*nmemb;
    CURLDEMO *vc = (__bridge CURLDEMO *)userdata;
    
    return [vc copyUpToThisManyBytes:sizeInBytes intoThisPointer:ptr];
}

size_t iOSCurlWriteCallback(char *ptr, size_t size, size_t nmemb, void *userdata) {
    const size_t sizeInBytes = size*nmemb;
    CURLDEMO *vc = (__bridge CURLDEMO *)userdata;
    NSData *data = [[NSData alloc] initWithBytes:ptr length:sizeInBytes];
    
    [vc receivedData:data];  // send to viewcontroller
    return sizeInBytes;
}

int iOSCurlProgressCallback(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
    // Placeholder - add progress bar?
    // NSLog(@"iOSCurlProgressCallback %f of %f", dlnow, dltotal);
    return 0;
}

@implementation CURLDEMO

- (instancetype)init
{
    self = [super init];
    if (self) {
        // OpenSSL
        SSL_load_error_strings();                /* readable error messages */
        SSL_library_init();                      /* initialize library */
        
        curl_global_init(0L);
    }
    return self;
}

/*初始化*/
- (void)curlinit
{

    _curl = curl_easy_init();
    _resultMu = [NSMutableString string];
    
}

/*基础参数，url，类型（get、post），参数*/
- (void)performCurlWithURL:(NSString *)urlString parame:(NSDictionary *)parame isPost:(BOOL)isPost urlId:(NSInteger)Id
{
    // Give some render time to show response before we hit the network
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    
    [_dataReceived setLength:0U];
    _dataToSendBookmark = 0U;
    
    self.Id = Id;
    
    NSString *url = [NSString stringWithFormat:@"%@%@",_HOST,urlString];
    
    NSString *parameString = [self pamametWithParameDictionary:parame];

    // Set CURL callback functions  返回结果设置
    curl_easy_setopt(_curl, CURLOPT_DEBUGFUNCTION, iOSCurlDebugCallback);  // function to get debug data to view
    curl_easy_setopt(_curl, CURLOPT_DEBUGDATA, self);
    curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, iOSCurlWriteCallback);  // function to get write data to view
    curl_easy_setopt(_curl, CURLOPT_WRITEDATA, self);    // prevent libcurl from writing the data to stdout
    curl_easy_setopt(_curl, CURLOPT_NOPROGRESS, 0L);
    curl_easy_setopt(_curl, CURLOPT_PROGRESSFUNCTION, iOSCurlProgressCallback);
    curl_easy_setopt(_curl, CURLOPT_PROGRESSDATA, self);  // libcurl will pass back dl data progress
    
    // Set some CURL options  使用设置
    curl_easy_setopt(_curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);    // user/pass may be in URL
    curl_easy_setopt(_curl, CURLOPT_USERAGENT, curl_version());    // set a default user agent
    curl_easy_setopt(_curl, CURLOPT_VERBOSE, 1L);    // turn on verbose
    curl_easy_setopt(_curl, CURLOPT_MAXCONNECTS, 0L); // this should disallow connection sharing
    curl_easy_setopt(_curl, CURLOPT_FORBID_REUSE, 1L); // enforce connection to be closed
    curl_easy_setopt(_curl, CURLOPT_DNS_CACHE_TIMEOUT, 0L); // Disable DNS cache
    curl_easy_setopt(_curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0); // enable HTTP2 Protocol
    curl_easy_setopt(_curl, CURLOPT_SSLVERSION, CURL_SSLVERSION_DEFAULT); // Force TLSv1 protocol - Default
    curl_easy_setopt(_curl, CURLOPT_SSL_CIPHER_LIST, [@"ALL" UTF8String]);
    curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYHOST, 0L);   // 1L to verify, 0L to disable
    curl_easy_setopt(_curl, CURLOPT_UPLOAD, 0L);
    curl_easy_setopt(_curl, CURLOPT_CUSTOMREQUEST,nil);
    
    
    if (isPost) {
        curl_easy_setopt(_curl, CURLOPT_HTTPPOST, 1L); // use HTTP POST method
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS,parameString.UTF8String);
    }
    else {
        curl_easy_setopt(_curl, CURLOPT_HTTPGET, 1L); // use HTTP GET method
    }
    
    NSURL *urlBate = [NSURL URLWithString:url];
    curl_easy_setopt(_curl, CURLOPT_URL, urlBate.absoluteString.UTF8String);
    
    [self setcurlHeader];
    [self curlperform];
    
}
/*超时时间， long数值类型，设置函数执行的最长时间，时间单位为s*/
- (void)setcurlTimeOut:(long)time
{
    curl_easy_setopt(_curl, CURLOPT_TIMEOUT, time); // seconds
}
/*链接服务器超时时间,long数值类型，设置连接服务器最长时间，时间单位为s；当置为0时表示无限长*/
- (void)setcurlConnectTimeOut:(long)time
{
    curl_easy_setopt(_curl, CURLOPT_CONNECTTIMEOUT, time); // seconds
}
/*字符串类型，设置http头中的cookie信息*/
- (void)setcurlCookie
{

}
/*字符串类型，设置http头信息*/
- (void)setcurlHeader
{
    curl_easy_setopt(_curl, CURLOPT_COOKIE ,_JSESSIONID.UTF8String);
    struct curl_slist *http_headers = NULL;
    
    if (_JSESSIONID.length > 0) {
        http_headers = curl_slist_append(http_headers, _JSESSIONID.UTF8String);
        
    }
    
    curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, http_headers); // NULL headers 为空
}

/*开始执行*/
- (void)curlperform
{
    curl_easy_perform(_curl);
    
    [self curlClean];
}
/*关闭、清除Curl*/
- (void)curlClean
{
    curl_easy_cleanup(_curl);
    curl_global_cleanup();
}


- (size_t)copyUpToThisManyBytes:(size_t)bytes intoThisPointer:(void *)pointer
{
    size_t bytesToGo = _dataToSend.length-_dataToSendBookmark;
    size_t bytesToGet = MIN(bytes, bytesToGo);
    
    if (bytesToGo) {
        [_dataToSend getBytes:pointer range:NSMakeRange(_dataToSendBookmark, bytesToGet)];
        _dataToSendBookmark += bytesToGet;
        return bytesToGet;
    }
    return 0U;
}

- (void)displayText:(NSString *)text
{

}

- (void)receivedData:(NSData *)data
{
    [_dataReceived appendData:data];
}

/* 返回结果 */
- (void)delegateSoutcr:(NSString *)infoString type:(curl_infotype)type
{
    if ([_delegate respondsToSelector:@selector(CurlDebugCallback:urlId:)]) {
        if (type == CURLINFO_DATA_IN) { // 仅返回接口返回结果
            NSDictionary *dic;
            if (!dic) {
            [_resultMu appendString:infoString];
            NSData *jonData = [_resultMu dataUsingEncoding:NSUTF8StringEncoding];
            dic = [NSJSONSerialization JSONObjectWithData:jonData options:NSJSONReadingMutableLeaves error:nil];
            }
            if (dic){
                [_delegate CurlDebugCallback:dic urlId:self.Id];
            }
        }
        
        if (self.Id == 1 && type == CURLINFO_HEADER_IN) {
            if ([_delegate respondsToSelector:@selector(CurlSesstionback:)]) {
                NSRange range = [infoString rangeOfString:@"PHPSESSID"];
                if (range.location != NSNotFound) {
                    NSRange footRange = [infoString rangeOfString:@"path"];
                    NSInteger header = range.location + range.length + 1;
                    NSInteger len = footRange.location - 2 - header;
                    NSString *s = [infoString substringWithRange:NSMakeRange(header, len)];
                    _JSESSIONID = [NSString stringWithFormat:@"PHPSESSID=%@",s];
                    
                    [_delegate CurlSesstionback:_JSESSIONID];
                }
            }
        }
    }
}

/*设置头文件 Session*/
-(void) setSessionValue:(NSString *) session
{
    _JSESSIONID = session;
}
/*设置接口 host*/
-(void) setHost:(NSString *) host
{
    _HOST = host;
}

/*将键值对参数转为String*/
- (NSString *)pamametWithParameDictionary:(NSDictionary *)dic
{
    NSMutableString *parameString = [NSMutableString string];
    
    NSArray * allkeys = [dic allKeys];
    
    for (int i = 0; i < allkeys.count; i++)
    {
        NSString *key = [allkeys objectAtIndex:i];
        NSString *value = [dic valueForKey:key];
        [parameString appendFormat:@"%@=%@&",key,value];
    }
    if (parameString.length > 0) {
        [parameString deleteCharactersInRange:NSMakeRange(parameString.length - 1, 1)];
    }
    return parameString;
}

@end
