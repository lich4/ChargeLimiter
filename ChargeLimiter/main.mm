#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <GCDWebServers/GCDWebServers.h>
#import <IOKit/IOKit.h>
#include <IOKit/hid/IOHIDService.h>
#import <UserNotifications/UserNotifications.h>
#include "utils.h"

#define PRODUCT         "aldente"
#define GSERV_PORT      1230

NSString* log_prefix = @(PRODUCT "logger");
static NSDictionary* bat_info = nil;
static NSDictionary* handleReq(NSDictionary* nsreq);

extern "C" {
void* BKSHIDEventRegisterEventCallback(void (*)(void*, void*, IOHIDServiceRef, IOHIDEventRef));
void UIApplicationInstantiateSingleton(id aclass);
void UIApplicationInitialize();
}


@interface UIApplication(Private)
- (void)__completeAndRunAsPlugin;
@end

@interface UIWindow(Private)
- (unsigned int)_contextId;
@end

@interface SBSAccessibilityWindowHostingController: NSObject
- (void)registerWindowWithContextID:(unsigned)arg1 atLevel:(double)arg2;
@end

@interface Service : NSObject<UNUserNotificationCenterDelegate>
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)localPush:(NSString*)msg interval:(int)interval;
@end

@interface AppDelegate : UIViewController<UIApplicationDelegate, UIWindowSceneDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate>
@property(strong, nonatomic) UIWindow* window;
@property(retain) UIWebView* webview;
@end

@interface HUDMainWindow: UIWindow
@end

@implementation HUDMainWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}
- (BOOL)_isWindowServerHostingManaged {
    return NO;
}
@end

static int g_wind_type = 0; // 1: HUD
#define FLOAT_ORIGINX   100
#define FLOAT_ORIGINY   100
#define FLOAT_WIDTH     80
#define FLOAT_HEIGHT    55

@implementation AppDelegate
static UIView* _mainWnd = nil;
static AppDelegate* _app = nil;
- (void)sceneWillEnterForeground:(UIScene*)scene API_AVAILABLE(ios(13.0)) {
    _mainWnd = self.window;
}
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
    if (g_wind_type == 0) {
        _mainWnd = self.window;
    } else if (g_wind_type == 1) {
        self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [self.window setRootViewController:[AppDelegate new]];
        [self.window setWindowLevel:10000010.0];
        [self.window setHidden:NO];
        [self.window makeKeyAndVisible];
        static SBSAccessibilityWindowHostingController* _accessController = [objc_getClass("SBSAccessibilityWindowHostingController") new];
        unsigned int _contextId = [self.window _contextId];
        double windowLevel = [self.window windowLevel];
        [_accessController registerWindowWithContextID:_contextId atLevel:windowLevel];
    }
    return YES;
}
- (void)viewDidAppear:(BOOL)animated {
    @autoreleasepool {
        [super viewDidAppear:animated];
        CGSize size = UIScreen.mainScreen.bounds.size;
        _app = self;
        if (g_wind_type == 0) {
            NSString* imgpath = [NSString stringWithFormat:@"%@/splash.png", NSBundle.mainBundle.bundlePath];
            UIImage* image = [UIImage imageWithContentsOfFile:imgpath];
            UIImageView* imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
            imageview.image = image;
            imageview.contentMode = UIViewContentModeScaleAspectFill;
            [_mainWnd addSubview:imageview];
            
            UIWebView* webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
            webview.delegate = self;
            self.webview = webview;
            NSString* wwwpath = [NSString stringWithFormat:@"http://127.0.0.1:%d", GSERV_PORT];
            NSURL* url = [NSURL URLWithString:wwwpath];
            NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
            [webview loadRequest:req];
        } else if (g_wind_type == 1) {
            _mainWnd = self.view;
            UIWebView* webview = [[UIWebView alloc] initWithFrame:CGRectMake(FLOAT_ORIGINX, FLOAT_ORIGINY, FLOAT_WIDTH, FLOAT_HEIGHT)]; // 窗口大小
            webview.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
            webview.opaque = NO;
            webview.delegate = self;
            webview.userInteractionEnabled = YES;
            self.webview = webview;
            NSString* wwwpath = [NSString stringWithFormat:@"http://127.0.0.1:%d/float.html", GSERV_PORT];
            NSURL* url = [NSURL URLWithString:wwwpath];
            NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
            [webview loadRequest:req];
            
            BKSHIDEventRegisterEventCallback([](void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
                CFArrayRef ref = IOHIDEventGetChildren(event);
                if (!ref || CFArrayGetCount(ref) == 0) {
                    return;
                }
                /*
                 按下:
                    x=161 y=126 range=1 touch=1 mask=range|touch
                    x=161 y=126 range=0 touch=0 mask=range|touch
                 拖动:
                    x=157 y=123 range=1 touch=1 mask=range|touch
                    x=156 y=135 range=1 touch=1 mask=position
                    x=156 y=139 range=1 touch=1 mask=position
                    x=156 y=14  range=1 touch=1 mask=position
                    x=157 y=146 range=0 touch=0 mask=range|touch
                 */
                static int last_x = -1, last_y = -1;
                event = (IOHIDEventRef)CFArrayGetValueAtIndex(ref, 0);
                int x = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerX);
                int y = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerY);
                int range = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerRange);
                int touch = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerTouch);
                int mask = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerEventMask);
                //NSLog(@"BKSHIDEventRegisterEventCallback x=%d y=%d range=%d touch=%d mask=%d", x, y, range, touch, mask);
                if ((mask & kIOHIDDigitizerEventTouch) != 0) {
                    if (touch != 0) { // touch_down
                        last_x = x;
                        last_y = y;
                    } else { // touch_up
                        if (last_x == x && last_y == y) {
                            //NSLog(@"%@ click (%d,%d)", log_prefix, x, y);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_app.webview stringByEvaluatingJavaScriptFromString:@"window.app.invset_enable()"];
                            });
                        }
                        last_x = -1;
                        last_y = -1;
                    }
                } else if ((mask & kIOHIDDigitizerEventPosition) != 0) { // touch_move
                    //NSLog(@"%@ move (%d,%d)", log_prefix, x, y);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CGRect rt = CGRectMake(x - FLOAT_WIDTH / 2, y - FLOAT_HEIGHT / 2, FLOAT_WIDTH, FLOAT_HEIGHT);
                        [_app.webview setFrame:rt];
                    });
                }
            });
        }
    }
}
- (void)webViewDidFinishLoad:(UIWebView*)webview {
    NSString* surl = webview.request.URL.absoluteString;
    NSLog(@"%@ webViewDidFinishLoad %@", log_prefix, surl);
    [_mainWnd addSubview:webview];
    [_mainWnd bringSubviewToFront:webview];
}
- (void)webView:(UIWebView*)webview didFailLoadWithError:(NSError*)error {
    NSString* surl = webview.request.URL.absoluteString;
    NSLog(@"%@ didFailLoadWithError %@", log_prefix, surl);
    [NSThread sleepForTimeInterval:0.5];
    if (surl.length == 0) { // 服务端未初始化时url会被置空
        surl = [NSString stringWithFormat:@"http://127.0.0.1:%d", GSERV_PORT];
    }
    NSURL* url = [NSURL URLWithString:surl];
    NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3.0];
    [webview loadRequest:req];
}
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* url = request.URL.absoluteString;
    NSLog(@"%@ shouldStartLoadWithRequest %@", log_prefix, url);
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
        // IOPMPowerSource:AppleARMPMUPowerSource:AppleARMPMUCharger
        //      IOAccessoryTransport:IOAccessoryPowerSource:AppleARMPMUAccessoryPS
        // AppleSmartBattery >=iPhone11才有, 且数据相同
    }
    return serv;
}

static NSDictionary* getBatSlimInfo(NSDictionary* info) {
    NSMutableDictionary* filtered_info = [NSMutableDictionary dictionary];
    NSArray* keep = @[
        @"Amperage", @"AppleRawCurrentCapacity", @"BatteryInstalled", @"BootVoltage", @"CurrentCapacity", @"CycleCount", @"DesignCapacity", @"ExternalChargeCapable", @"ExternalConnected",
        @"InstantAmperage", @"IsCharging", @"NominalChargeCapacity", @"PostChargeWaitSeconds", @"PostDischargeWaitSeconds", @"Serial", @"Temperature",
        @"UpdateTime", @"Voltage"];
    for (NSString* key in info) {
        if ([keep containsObject:key]) {
            filtered_info[key] = info[key];
        }
    }
    if (filtered_info[@"NominalChargeCapacity"] == nil) {
        if (info[@"AppleRawMaxCapacity"] != nil) {
            filtered_info[@"NominalChargeCapacity"] = info[@"AppleRawMaxCapacity"];
        }
    }
    if (info[@"AdapterDetails"] != nil) {
        NSDictionary* adaptor_info = info[@"AdapterDetails"];
        NSMutableDictionary* filtered_adaptor_info = [NSMutableDictionary dictionary];
        keep = @[@"Current", @"Description", @"IsWireless", @"Manufacturer", @"Name", @"Voltage", @"Watts"];
        for (NSString* key in adaptor_info) {
            if ([keep containsObject:key]) {
                filtered_adaptor_info[key] = adaptor_info[key];
            }
        }
        if (filtered_adaptor_info[@"Voltage"] == nil) {
            if (adaptor_info[@"AdapterVoltage"] != nil) {
                filtered_adaptor_info[@"Voltage"] = adaptor_info[@"AdapterVoltage"];
            }
        }
        filtered_info[@"AdapterDetails"] = filtered_adaptor_info;
    }
    return filtered_info;
}

static int getBatInfoWithServ(io_service_t serv, NSDictionary* __strong* pinfo) {
    CFMutableDictionaryRef prop = nil;
    IORegistryEntryCreateCFProperties(serv, &prop, kCFAllocatorDefault, 0);
    if (prop == nil) {
        return -2;
    }
    NSMutableDictionary* info = (__bridge_transfer NSMutableDictionary*)prop;
    *pinfo = getBatSlimInfo(info);
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
        *pinfo = getBatSlimInfo(info);
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

static BOOL g_enable = YES;
static BOOL g_enable_floatwnd = NO;
static int g_jbtype = -1;
static NSMutableDictionary* cache_kv = nil;

static id getlocalKV(NSString* key) {
    if (cache_kv == nil) {
        NSString* path = [NSHomeDirectory() stringByAppendingString:@"/aldente.conf"];
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    if (cache_kv == nil) {
        return nil;
    }
    return cache_kv[key];
}

static void setlocalKV(NSString* key, id val) {
    NSString* path = [NSHomeDirectory() stringByAppendingString:@"/aldente.conf"];
    if (cache_kv == nil) {
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if (cache_kv == nil) {
            cache_kv = [NSMutableDictionary new];
        }
    }
    cache_kv[key] = val;
    [cache_kv writeToFile:path atomically:YES];
}

void do_in_mainqueue(void(^Block)()) {
    if ([NSThread isMainThread]) {
        Block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), Block);
    }
}

static void perform_acccharge(BOOL flag) {
    static NSMutableDictionary* cache_status = nil;
    NSNumber* acc_charge = getlocalKV(@"acc_charge");
    NSNumber* acc_charge_airmode = getlocalKV(@"acc_charge_airmode");
    NSNumber* acc_charge_blue = getlocalKV(@"acc_charge_blue");
    NSNumber* acc_charge_bright = getlocalKV(@"acc_charge_bright");
    NSNumber* acc_charge_lpm = getlocalKV(@"acc_charge_lpm");
    if (acc_charge.boolValue) {
        if (flag) { // 修改状态
            cache_status = [NSMutableDictionary new];
            if (acc_charge_airmode.boolValue) {
                setAirEnable(YES);
            }
            if (acc_charge_blue.boolValue) {
                setBlueEnable(NO);
            }
            if (acc_charge_bright.boolValue) {
                float val = getBrightness();
                cache_status[@"acc_charge_bright"] = @(val);
                setBrightness(0.0);
            }
            if (acc_charge_lpm.boolValue) {
                setLPMEnable(YES);
            }
        } else if (cache_status != nil) { // 还原状态
            setAirEnable(NO);
            setBlueEnable(YES);
            setLPMEnable(NO);
            if (cache_status[@"acc_charge_bright"] != nil) {
                NSNumber* acc_charge_bright = cache_status[@"acc_charge_bright"];
                setBrightness(acc_charge_bright.floatValue);
            }
            cache_status = nil;
        }
    }
}

static void onBatteryEvent(io_service_t serv) {
    @autoreleasepool {
        NSDictionary* old_bat_info = bat_info;
        if (0 == getBatInfoWithServ(serv, &bat_info) && g_enable) {
            NSString* mode = getlocalKV(@"mode");
            NSNumber* charge_below = getlocalKV(@"charge_below");
            NSNumber* charge_above = getlocalKV(@"charge_above");
            NSNumber* enable_temp = getlocalKV(@"enable_temp");
            NSNumber* charge_temp_above = getlocalKV(@"charge_temp_above");
            NSNumber* charge_temp_below = getlocalKV(@"charge_temp_below");
            NSNumber* capacity = bat_info[@"CurrentCapacity"];
            NSNumber* is_charging = bat_info[@"IsCharging"];
            NSNumber* temperature_ = bat_info[@"Temperature"];
            int temperature = temperature_.intValue / 100;
            if (enable_temp.boolValue && temperature >= charge_temp_above.intValue) {
                if (is_charging.boolValue) {
                    NSLog(@"%@ stop charging for high temperature", log_prefix);
                    [Service.inst localPush:@"Stop charging" interval:3600];
                    if (0 == setChargeStatus(NO)) {
                        perform_acccharge(NO);
                    }
                    return;
                }
            }
            if (capacity.intValue >= charge_above.intValue) {
                if (is_charging.boolValue) {
                    NSLog(@"%@ stop charging for capacity", log_prefix);
                    [Service.inst localPush:@"Stop charging" interval:3600];
                    if (0 == setChargeStatus(NO)) {
                        perform_acccharge(NO);
                    }
                }
                return; // 电量满禁止操作
            }
            if ([mode isEqualToString:@"charge_on_plug"]) { // 此状态下禁用charge_below
                if (isAdaptorNewConnect(old_bat_info, bat_info)) {
                    NSLog(@"%@ start charging for plug in", log_prefix);
                    [Service.inst localPush:@"Start charging" interval:3600];
                    if (0 == setChargeStatus(YES)) {
                        perform_acccharge(YES);
                    }
                    return;
                }
                if (enable_temp.boolValue && temperature <= charge_temp_below.intValue) {
                    NSLog(@"%@ start charging for low temperature", log_prefix);
                    [Service.inst localPush:@"Start charging" interval:3600];
                    if (0 == setChargeStatus(YES)) {
                        perform_acccharge(YES);
                    }
                    return;
                }
                return;
            }
            if (capacity.intValue <= charge_below.intValue) {
                if (!is_charging.boolValue) {
                    if (isAdaptorConnect(bat_info)) {
                        NSLog(@"%@ start charging for capacity", log_prefix);
                        [Service.inst localPush:@"Start charging" interval:3600];
                        if (0 == setChargeStatus(YES)) {
                            perform_acccharge(YES);
                        }
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
        @"charge_temp_below": @10,
        @"acc_charge": @NO,
        @"acc_charge_airmode": @YES,
        @"acc_charge_blue": @NO,
        @"acc_charge_bright": @NO,
        @"acc_charge_lpm": @YES,
    };
    for (NSString* key in def_dic) {
        id val = getlocalKV(key);
        if (val == nil) {
            setlocalKV(key, def_dic[key]);
        }
    }
}

static void showFloatwnd(BOOL flag) {
    static int floatwnd_pid = -1;
    if (flag) { // open
        if (floatwnd_pid == -1) {
            spawn(@[getAppEXEPath(), @"floatwnd"], nil, nil, &floatwnd_pid, SPAWN_FLAG_NOWAIT);
        }
    } else { // close
        if (floatwnd_pid != -1) {
            kill(floatwnd_pid, SIGKILL);
            floatwnd_pid = -1;
        }
    }
}

static NSDictionary* handleReq(NSDictionary* nsreq) {
    NSString* api = nsreq[@"api"];
    if ([api isEqualToString:@"get_conf"]) {
        NSMutableDictionary* kv = [cache_kv mutableCopy];
        kv[@"enable"] = @(g_enable);
        kv[@"floatwnd"] = @(g_enable_floatwnd);
        return @{
            @"status": @0,
            @"data": kv,
        };
    } else if ([api isEqualToString:@"set_conf"]) {
        NSString* key = nsreq[@"key"];
        id val = nsreq[@"val"];
        if ([key isEqualToString:@"enable"]) {
            g_enable = [val boolValue];
            if (!g_enable) {
                setChargeStatus(YES);
            }
        } else if ([key isEqualToString:@"floatwnd"]) {
            g_enable_floatwnd = [val boolValue];
            showFloatwnd(g_enable_floatwnd);
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
        if (g_jbtype != JBTYPE_TROLLSTORE) {
            spawn(@[@"launchctl", @"unload", @(ROOTDIR "/Library/LaunchDaemons/chaoge.ChargeLimiter.plist")], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
            exit(0);
        });
        return @{
            @"status": @0
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
    if (g_enable_floatwnd) { // 有悬浮窗则忽略通知
        return;
    }
    static NSMutableDictionary* lastRemindDic = [NSMutableDictionary new];
    static void (^Block)(NSString*) = ^(NSString* msg) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"ChargeLimiter";
        content.body = msg;
        NSTimeInterval timeInterval = [[NSDate dateWithTimeIntervalSinceNow:1] timeIntervalSinceNow];
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:NO];
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"ChargeLimiter" content:content trigger:trigger];
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
        isBlueEnable(); // init
        isLPMEnable();
    }
}
@end


int main(int argc, char** argv) {
    @autoreleasepool {
        g_jbtype = getJBType();
        if (argc == 1) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (!localPortOpen(GSERV_PORT)) {
                    NSLog(@"%@ start daemon", log_prefix);
                    if (g_jbtype == JBTYPE_TROLLSTORE) {
                        spawn(@[getAppEXEPath(), @"daemon"], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
                    } else {
                        //spawn(@[@"launchctl", @"load", @(ROOTDIR "/Library/LaunchDaemons/chaoge.ChargeLimiter.plist")], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
                    }
                }
            });
            return UIApplicationMain(argc, argv, nil, @"AppDelegate");
        } else if (argc > 1) {
            if (0 == strcmp(argv[1], "daemon")) {
                if (g_jbtype == JBTYPE_TROLLSTORE) {
                    signal(SIGHUP, SIG_IGN);
                    signal(SIGTERM, SIG_IGN); // 防止App被Kill以后daemon退出
                } else {
                    platformize_me(); // for jailbreak
                    set_memory_limit(getpid(), 80);
                }
                [Service.inst serve];
                atexit_b(^{
                    [LSApplicationWorkspace.defaultWorkspace removeObserver:Service.inst];
                    setChargeStatus(YES);
                    showFloatwnd(NO);
                });
                [NSRunLoop.mainRunLoop run];
            } else if (0 == strcmp(argv[1], "get_bat_info")) {
                BOOL slim = argc == 3;
                getBatInfo(&bat_info, slim);
                NSLog(@"%@", bat_info);
            } else if (0 == strcmp(argv[1], "floatwnd")) {
                g_wind_type = 1;
                static id<UIApplicationDelegate> appDelegate = [AppDelegate new];
                UIApplicationInstantiateSingleton(UIApplication.class);
                [UIApplication.sharedApplication setDelegate:appDelegate];
                [UIApplication.sharedApplication __completeAndRunAsPlugin];
                CFRunLoopRun();
            }
        }
        return -1;
    }
}

