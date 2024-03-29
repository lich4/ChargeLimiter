#import <Foundation/Foundation.h>
#import <GCDWebServers/GCDWebServers.h>
#import <IOKit/IOKit.h>
#include <IOKit/hid/IOHIDService.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#include "utils.h"

#define PRODUCT         "ChargeLimiter"
#define GSERV_PORT      1230
#define TRACE           false
#define FLOAT_ORIGINX   100
#define FLOAT_ORIGINY   100
#define FLOAT_WIDTH     80
#define FLOAT_HEIGHT    60

NSString* log_prefix = @(PRODUCT "Logger");
static NSDictionary* bat_info = nil;
static BOOL g_enable = YES;
static BOOL g_enable_floatwnd = NO;
static BOOL g_use_smart = NO;
static int g_jbtype = -1;
static int g_wind_type = 0; // 1: HUD
static int g_serv_boot = 0;

static NSDictionary* handleReq(NSDictionary* nsreq);
static void start_daemon();

extern "C" {
void BKSDisplayServicesStart();
void BKSHIDEventRegisterEventCallback(void (*)(void*, void*, IOHIDServiceRef, IOHIDEventRef));
void UIApplicationInstantiateSingleton(id aclass);
void UIApplicationInitialize();
}

@interface UIApplication(Private)
- (void)__completeAndRunAsPlugin;
- (void)_enqueueHIDEvent:(IOHIDEventRef)event;
- (void)_run;
@end

@interface UIWindow(Private)
- (unsigned int)_contextId;
@end

@interface SBSAccessibilityWindowHostingController: NSObject
- (void)registerWindowWithContextID:(unsigned)arg1 atLevel:(double)arg2;
@end

@interface FBSOrientationUpdate: NSObject
- (UIDeviceOrientation)orientation;
- (CGFloat)duration;
@end

@interface FBSOrientationObserver: NSObject
- (void)setHandler:(void(^)(FBSOrientationUpdate*))handler;
@end

@interface Service: NSObject<UNUserNotificationCenterDelegate> 
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)initLocalPush;
- (void)localPush:(NSString*)title msg:(NSString*)msg;
@end

@interface AppDelegate : UIViewController<UIApplicationDelegate, UIWindowSceneDelegate, UIWebViewDelegate>
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

static NSMutableDictionary* cache_kv = nil;
#define CONF_PATH   "/var/root/aldente.conf"
static id getlocalKV(NSString* key) {
    if (cache_kv == nil) {
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:@CONF_PATH];
    }
    if (cache_kv == nil) {
        return nil;
    }
    return cache_kv[key];
}

static void setlocalKV(NSString* key, id val) {
    if (cache_kv == nil) {
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:@CONF_PATH];
        if (cache_kv == nil) {
            cache_kv = [NSMutableDictionary new];
        }
    }
    cache_kv[key] = val;
    [cache_kv writeToFile:@CONF_PATH atomically:YES];
}

@implementation AppDelegate {
    NSString* initUrl;
}
static UIView* _mainWnd = nil;
static AppDelegate* _app = nil;
- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)connectionOptions API_AVAILABLE(ios(13.0)) {
    if (connectionOptions.URLContexts != nil) {
        [self scene:scene openURLContexts:connectionOptions.URLContexts];
    }
}
- (void)scene:(UIScene*)scene openURLContexts:(NSSet*)URLContexts API_AVAILABLE(ios(13.0)) {
    if (URLContexts == nil || URLContexts.count == 0) {
        return;
    }
    UIOpenURLContext* urlContext = URLContexts.allObjects.firstObject;
    NSURL* url = urlContext.URL; // cl:///(charge|nocharge)(/exit)
    for (NSString* cmd in url.pathComponents) {
        if ([cmd isEqualToString:@"charge"]) {
            handleReq(@{
                @"api": @"set_charge_status",
                @"flag": @YES,
            });
        } else if ([cmd isEqualToString:@"nocharge"]) {
            handleReq(@{
                @"api": @"set_charge_status",
                @"flag": @NO,
            });
        } else if ([cmd hasPrefix:@"exit"]) {
            int n = 1;
            if (cmd.length > 4) {
                NSString* nn = [cmd substringFromIndex:4];
                n = [nn intValue];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, n * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                exit(0);
            });
        }
    }
}
- (void)sceneWillEnterForeground:(UIScene*)scene API_AVAILABLE(ios(13.0)) {
    _mainWnd = self.window;
}
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
    if (g_wind_type == 0) {
        _mainWnd = self.window;
    } else if (g_wind_type == 1) { // from TrollSpeed
        self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.rootViewController = [AppDelegate new];
        self.window.windowLevel = 10000010.0;
        self.window.hidden = NO;
        [self.window makeKeyAndVisible];
        static SBSAccessibilityWindowHostingController* _accessController = [objc_getClass("SBSAccessibilityWindowHostingController") new];
        if (_accessController != nil) {
            unsigned int _contextId = [self.window _contextId];
            double windowLevel = [self.window windowLevel];
            [_accessController registerWindowWithContextID:_contextId atLevel:windowLevel];
        }
    }
    return YES;
}
- (void)speedUpWebView:(UIWebView*)webview { // 优化UIWebView反应速度
    // 不用WKWebView的原因: TrollStore环境下,需要no-container/no-sandbox执行子进程,而WKWebView在iOS>=16下需要container-required才能工作,考虑和越狱的一致性选择UIWebView
    // 如果不执行js也可以用SFSafariViewController替代
    for (UIView* view in webview.scrollView.subviews) {
        if ([view.class.description isEqualToString:@"UIWebBrowserView"]) {
            NSArray* gestures = view.gestureRecognizers;
            for (UIGestureRecognizer* gestureRecognizer in gestures) {
                if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class]) {
                    UITapGestureRecognizer* tapRecognizer = (UITapGestureRecognizer*)gestureRecognizer;
                    if (tapRecognizer.numberOfTapsRequired > 1 || tapRecognizer.numberOfTouchesRequired > 1) {
                        gestureRecognizer.enabled = NO;
                    }
                } else if ([gestureRecognizer isKindOfClass:UILongPressGestureRecognizer.class]) {
                    gestureRecognizer.enabled = NO;
                } else if ([gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
                    gestureRecognizer.enabled = NO;
                } else {
                    NSString* type = NSStringFromClass(gestureRecognizer.class);
                    if ([type isEqualToString:@"UIWebTouchEventsGestureRecognizer"]) {
                    } else {
                        gestureRecognizer.enabled = NO;
                    }
                }
            }
            break;
        }
    }
}
- (void)viewDidAppear:(BOOL)animated {
    @autoreleasepool {
        [super viewDidAppear:animated];
        static CGSize scrSize = UIScreen.mainScreen.bounds.size;
        _app = self;
        if (g_wind_type == 0) {
            NSString* imgpath = [NSString stringWithFormat:@"%@/splash.png", NSBundle.mainBundle.bundlePath];
            UIImage* image = [UIImage imageWithContentsOfFile:imgpath];
            UIImageView* imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, scrSize.width, scrSize.height)];
            imageview.image = image;
            imageview.contentMode = UIViewContentModeScaleAspectFill;
            [_mainWnd addSubview:imageview];
            
            UIWebView* webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, scrSize.width, scrSize.height)];
            webview.delegate = self;
            self.webview = webview;
            initUrl = [NSString stringWithFormat:@"http://127.0.0.1:%d", GSERV_PORT];
            NSURL* url = [NSURL URLWithString:initUrl];
            NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
            [webview loadRequest:req];
        } else if (g_wind_type == 1) {
            _mainWnd = self.view;
            UIWebView* webview = [[UIWebView alloc] initWithFrame:CGRectMake(FLOAT_ORIGINX, FLOAT_ORIGINY, FLOAT_WIDTH, FLOAT_HEIGHT)]; // 窗口大小
            webview.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
            webview.opaque = NO;
            webview.delegate = self;
            self.webview = webview;
            initUrl = [NSString stringWithFormat:@"http://127.0.0.1:%d/float.html", GSERV_PORT];
            NSURL* url = [NSURL URLWithString:initUrl];
            NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0];
            [webview loadRequest:req];
            BKSHIDEventRegisterEventCallback([](void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
                @autoreleasepool {
                    IOHIDEventType type = IOHIDEventGetType(event);
                    if (type != kIOHIDEventTypeDigitizer) {
                        return;
                    }
                    CFArrayRef ref = IOHIDEventGetChildren(event);
                    if (!ref || CFArrayGetCount(ref) == 0) {
                        return;
                    }
                    IOHIDEventRef event2 = (IOHIDEventRef)CFArrayGetValueAtIndex(ref, 0);
                    int x = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerX);
                    int y = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerY);
                    int mask = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerEventMask);
                    if ((mask & kIOHIDDigitizerEventPosition) != 0) { // touch_move
                        dispatch_async(dispatch_get_main_queue(), ^{
                            int f_x = MAX(x - FLOAT_WIDTH/2, 0);
                            int f_y = MAX(y - FLOAT_HEIGHT/2, 0);
                            f_x = MIN(f_x, scrSize.width - FLOAT_WIDTH);
                            f_y = MIN(f_y, scrSize.height - FLOAT_HEIGHT);
                            CGRect rt = _app.webview.frame;
                            [_app.webview setFrame:CGRectMake(f_x, f_y, rt.size.width, rt.size.height)];
                        });
                    } else {
                        [UIApplication.sharedApplication _enqueueHIDEvent:event];
                    }
                }
            });
            
            static UIDeviceOrientation cur_orient = UIDevice.currentDevice.orientation;
            static FBSOrientationObserver* orientObserver = [objc_getClass("FBSOrientationObserver") new];
            [orientObserver setHandler:^(FBSOrientationUpdate* update) {
                if (update.orientation == cur_orient) {
                    return;
                }
                cur_orient = update.orientation;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_app.webview setTransform:CGAffineTransformMakeRotation(getOrientAngle(update.orientation))];
                });
            }];
            
            static CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
            
            CFNotificationCenterAddObserver(center, (__bridge const void *)self, [](CFNotificationCenterRef center, void* observer, CFStringRef name, void const* object, CFDictionaryRef userInfo) {
                @autoreleasepool {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                        NSString* bid = getFrontMostBid();
                        NSString* self_bid = NSBundle.mainBundle.bundleIdentifier;
                        if (bid == nil || [bid isEqualToString:self_bid] || [bid isEqualToString:@"com.apple.springboard"]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _app.webview.hidden = NO;
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _app.webview.hidden = YES;
                            });
                        }
                    });
                }
            }, CFSTR("com.apple.mobile.SubstantialTransition"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        }
    }
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    UIDeviceOrientation orient = UIDevice.currentDevice.orientation;
    if (orient == UIDeviceOrientationPortrait || orient == UIDeviceOrientationPortraitUpsideDown) {
        CGRect rt = _app.webview.frame;
        [_app.webview setFrame:CGRectMake(rt.origin.x, rt.origin.y, MIN(rt.size.width, rt.size.height), MAX(rt.size.width, rt.size.height))];
    } else if (orient == UIDeviceOrientationLandscapeLeft || orient == UIDeviceOrientationLandscapeRight) {
        CGRect rt = _app.webview.frame;
        [_app.webview setFrame:CGRectMake(rt.origin.x, rt.origin.y, MAX(rt.size.width, rt.size.height), MIN(rt.size.width, rt.size.height))];
    }
}
- (void)webViewDidFinishLoad:(UIWebView*)webview {
    [_mainWnd addSubview:webview];
    [_mainWnd bringSubviewToFront:webview];
    [self speedUpWebView: webview];
    if (isDarkMode()) {
        [webview stringByEvaluatingJavaScriptFromString:@"window.app.switch_dark(true)"];
    }
    [webview stringByEvaluatingJavaScriptFromString:@"window.source='CL'"];
}
- (void)webView:(UIWebView*)webview didFailLoadWithError:(NSError*)error {
    NSString* surl = webview.request.URL.absoluteString;
    [NSThread sleepForTimeInterval:0.5];
    if (surl.length == 0) { // 服务端未初始化时url会被置空
        surl = initUrl;
    }
    NSURL* url = [NSURL URLWithString:surl];
    NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3.0];
    [webview loadRequest:req];
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* url = request.URL.absoluteString;
    if ([url isEqualToString:@"safari://"]) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:initUrl]];
        return NO;
    } else if ([url isEqualToString:@"cl://start_daemon"]) {
        start_daemon();
        return NO;
    }
    return YES;
}
@end


static io_service_t getIOPMPSServ() {
    static io_service_t serv = IO_OBJECT_NULL;
    if (serv == IO_OBJECT_NULL) {
        NSNumber* adv_prefer_smart = getlocalKV(@"adv_prefer_smart");
        if (adv_prefer_smart.boolValue) {
            serv = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery")); // >=iPhone8
        }
        if (serv != IO_OBJECT_NULL) {
            g_use_smart = YES;
        } else {// SmartBattery not support, roll back to use IOPS
            serv = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
            // IOPMPowerSource:AppleARMPMUPowerSource:AppleARMPMUCharger
            //      IOAccessoryTransport:IOAccessoryPowerSource:AppleARMPMUAccessoryPS
            g_use_smart = NO;
        }
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
    if (serv == IO_OBJECT_NULL) {
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

static int setInflowStatus(BOOL flag) {
    io_service_t serv = getIOPMPSServ();
    if (serv == IO_OBJECT_NULL) {
        return -1;
    }
    // iPhone>=8 ExternalConnected重置可消除120秒延迟,且更新系统充电图标
    NSMutableDictionary* props = [NSMutableDictionary new];
    props[@"ExternalConnected"] = @(flag);
    kern_return_t ret = IORegistryEntrySetCFProperties(serv, (__bridge CFTypeRef)props);
    if (ret != 0) {
        return -2;
    }
    return 0;
}

static void tryEnableInflowIfDisabled() {
    NSNumber* adv_disable_inflow = getlocalKV(@"adv_disable_inflow");
    if (adv_disable_inflow.boolValue) {
        static int last_check_time = (int)time(0);
        int ts = (int)time(0);
        if (ts - last_check_time > 60) {
            last_check_time = ts;
            setInflowStatus(YES);
        }
    }
}

static BOOL isAdaptorConnect(NSDictionary* info) {
    // 某些充电器ExternalConnected为false,这里使用ExternalChargeCapable
    NSNumber* ExternalChargeCapable = info[@"ExternalChargeCapable"];
    NSNumber* ExternalConnected = info[@"ExternalConnected"];
    if (!ExternalConnected.boolValue) {
        tryEnableInflowIfDisabled();
    }
    if (ExternalChargeCapable != nil) {
        return ExternalChargeCapable.boolValue;
    }
    return NO;
}

static BOOL isAdaptorNewConnect(NSDictionary* oldInfo, NSDictionary* info) {
    NSNumber* old_ExternalChargeCapable = oldInfo[@"ExternalChargeCapable"];
    NSNumber* ExternalChargeCapable = info[@"ExternalChargeCapable"];
    NSNumber* ExternalConnected = info[@"ExternalConnected"];
    if (!ExternalConnected.boolValue) {
        tryEnableInflowIfDisabled();
    }
    if (!old_ExternalChargeCapable.boolValue && ExternalChargeCapable.boolValue) {
        return YES;
    }
    return NO;
}

static int setChargeStatus(BOOL flag) {
    NSNumber* adv_predictive_inhibit_charge = getlocalKV(@"adv_predictive_inhibit_charge");
    io_service_t serv = getIOPMPSServ();
    if (serv == IO_OBJECT_NULL) {
        return -1;
    }
    NSMutableDictionary* props = [NSMutableDictionary new];
    if (adv_predictive_inhibit_charge.boolValue) { // iOS>=13  目前测试PredictiveChargingInhibit在iOS>=13生效
        props[@"IsCharging"] = @YES;
        props[@"PredictiveChargingInhibit"] = @(!flag);
    } else { // iOS<=12
        props[@"IsCharging"] = @(flag);
        props[@"PredictiveChargingInhibit"] = @NO; // PredictiveChargingInhibit为IsCharging总开关
    }
    kern_return_t ret = IORegistryEntrySetCFProperties(serv, (__bridge CFTypeRef)props);
    if (ret != 0) {
        return -2;
    }
    return 0;
}

static int setBatteryStatus(BOOL flag) {
    NSNumber* adv_disable_inflow = getlocalKV(@"adv_disable_inflow");
    NSNumber* adv_skip_wait = getlocalKV(@"adv_skip_wait");
    int ret = 0;
    if (flag) {
        if (adv_disable_inflow.boolValue) {
            ret += setInflowStatus(flag);
        }
        ret += setChargeStatus(flag);
        if (adv_skip_wait.boolValue) {
            setInflowStatus(!flag);
            setInflowStatus(flag);
        }
    } else {
        ret += setChargeStatus(flag);
        if (adv_disable_inflow.boolValue) {
            ret += setInflowStatus(flag);
        }
        if (adv_skip_wait.boolValue) {
            setInflowStatus(!flag);
            setInflowStatus(flag);
        }
    }
    return ret;
}

static void resetBatteryStatus() {
    io_service_t serv = getIOPMPSServ();
    if (serv == IO_OBJECT_NULL) {
        return;
    }
    NSMutableDictionary* props = [NSMutableDictionary new];
    props[@"IsCharging"] = @YES;
    props[@"PredictiveChargingInhibit"] = @NO;
    props[@"ExternalConnected"] = @YES;
    IORegistryEntrySetCFProperties(serv, (__bridge CFTypeRef)props);
}

static void performAcccharge(BOOL flag) {
    static NSMutableDictionary* cache_status = nil;
    NSNumber* acc_charge = getlocalKV(@"acc_charge");
    NSNumber* acc_charge_airmode = getlocalKV(@"acc_charge_airmode");
    NSNumber* acc_charge_wifi = getlocalKV(@"acc_charge_wifi");
    NSNumber* acc_charge_blue = getlocalKV(@"acc_charge_blue");
    NSNumber* acc_charge_bright = getlocalKV(@"acc_charge_bright");
    NSNumber* acc_charge_lpm = getlocalKV(@"acc_charge_lpm");
    if (acc_charge.boolValue) {
        if (flag) { // 修改状态
            cache_status = [NSMutableDictionary new];
            if (acc_charge_airmode.boolValue) {
                setAirEnable(YES);
            }
            if (acc_charge_wifi.boolValue) {
                setWiFiEnable(NO); // todo 支持16
            }
            if (acc_charge_blue.boolValue) {
                setBlueEnable(NO);
            }
            if (acc_charge_bright.boolValue) {
                float val = getBrightness();
                cache_status[@"acc_charge_bright"] = @(val);
                setAutoBrightEnable(NO);
                setBrightness(0.0);
            }
            if (acc_charge_lpm.boolValue) {
                setLPMEnable(YES);
            }
        } else if (cache_status != nil) { // 还原状态
            if (acc_charge_airmode.boolValue) {
                setAirEnable(NO);
            }
            if (acc_charge_wifi.boolValue) {
                setWiFiEnable(YES);
            }
            if (acc_charge_blue.boolValue) {
                setBlueEnable(YES);
            }
            if (acc_charge_bright.boolValue) {
                if (cache_status[@"acc_charge_bright"] != nil) {
                    NSNumber* acc_charge_bright = cache_status[@"acc_charge_bright"];
                    setBrightness(acc_charge_bright.floatValue);
                }
                setAutoBrightEnable(YES);
            }
            if (acc_charge_lpm.boolValue) {
                setLPMEnable(NO);
            }
            cache_status = nil;
        }
    }
}

static NSDictionary* messages = @{
    @"en": @{
        @"stop_charge": @"Stop charging",
    },
    @"zh_CN": @{
        @"stop_charge": @"停止充电",
    },
    @"zh_TW": @{
        @"stop_charge": @"停止充電",
    }
};
static NSString* getMsgForLang(NSString* msgid, NSString* lang) {
    if (messages[lang] == nil) {
        lang = @"en";
    }
    return messages[lang][msgid];
}

static void performAction(NSString* msgid) {
    NSString* lang = getlocalKV(@"lang");
    NSString* action = getlocalKV(@"action");
    if (action.length == 0) {
        return;
    }
    if ([action isEqualToString:@"noti"]) {
        [Service.inst localPush:@PRODUCT msg:getMsgForLang(msgid, lang)];
    }
}

static NSMutableDictionary* getFilteredMDic(NSDictionary* dic, NSArray* filter) {
    NSMutableDictionary* mdic = [NSMutableDictionary new];
    for (NSString* key in filter) {
        if (dic[key] != nil) {
            mdic[key] = dic[key];
        }
    }
    return mdic;
}

static void updateStatistics() {
    int ts = (int)time(0);
    NSString* hourKey = [@(ts/3600) stringValue];
    NSString* dayKey = [@(ts/86400) stringValue];
    NSString* monthKey = [@(ts/2592000) stringValue];
    NSMutableArray* stat_hour = [getlocalKV(@"stat_hour") mutableCopy];
    NSMutableArray* stat_day = [getlocalKV(@"stat_day") mutableCopy];
    NSMutableArray* stat_month = [getlocalKV(@"stat_month") mutableCopy];
    if (stat_hour.count == 0 || ![stat_hour.lastObject[@"key"] isEqualToString:hourKey]) {
        NSMutableDictionary* mBatInfo = getFilteredMDic(bat_info, @[@"CurrentCapacity", @"InstantAmperage", @"IsCharging", @"Temperature", @"UpdateTime"]);
        mBatInfo[@"key"] = hourKey;
        [stat_hour addObject:mBatInfo];
        NSArray* new_stat = [stat_hour subarrayWithRange:NSMakeRange(MAX((int)stat_hour.count - 100, 0), MIN(stat_hour.count, 100))];
        setlocalKV(@"stat_hour", new_stat);
    }
    if (stat_day.count == 0 || ![stat_day.lastObject[@"key"] isEqualToString:dayKey]) {
        NSMutableDictionary* mBatInfo = getFilteredMDic(bat_info, @[@"CycleCount", @"NominalChargeCapacity", @"UpdateTime"]);
        mBatInfo[@"key"] = dayKey;
        [stat_day addObject:mBatInfo];
        NSArray* new_stat = [stat_day subarrayWithRange:NSMakeRange(MAX((int)stat_day.count - 100, 0), MIN(stat_day.count, 100))];
        setlocalKV(@"stat_day", new_stat);
    }
    if (stat_month.count == 0 || ![stat_month.lastObject[@"key"] isEqualToString:monthKey]) {
        NSMutableDictionary* mBatInfo = getFilteredMDic(bat_info, @[@"CycleCount", @"NominalChargeCapacity", @"UpdateTime"]);
        mBatInfo[@"key"] = monthKey;
        [stat_month addObject:mBatInfo];
        setlocalKV(@"stat_month", stat_month);
    }
}

static void onBatteryEvent(io_service_t serv) {
    @autoreleasepool {
        NSDictionary* old_bat_info = bat_info;
        if (0 != getBatInfoWithServ(serv, &bat_info)) {
            return;
        }
        updateStatistics();
        if (!g_enable) {
            return;
        }
        NSString* mode = getlocalKV(@"mode");
        NSNumber* charge_below = getlocalKV(@"charge_below");
        NSNumber* charge_above = getlocalKV(@"charge_above");
        NSNumber* enable_temp = getlocalKV(@"enable_temp");
        NSNumber* charge_temp_above = getlocalKV(@"charge_temp_above");
        NSNumber* charge_temp_below = getlocalKV(@"charge_temp_below");
        NSNumber* capacity = bat_info[@"CurrentCapacity"];
        NSNumber* is_charging = bat_info[@"IsCharging"];
        NSNumber* temperature_ = bat_info[@"Temperature"];
        if (capacity.intValue <= 5) {
            // 防止误用或意外造成无法充电
            if (!is_charging.boolValue) {
                setInflowStatus(YES);
                setBatteryStatus(YES);
                performAcccharge(YES);
            }
            return; // 电量过低禁止操作
        }
        int temperature = temperature_.intValue / 100;
        if (enable_temp.boolValue && temperature >= charge_temp_above.intValue) {
            if (is_charging.boolValue) {
                NSFileLog(@"stop charging for high temperature");
                if (0 == setBatteryStatus(NO)) {
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
                return;
            }
        }
        if (capacity.intValue >= charge_above.intValue) {
            if (is_charging.boolValue) {
                NSFileLog(@"stop charging for capacity");
                if (0 == setBatteryStatus(NO)) {
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
            }
            return; // 电量满禁止操作
        }
        if ([mode isEqualToString:@"charge_on_plug"]) {
            if (isAdaptorNewConnect(old_bat_info, bat_info)) {
                NSFileLog(@"start charging for plug in");
                if (0 == setBatteryStatus(YES)) {
                    performAcccharge(YES);
                }
                return;
            }
            if (enable_temp.boolValue && temperature <= charge_temp_below.intValue) {
                if (isAdaptorConnect(bat_info)) {
                    NSFileLog(@"start charging for low temperature");
                    if (0 == setBatteryStatus(YES)) {
                        performAcccharge(YES);
                    }
                    return;
                }
            }
        }
        if (capacity.intValue <= charge_below.intValue) {
            // 任何模式下强制低电充电
            // 1. 防止误用造成无法充电
            // 2. 禁流模式下电量下降后恢复充电
            if (!is_charging.boolValue) {
                if (isAdaptorConnect(bat_info)) {
                    NSFileLog(@"start charging for capacity");
                    if (0 == setBatteryStatus(YES)) {
                        performAcccharge(YES);
                    }
                    return;
                }
            }
        }
    }
}

static void initConf() {
    BOOL predictive_inhibit_charge_avail = getSysVerInt().majorVersion >= 13;
    NSDictionary* def_dic = @{
        @"mode": @"charge_on_plug",
        @"update_freq": @1,
        @"lang": @"",
        @"charge_below": @20,
        @"charge_above": @80,
        @"enable_temp": @NO,
        @"charge_temp_above": @35,
        @"charge_temp_below": @10,
        @"acc_charge": @NO,
        @"acc_charge_airmode": @YES,
        @"acc_charge_wifi": @NO,
        @"acc_charge_blue": @NO,
        @"acc_charge_bright": @NO,
        @"acc_charge_lpm": @YES,
        @"adv_prefer_smart": @YES, // iPhone8+ iOS13+
        @"adv_predictive_inhibit_charge": @(predictive_inhibit_charge_avail), // iPhone8+ iOS13+
        @"adv_disable_inflow": @NO, // all (iPhone8+ iOS13+会改变系统充电图标)
        @"adv_skip_wait": @NO,
        @"action": @"",
        @"stat_hour": @[],
        @"stat_day": @[],
        @"stat_month": @[],
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
            NSDictionary* param = @{
                @"close": getUnusedFds(),
            };
            spawn(@[getAppEXEPath(), @"floatwnd"], nil, nil, &floatwnd_pid, SPAWN_FLAG_NOWAIT, param);
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
        NSString* key = nsreq[@"key"];
        if (key == nil) {
            NSMutableDictionary* kv = [cache_kv mutableCopy];
            kv[@"enable"] = @(g_enable);
            kv[@"floatwnd"] = @(g_enable_floatwnd);
            //kv[@"dark"] = @(isDarkMode());  daemon获取到的结果不随系统变化,需要从app获取
            kv[@"sysver"] = getSysVer();
            kv[@"devmodel"] = getDevMdoel();
            kv[@"ver"] = getAppVer();
            kv[@"serv_boot"] = @(g_serv_boot);
            kv[@"sys_boot"] = @(get_sys_boottime());
            //kv[@"thermal_simulate_mode"] = getThermalSimulationMode(); // todo: 监视NSUserDefaults
            //kv[@"ppm_simulate_mode"] = getPPMSimulationMode();
            kv[@"use_smart"] = @(g_use_smart);
            return @{
                @"status": @0,
                @"data": kv,
            };
        } else {
            return @{
                @"status": @0,
                @"data": getlocalKV(key),
            };
        }
    } else if ([api isEqualToString:@"set_conf"]) {
        NSString* key = nsreq[@"key"];
        id val = nsreq[@"val"];
        if ([key isEqualToString:@"enable"]) {
            g_enable = [val boolValue];
            if (!g_enable) {
                resetBatteryStatus();
            }
        } else if ([key isEqualToString:@"floatwnd"]) {
            g_enable_floatwnd = [val boolValue];
            showFloatwnd(g_enable_floatwnd);
        } else {
            setlocalKV(key, val);
        }
        if ([key isEqualToString:@"action"]) {
            if ([val isEqualToString:@"noti"]) {
                [Service.inst initLocalPush];
            }
        } else if ([key isEqualToString:@"adv_predictive_inhibit_charge"]) {
            resetBatteryStatus();
        } else if ([key isEqualToString:@"adv_disable_inflow"]) {
            resetBatteryStatus();
        } else if ([key isEqualToString:@"adv_prefer_smart"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_global_queue(0, 0), ^{
                exit(0);
            });
        }
        return @{
            @"status": @0,
        };
    } else if ([api isEqualToString:@"get_bat_info"]) {
        return @{
            @"status": @0,
            @"data": bat_info,
        };
    } else if ([api isEqualToString:@"set_charge_status"]) {
        NSNumber* flag = nsreq[@"flag"];
        getBatInfo(&bat_info);
        int status = setChargeStatus(flag.boolValue);
        return @{
            @"status": @(status)
        };
    } else if ([api isEqualToString:@"set_inflow_status"]) {
        NSNumber* flag = nsreq[@"flag"];
        getBatInfo(&bat_info);
        int status = setInflowStatus(flag.boolValue);
        return @{
            @"status": @(status)
        };
    } else if ([api isEqualToString:@"set_pb"]) {
        NSString* val = nsreq[@"val"];
        UIPasteboard* pb = [UIPasteboard generalPasteboard];
        pb.string = val;
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
                NSFileLog(@"uninstalled, exit"); // 卸载时旧版daemon自动退出
                exit(0);
            }
        }
    }
}
- (void)applicationsDidInstall:(NSArray<LSApplicationProxy*>*)list {
    for (LSApplicationProxy* proxy in list) {
        if ([proxy.bundleIdentifier isEqualToString:self->bid]) {
            NSFileLog(@"updated, exit"); // 覆盖安装时旧版daemon自动退出
            exit(0);
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
    center.delegate = self;
    // getNotificationSettingsWithCompletionHandler返回结果不准确,忽略
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError* error) {
    }];
}
- (void)localPush:(NSString*)title msg:(NSString*)msg {
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = msg;
    content.sound = UNNotificationSound.defaultSound;
    NSTimeInterval timeInterval = [[NSDate dateWithTimeIntervalSinceNow:1] timeIntervalSinceNow];
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:title content:content trigger:trigger];
    [center addNotificationRequest:request withCompletionHandler:nil];
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
        NSDictionary* options = @{
            @"Port": @(GSERV_PORT),
            @"BindToLocalhost": @YES,
        };
        BOOL status = [_webServer startWithOptions:options error:nil];
        if (!status) {
            NSLog(@"%@ serve failed, exit", log_prefix);
            exit(0);
        }
        getBatInfo(&bat_info);
        IONotificationPortRef port = IONotificationPortCreate(kIOMasterPortDefault);
        CFRunLoopSourceRef runSrc = IONotificationPortGetRunLoopSource(port);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runSrc, kCFRunLoopDefaultMode);
        io_service_t serv = getIOPMPSServ();
        if (serv != IO_OBJECT_NULL) {
            io_object_t noti = IO_OBJECT_NULL;
            IOServiceAddInterestNotification(port, serv, "IOGeneralInterest", [](void* refcon, io_service_t service, uint32_t type, void* args) {
                @synchronized (Service.inst) {
                    onBatteryEvent(service);
                }
            }, nil, &noti);
        }
        [LSApplicationWorkspace.defaultWorkspace addObserver:self];
        isBlueEnable(); // init
        isLPMEnable();
    }
}
@end


// from TrollSpeed
#if __arm64e__
#include <ptrauth.h>
#endif

@interface UIEventDispatcher : NSObject
- (void)_installEventRunLoopSources:(CFRunLoopRef)arg1;
@end

@interface UIEventFetcher : NSObject
- (void)_receiveHIDEvent:(IOHIDEventRef)arg1;
- (void)setEventFetcherSink:(UIEventDispatcher *)arg1;
@end

@interface HUDMainApplication : UIApplication
@end

static void* make_sym_readable(void *ptr) {
#if __arm64e__
    if (!ptr) return ptr;
    ptr = ptrauth_strip(ptr, ptrauth_key_function_pointer);
#endif
    return ptr;
}

static void* make_sym_callable(void *ptr) {
#if __arm64e__
    if (!ptr) return ptr;
    ptr = ptrauth_sign_unauthenticated(ptrauth_strip(ptr, ptrauth_key_function_pointer), ptrauth_key_function_pointer, 0);
#endif
    return ptr;
}

@implementation HUDMainApplication
- (instancetype)init {
    self = [super init];
    do {
        UIEventDispatcher* dispatcher = (UIEventDispatcher*)[self valueForKey:@"eventDispatcher"];
        if (!dispatcher) {
            break;
        }
        if ([dispatcher respondsToSelector:@selector(_installEventRunLoopSources:)]) { // -[UIApplication _run]
            CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
            [dispatcher _installEventRunLoopSources:mainRunLoop];
        } else { // iOS>=16?
            IMP runMethodIMP = class_getMethodImplementation([self class], @selector(_run));
            if (!runMethodIMP) {
                break;
            }
            uint32_t *runMethodPtr = (uint32_t *)make_sym_readable((void *)runMethodIMP);
            void (*orig_UIEventDispatcher__installEventRunLoopSources_)(id _Nonnull, SEL _Nonnull, CFRunLoopRef) = NULL;
            for (int i = 0; i < 0x140; i++) {
                // mov x2, x0
                // mov x0, x?
                if (runMethodPtr[i] != 0xaa0003e2 || (runMethodPtr[i + 1] & 0xff000000) != 0xaa000000) {
                    continue;
                }
                // bl -[UIEventDispatcher _installEventRunLoopSources:]
                uint32_t blInst = runMethodPtr[i + 2];
                uint32_t *blInstPtr = &runMethodPtr[i + 2];
                if ((blInst & 0xfc000000) != 0x94000000) {
                    continue;
                }
                int32_t blOffset = blInst & 0x03ffffff;
                if (blOffset & 0x02000000)
                    blOffset |= 0xfc000000;
                blOffset <<= 2;
                uint64_t blAddr = (uint64_t)blInstPtr + blOffset;
                // cbz x0, loc_?????????
                uint32_t cbzInst = *((uint32_t *)make_sym_readable((void *)blAddr));
                if ((cbzInst & 0xff000000) != 0xb4000000) {
                    continue;
                }
                orig_UIEventDispatcher__installEventRunLoopSources_ = (void (*)(id  _Nonnull __strong, SEL _Nonnull, CFRunLoopRef))make_sym_callable((void *)blAddr);
            }
            if (!orig_UIEventDispatcher__installEventRunLoopSources_) {
                break;
            }
            CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
            orig_UIEventDispatcher__installEventRunLoopSources_(dispatcher, @selector(_installEventRunLoopSources:), mainRunLoop);
        }
        UIEventFetcher *fetcher = [objc_getClass("UIEventFetcher") new];
        [dispatcher setValue:fetcher forKey:@"eventFetcher"];
        if ([fetcher respondsToSelector:@selector(setEventFetcherSink:)]) {
            [fetcher setEventFetcherSink:dispatcher];
        } else { // iOS>=16?
            [fetcher setValue:dispatcher forKey:@"eventFetcherSink"];
        }
        [self setValue:fetcher forKey:@"eventFetcher"];
    } while (NO);
    
    Method mori_handlePan = class_getInstanceMethod(UIScrollView.class, @selector(handlePan:));
    Method mnew_handlePan = class_getInstanceMethod(HUDMainApplication.class, @selector(handlePan:));
    method_exchangeImplementations(mori_handlePan, mnew_handlePan);
    return self;
}
- (void)handlePan:(UIPanGestureRecognizer*)recognizer {
    // 避免悬浮窗滑动崩溃
}
@end

static void start_daemon() {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!localPortOpen(GSERV_PORT)) {
            if (g_jbtype == JBTYPE_TROLLSTORE) {
                spawn(@[getAppEXEPath(), @"daemon"], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
            }
        }
    });
}

int main(int argc, char** argv) {
    @autoreleasepool {
        g_jbtype = getJBType();
        if (argc == 1) {
            start_daemon();
            return UIApplicationMain(argc, argv, nil, @"AppDelegate");
        } else if (argc > 1) {
            if (0 == strcmp(argv[1], "daemon")) {
                g_serv_boot = (int)time(0);
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
                    resetBatteryStatus();
                    showFloatwnd(NO);
                    // 恢复电源连接
                });
                NSFileLog(@"daemon start");
                static NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:3600 repeats:YES block:^(NSTimer* timer) {
                    NSFileLog(@"daemon alive"); // 用于诊断
                }];
                [NSRunLoop.mainRunLoop run];
            } else if (0 == strcmp(argv[1], "floatwnd")) {
                g_wind_type = 1;
                static id<UIApplicationDelegate> appDelegate = [AppDelegate new];
                UIApplicationInstantiateSingleton(HUDMainApplication.class);
                static UIApplication* app = [UIApplication sharedApplication];
                [app setDelegate:appDelegate];
                [app __completeAndRunAsPlugin];
                CFRunLoopRun();
            } else if (0 == strcmp(argv[1], "get_bat_info")) {
                BOOL slim = argc == 3;
                getBatInfo(&bat_info, slim);
                NSLog(@"%@", bat_info);
            }
        }
        return -1;
    }
}

