#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <GCDWebServers/GCDWebServers.h>
#import <IOKit/IOKit.h>
#import <UserNotifications/UserNotifications.h>
#include "utils.h"


#define PRODUCT         "aldente"
#define GSERV_PORT      1230


NSString* log_prefix = @(PRODUCT "logger");
static NSDictionary* bat_info = nil;
static NSDictionary* handleReq(NSDictionary* nsreq);


@interface Service : NSObject<UNUserNotificationCenterDelegate>
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)localPush:(NSString*)msg interval:(int)interval;
@end

@interface AppDelegate : UIViewController<UIApplicationDelegate, UIWindowSceneDelegate, UIWebViewDelegate>
@property(strong, nonatomic) UIWindow* window;
@property(retain) UIWebView* webview;
@end

@implementation AppDelegate
static UIWindow* _g_wind = nil;
static AppDelegate* _g_app = nil;
static BOOL _webview_inited = NO;
- (void)sceneWillEnterForeground:(UIScene*)scene API_AVAILABLE(ios(13.0)) {
    _g_wind = self.window;
}
- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
    _g_wind = self.window;
    return YES;
}
- (void)viewDidAppear:(BOOL)animated {
    @autoreleasepool {
        [super viewDidAppear:animated];
        self.window = _g_wind;
        _g_app = self;
        
        CGSize size = UIScreen.mainScreen.bounds.size;
        // 从WKWebView换UIWebView: 巨魔+越狱共存环境下签名问题导致delegate不生效而黑屏
        UIWebView* webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        webview.delegate = self;
        self.webview = webview;

        NSString* wwwpath = [NSString stringWithFormat:@"http://127.0.0.1:%d", GSERV_PORT];
        NSURL* url = [NSURL URLWithString:wwwpath];
        NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
        [webview loadRequest:req];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (!_webview_inited) { // 巨魔+越狱共存环境下因签名问题导致delegate不生效而黑屏
                [webview loadRequest:req];
                [self.window addSubview:webview];
                [self.window bringSubviewToFront:webview];
                _webview_inited = YES;
            }
        });
    }
}
- (void)webViewDidFinishLoad:(UIWebView*)webview {
    [self.window addSubview:webview];
    [self.window bringSubviewToFront:webview];
    _webview_inited = YES;
}
- (void)webView:(UIWebView*)webview didFailLoadWithError:(NSError*)error {
    NSString* wwwpath = [NSString stringWithFormat:@"http://127.0.0.1:%d", GSERV_PORT];
    NSURL* url = [NSURL URLWithString:wwwpath];
    NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
    [webview loadRequest:req];
}
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* url = request.URL.absoluteString;
    if ([url isEqualToString:@"app://exit"]) {
        exit(0);
    }
    return YES;
}
@end


static io_service_t getIOPMPSServ() {
    static io_service_t serv = 0;
    if (serv == 0) {
        serv = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
        // AppleSmartBattery >=iPhone11才有, 且数据相同
    }
    return serv;
}

static int getBatInfoWithServ(io_service_t serv, NSDictionary* __strong* pinfo) {
    CFMutableDictionaryRef prop = nil;
    IORegistryEntryCreateCFProperties(serv, &prop, kCFAllocatorDefault, 0);
    if (prop == nil) {
        return -2;
    }
    NSMutableDictionary* info = (__bridge_transfer NSMutableDictionary*)prop;
    NSMutableDictionary* filtered_info = [NSMutableDictionary dictionary];
    NSArray* keep = @[
        @"Amperage", @"BatteryInstalled", @"BootVoltage", @"CurrentCapacity", @"CycleCount", @"DesignCapacity", @"ExternalChargeCapable", @"ExternalConnected",
        @"InstantAmperage", @"IsCharging", @"NominalChargeCapacity", @"PostChargeWaitSeconds", @"PostDischargeWaitSeconds", @"Serial", @"Temperature",
        @"UpdateTime", @"Voltage"];
    for (NSString* key in info) {
        if ([keep containsObject:key]) {
            filtered_info[key] = info[key];
        }
    }
    if (info[@"AdapterDetails"] != nil) {
        NSDictionary* adaptor_info = info[@"AdapterDetails"];
        NSMutableDictionary* filtered_adaptor_info = [NSMutableDictionary dictionary];
        keep = @[@"AdapterVoltage", @"Current", @"Description", @"IsWireless", @"Manufacturer", @"Name",  @"Watts"];
        for (NSString* key in adaptor_info) {
            if ([keep containsObject:key]) {
                filtered_adaptor_info[key] = adaptor_info[key];
            }
        }
        filtered_info[@"AdapterDetails"] = filtered_adaptor_info;
    }
    *pinfo = filtered_info;
    return 0;
}

static int getBatInfo(NSDictionary* __strong* pinfo, BOOL slim=YES) {
    io_service_t serv = getIOPMPSServ();
    if (serv == 0) {
        return -1;
    }
    CFMutableDictionaryRef prop = nil;
    IORegistryEntryCreateCFProperties(serv, &prop, kCFAllocatorDefault, 0);
    if (prop == nil) {
        return -2;
    }
    NSMutableDictionary* info = (__bridge_transfer NSMutableDictionary*)prop;
    if (slim) {
        NSMutableDictionary* filtered_info = [NSMutableDictionary dictionary];
        NSArray* keep = @[
            @"Amperage", @"BatteryInstalled", @"BootVoltage", @"CurrentCapacity", @"CycleCount", @"DesignCapacity", @"ExternalChargeCapable", @"ExternalConnected",
            @"InstantAmperage", @"IsCharging", @"NominalChargeCapacity", @"PostChargeWaitSeconds", @"PostDischargeWaitSeconds", @"Serial", @"Temperature",
            @"UpdateTime", @"Voltage"];
        for (NSString* key in info) {
            if ([keep containsObject:key]) {
                filtered_info[key] = info[key];
            }
        }
        if (info[@"AdapterDetails"] != nil) {
            NSDictionary* adaptor_info = info[@"AdapterDetails"];
            NSMutableDictionary* filtered_adaptor_info = [NSMutableDictionary dictionary];
            keep = @[@"AdapterVoltage", @"Current", @"Description", @"IsWireless", @"Manufacturer", @"Name",  @"Watts"];
            for (NSString* key in adaptor_info) {
                if ([keep containsObject:key]) {
                    filtered_adaptor_info[key] = adaptor_info[key];
                }
            }
            filtered_info[@"AdapterDetails"] = filtered_adaptor_info;
        }
        *pinfo = filtered_info;
    } else {
        *pinfo = info;
    }
    return 0;
}

static BOOL isAdaptorConnect(NSDictionary* info) {
    NSNumber* ExternalConnected = info[@"ExternalConnected"];
    if (ExternalConnected != nil) {
        return ExternalConnected.boolValue;
    }
    return NO;
}

static BOOL isAdaptorNewConnect(NSDictionary* oldInfo, NSDictionary* info) {
    NSNumber* old_ExternalConnected = oldInfo[@"ExternalConnected"];
    NSNumber* ExternalConnected = info[@"ExternalConnected"];
    if (!old_ExternalConnected.boolValue && ExternalConnected.boolValue) {
        return YES;
    }
    return NO;
}

static int setChargeStatus(BOOL flag) {
    io_service_t serv = getIOPMPSServ();
    if (serv == 0) {
        return -1;
    }
    NSMutableDictionary* props = [NSMutableDictionary new];
    props[@"IsCharging"] = @(flag);
    props[@"PredictiveChargingInhibit"] = @NO; // PredictiveChargingInhibit为IsCharging总开关
    kern_return_t ret = IORegistryEntrySetCFProperties(serv, (__bridge CFTypeRef)props);
    if (ret != 0) {
        return -2;
    }
    return 0;
}

static id getlocalKV(NSString* key) {
    NSString* path = [NSHomeDirectory() stringByAppendingString:@"/aldente.conf"];
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:path];
    if (dic == nil) {
        return nil;
    }
    return dic[key];
}

static void setlocalKV(NSString* key, id val) {
    NSString* path = [NSHomeDirectory() stringByAppendingString:@"/aldente.conf"];
    NSMutableDictionary* mdic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (mdic == nil) {
        mdic = [NSMutableDictionary new];
    }
    mdic[key] = val;
    [mdic writeToFile:path atomically:YES];
}

static void onBatteryEvent(io_service_t serv) {
    @autoreleasepool {
        NSDictionary* old_bat_info = bat_info;
        if (0 == getBatInfoWithServ(serv, &bat_info)) {
            NSString* mode = getlocalKV(@"mode");
            NSNumber* charge_below = getlocalKV(@"charge_below");
            NSNumber* charge_above = getlocalKV(@"charge_above");
            NSNumber* enable_temp = getlocalKV(@"enable_temp");
            NSNumber* charge_temp_above = getlocalKV(@"charge_temp_above");
            NSNumber* capacity = bat_info[@"CurrentCapacity"];
            NSNumber* is_charging = bat_info[@"IsCharging"];
            NSNumber* temperature_ = bat_info[@"Temperature"];
            int temperature = temperature_.intValue / 100;
            if (enable_temp.boolValue && temperature >= charge_temp_above.intValue) {
                if (is_charging.boolValue) {
                    NSLog(@"%@ stop charging for high temperature", log_prefix);
                    [Service.inst localPush:@"Stop charging for high temperature" interval:3600];
                    setChargeStatus(NO);
                    return;
                }
            }
            if (capacity.intValue >= charge_above.intValue) {
                if (is_charging.boolValue) {
                    NSLog(@"%@ stop charging", log_prefix);
                    [Service.inst localPush:@"Stop charging" interval:3600];
                    setChargeStatus(NO);
                    return;
                }
            }
            if ([mode isEqualToString:@"charge_on_plug"]) { // 此状态下禁用charge_below
                if (isAdaptorNewConnect(old_bat_info, bat_info)) {
                    [Service.inst localPush:@"Start charging for plug in" interval:3600];
                    setChargeStatus(YES);
                }
                return;
            }
            if (capacity.intValue <= charge_below.intValue) {
                if (!is_charging.boolValue) {
                    if (isAdaptorConnect(bat_info)) {
                        NSLog(@"%@ start charging", log_prefix);
                        [Service.inst localPush:@"Start charging" interval:3600];
                        setChargeStatus(YES);
                    } else {
                        [Service.inst localPush:@"Plug in adaptor to charge" interval:3600];
                    }
                }
            }
        }
    }
}

static void initConf() {
    NSDictionary* def_dic = @{
        @"mode": @"charge_on_plug",
        @"lang": @"",
        @"charge_below": @20,
        @"charge_above": @80,
        @"enable_temp": @NO,
        @"charge_temp_above": @35,
        @"update_freq": @60,
    };
    for (NSString* key in def_dic) {
        id val = getlocalKV(key);
        if (val == nil) {
            setlocalKV(key, def_dic[key]);
        }
    }
}

static NSDictionary* handleReq(NSDictionary* nsreq) {
    NSString* api = nsreq[@"api"];
    if ([api isEqualToString:@"get_conf"]) {
        NSString* mode = getlocalKV(@"mode");
        NSString* lang = getlocalKV(@"lang");
        NSNumber* charge_below = getlocalKV(@"charge_below");
        NSNumber* charge_above = getlocalKV(@"charge_above");
        NSNumber* enable_temp = getlocalKV(@"enable_temp");
        NSNumber* charge_temp_above = getlocalKV(@"charge_temp_above");
        NSNumber* update_freq = getlocalKV(@"update_freq");
        return @{
            @"status": @0,
            @"data": @{
                @"mode": mode,
                @"lang": lang,
                @"charge_below": charge_below,
                @"charge_above": charge_above,
                @"enable_temp": enable_temp,
                @"charge_temp_above": charge_temp_above,
                @"update_freq": update_freq,
            },
        };
    } else if ([api isEqualToString:@"set_conf"]) {
        NSString* key = nsreq[@"key"];
        id val = nsreq[@"val"];
        setlocalKV(key, val);
        return @{
            @"status": @0,
        };
    } else if ([api isEqualToString:@"get_bat_info"]) {
        BOOL update = nsreq[@"update"] != nil;
        if (update) {
            getBatInfo(&bat_info);
        }
        int status = (bat_info != nil)?0 : -1;
        return @{
            @"status": @(status),
            @"data": bat_info,
        };
    } else if ([api isEqualToString:@"set_charge_status"]) {
        NSNumber* flag = nsreq[@"flag"];
        getBatInfo(&bat_info);
        int status = -1;
        if (flag.boolValue && !isAdaptorConnect(bat_info)) {
            status = -3;
        } else {
            status = setChargeStatus(flag.boolValue);
        }
        return @{
            @"status": @(status)
        };
    } else if ([api isEqualToString:@"exit"]) {
        exit(0);
    }
    return @{
        @"status": @-10
    };
}


@implementation Service {
    NSString* bid;
}
+ (instancetype)inst {
    static dispatch_once_t pred = 0;
    static Service* inst_ = nil;
    dispatch_once(&pred, ^{
        inst_ = [self new];
    });
    return inst_;
}
- (void)applicationsDidUninstall:(NSArray<LSApplicationProxy*>*)list {
    @autoreleasepool {
        for (LSApplicationProxy* proxy in list) {
            if ([proxy.bundleIdentifier isEqualToString:self->bid]) {
                NSLog(@"%@ uninstalled, exit", log_prefix); // 卸载时系统不能自动杀本进程,需手动退出
                exit(0);
            }
        }
    }
}
- (instancetype)init {
    self = super.init;
    self->bid = NSBundle.mainBundle.bundleIdentifier;
    return self;
}
- (void)initLocalPush {
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError* error) {
    }];
}
- (void)localPush:(NSString*)msg interval:(int)interval { // interval防止频繁提示
    static NSMutableDictionary* lastRemindDic = [NSMutableDictionary new];
    static void (^Block)(NSString*) = ^(NSString* msg) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"AlDente";
        content.body = msg;
        NSTimeInterval timeInterval = [[NSDate dateWithTimeIntervalSinceNow:1] timeIntervalSinceNow];
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:NO];
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"AlDente" content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:nil];
    };
    BOOL needNotify = NO;
    if (interval == 0) {
        needNotify = YES;
    } else if (interval > 0) {
        int ts = (int)time(0);
        if (lastRemindDic[msg] == nil) {
            lastRemindDic[msg] = @0;
        }
        NSNumber* last_remind_ts = lastRemindDic[msg];
        if (ts - last_remind_ts.intValue > interval) {
            lastRemindDic[msg] = @(ts);
            needNotify = YES;
        }
    }
    if (needNotify) {
        if ([NSThread isMainThread]) {
            Block(msg);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                Block(msg);
            });
        }
    }
}
- (void)serve {
    initConf();
    static GCDWebServer* _webServer = nil;
    if (_webServer == nil) {
        if (localPortOpen(GSERV_PORT)) {
            NSLog(@"%@ already served, exit", log_prefix);
            exit(0); // 服务已存在,退出
        }
        _webServer = [GCDWebServer new];
        NSString* html_root = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"www"];
        [_webServer addGETHandlerForBasePath:@"/" directoryPath:html_root indexFilename:@"index.html" cacheAge:1 allowRangeRequests:NO];
        [_webServer addDefaultHandlerForMethod:@"POST" requestClass:GCDWebServerDataRequest.class processBlock:^GCDWebServerResponse*(GCDWebServerDataRequest* request) {
            @autoreleasepool {
                NSDictionary* nsres = handleReq(request.jsonObject);
                return [GCDWebServerDataResponse responseWithJSONObject:nsres];
            }
        }];
        BOOL status = [_webServer startWithPort:GSERV_PORT bonjourName:nil];
        if (!status) {
            NSLog(@"%@ serve failed, exit", log_prefix);
            exit(0);
        }
        getBatInfo(&bat_info);
        io_service_t serv = getIOPMPSServ();
        IONotificationPortRef port = IONotificationPortCreate(kIOMasterPortDefault);
        CFRunLoopSourceRef runSrc = IONotificationPortGetRunLoopSource(port);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runSrc, kCFRunLoopDefaultMode);
        io_object_t noti = IO_OBJECT_NULL;
        IOServiceAddInterestNotification(port, serv, "IOGeneralInterest", [](void* refcon, io_service_t service, uint32_t type, void* args) {
            onBatteryEvent(service);
        }, nil, &noti);
        [LSApplicationWorkspace.defaultWorkspace addObserver:self];
        [self initLocalPush];
    }
}
@end

static int getJBType() {
    NSString* path = getAppEXEPath();
    if ([path hasPrefix:@"/private"]) {
        path = [path substringFromIndex:8];
    }
    if ([path hasPrefix:@"/Applications"] || [path hasPrefix:@"/var/jb/Applications"]) {
        return 1; // jailbreak
    }
    // iOS>=15无根越狱使用trollstore替代
    return 2; // trollstore
}

int main(int argc, char** argv) {
    @autoreleasepool {
        int jbtype = getJBType();
        if (argc == 1) {
            if (jbtype == 2) { // jb daemon自动启动; trollstore需要手动启动
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (!localPortOpen(GSERV_PORT)) {
                        NSLog(@"%@ start daemon", log_prefix);
                        spawn(@[getAppEXEPath(), @"daemon"], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
                    }
                });
            }
            return UIApplicationMain(argc, argv, nil, @"AppDelegate");
        } else if (argc > 1) {
            if (0 == strcmp(argv[1], "daemon")) {
                if (jbtype == 2) {
                    signal(SIGHUP, SIG_IGN);
                    signal(SIGTERM, SIG_IGN); // 防止App被Kill以后daemon退出
                }
                platformize_me(); // for jailbreak
                [Service.inst serve];
                atexit_b(^{
                    [LSApplicationWorkspace.defaultWorkspace removeObserver:Service.inst];
                    setChargeStatus(YES);
                });
                [NSRunLoop.mainRunLoop run];
            } else if (0 == strcmp(argv[1], "get_bat_info")) {
                BOOL slim = argc == 3;
                getBatInfo(&bat_info, slim);
                NSLog(@"%@", bat_info);
            }
        }
        return -1;
    }
}

