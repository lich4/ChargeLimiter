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
static NSTimer* update_timer = nil;
static int update_freq = 60;
static NSDictionary* handleReq(NSDictionary* nsreq);


@interface Service : NSObject<UNUserNotificationCenterDelegate>
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)localPush:(NSString*)msg;
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
        NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1.0];;
        [webview loadRequest:req];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (!_webview_inited) { // 巨魔+越狱共存环境下因签名问题导致delegate不生效而黑屏
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
@end


static io_service_t getIOPMPSServ() {
    static io_service_t serv = 0;
    if (serv == 0) {
        serv = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
    }
    return serv;
}

static int getBatInfo(NSDictionary* __strong* pinfo) {
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
    NSMutableDictionary* filtered_info = [NSMutableDictionary dictionary];
    NSArray* keep = @[@"BootVoltage", @"CurrentCapacity", @"CycleCount", @"DesignCapacity", @"InstantAmperage", @"IsCharging", @"NominalChargeCapacity",
                      @"Serial", @"Temperature", @"Voltage"];
    for (NSString* key in info) {
        if ([keep containsObject:key]) {
            filtered_info[key] = info[key];
        }
    }
    *pinfo = filtered_info;
    return 0;
}

static int setChargeStatus(BOOL flag) {
    io_service_t serv = getIOPMPSServ();
    if (serv == 0) {
        return -1;
    }
    kern_return_t ret = IORegistryEntrySetCFProperty(serv, CFSTR("IsCharging"), flag?kCFBooleanTrue : kCFBooleanFalse);
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

static NSTimer* start_monitor_timer(int interval) {
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer* timer) {
        @autoreleasepool {
            NSLog(@"%@ monitor_timer", log_prefix);
            if (0 == getBatInfo(&bat_info)) {
                NSNumber* charge_below = getlocalKV(@"charge_below");
                NSNumber* charge_above = getlocalKV(@"charge_above");
                NSNumber* capacity = bat_info[@"CurrentCapacity"];
                NSNumber* is_charging = bat_info[@"IsCharging"];
                NSLog(@"%@ monitor_timer %@-%@ cur=%@ charging=%d", log_prefix, charge_below, charge_above, capacity, is_charging.boolValue);
                if (capacity.intValue <= charge_below.intValue) {
                    if (!is_charging.boolValue) {
                        NSLog(@"%@ start charging", log_prefix);
                        [Service.inst localPush:@"Start charging"];
                        setChargeStatus(YES);
                    }
                } else if (capacity.intValue >= charge_above.intValue) {
                    if (is_charging.boolValue) {
                        NSLog(@"%@ stop charging", log_prefix);
                        [Service.inst localPush:@"Stop charging"];
                        setChargeStatus(NO);
                    }
                }
            }
        }
    }];
    [timer fire];
    return timer;
}

static NSDictionary* handleReq(NSDictionary* nsreq) {
    NSString* api = nsreq[@"api"];
    if ([api isEqualToString:@"get_conf"]) {
        NSNumber* charge_below = getlocalKV(@"charge_below");
        NSNumber* charge_above = getlocalKV(@"charge_above");
        if (charge_below == nil) {
            charge_below = @20;
            charge_above = @80;
            setlocalKV(@"charge_below", charge_below);
            setlocalKV(@"charge_above", charge_above);
        }
        return @{
            @"status": @0,
            @"data": @{
                 @"charge_below": charge_below,
                 @"charge_above": charge_above,
                 @"update_freq": @(update_freq),
            },
        };
    } else if ([api isEqualToString:@"set_conf"]) {
        NSString* key = nsreq[@"key"];
        id val = nsreq[@"val"];
        if ([key isEqualToString:@"update_freq"]) {
            update_freq = [val intValue];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [update_timer invalidate];
                update_timer = nil;
                update_timer = start_monitor_timer(update_freq);
            });
        } else {
            setlocalKV(key, val);
        }
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
        int status = setChargeStatus(flag.boolValue);
        return @{
            @"status": @(status)
        };
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
                setChargeStatus(YES);
                [LSApplicationWorkspace.defaultWorkspace removeObserver:self];
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
- (void)localPush:(NSString*)msg {
    void (^Block)() = ^{
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"AlDente";
        content.body = msg;
        NSTimeInterval timeInterval = [[NSDate dateWithTimeIntervalSinceNow:1] timeIntervalSinceNow];
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:NO];
        UNNotificationRequest* reqeust = [UNNotificationRequest requestWithIdentifier:@"AlDente" content:content trigger:trigger];
        [center addNotificationRequest:reqeust withCompletionHandler:nil];
    };
    if ([NSThread isMainThread]) {
        Block();
    } else {
        dispatch_async(dispatch_get_main_queue(), Block);
    }
}
- (void)serve {
    getBatInfo(&bat_info);
    if (update_timer == nil) {
        update_timer = start_monitor_timer(update_freq);
    }
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
            NSDictionary* nsres = handleReq(request.jsonObject);
            return [GCDWebServerDataResponse responseWithJSONObject:nsres];
        }];
        BOOL status = [_webServer startWithPort:GSERV_PORT bonjourName:nil];
        if (!status) {
            NSLog(@"%@ serve failed, exit", log_prefix);
            exit(0);
        }
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
    if ([path hasPrefix:@"/Applications"]) {
        return 1; // jailbreak 适用于iOS<=14
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
                platformize_me();
                [Service.inst serve];
                [NSRunLoop.mainRunLoop run];
            } else if (0 == strcmp(argv[1], "get_bat_info")) {
                getBatInfo(&bat_info);
                NSLog(@"%@", bat_info);
            }
        }
        return -1;
    }
}


// todo: 换sshd

