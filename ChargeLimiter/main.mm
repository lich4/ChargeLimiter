#import <Foundation/Foundation.h>
#import <GCDWebServers/GCDWebServers.h>
#import <IOKit/IOKit.h>
#include <IOKit/hid/IOHIDService.h>
#import <UIKit/UIKit.h>
#include "utils.h"

#define PRODUCT         "aldente"
#define GSERV_PORT      1230
#define TRACE           true

NSString* log_prefix = @(PRODUCT "logger");
static NSDictionary* bat_info = nil;
static NSDictionary* handleReq(NSDictionary* nsreq);

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

@interface Service : NSObject
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
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

static int g_wind_type = 0; // 1: HUD
#define FLOAT_ORIGINX   100
#define FLOAT_ORIGINY   100
#define FLOAT_WIDTH     80
#define FLOAT_HEIGHT    80
// 如果FLOAT_WIDTH==FLOAT_HEIGHT,iPad横屏拖动会出现残缺,原因未知

static CGFloat orientationAngle(UIDeviceOrientation orientation) {
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            return M_PI;
        case UIDeviceOrientationLandscapeLeft:
            return M_PI_2;
        case UIDeviceOrientationLandscapeRight:
            return -M_PI_2;
        default:
            return 0;
    }
}

@implementation AppDelegate {
    NSString* initUrl;
}
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
        if (_accessController != nil) {
            unsigned int _contextId = [self.window _contextId];
            double windowLevel = [self.window windowLevel];
            [_accessController registerWindowWithContextID:_contextId atLevel:windowLevel];
        }
    }
    return YES;
}
- (void)speedUpWebView:(UIWebView*)webview { // 优化UIWebView反应速度
    // 不用WKWebView的原因: TrollStore环境下,需要无沙盒执行子进程,而WKWebView需要沙盒才能工作,考虑和越狱的一致性选择UIWebView
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
                    CFArrayRef ref = IOHIDEventGetChildren(event);
                    if (!ref || CFArrayGetCount(ref) == 0) {
                        return;
                    }
                    IOHIDEventRef event2 = (IOHIDEventRef)CFArrayGetValueAtIndex(ref, 0);
                    //int index = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerIndex);
                    //int identity = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerIdentity);
                    //int range = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerRange);
                    //int touch = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerTouch);
                    int x = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerX);
                    int y = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerY);
                    int mask = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldDigitizerEventMask);
                    //NSLog(@"BKSHIDEventRegisterEventCallback index=%d identity=%d x=%d y=%d range=%d touch=%d mask=%d", index, identity, x, y, range, touch, mask);
                    if ((mask & kIOHIDDigitizerEventPosition) != 0) { // touch_move
                        dispatch_async(dispatch_get_main_queue(), ^{
                            int f_x = MAX(x - FLOAT_WIDTH/2, 0);
                            int f_y = MAX(y - FLOAT_HEIGHT/2, 0);
                            f_x = MIN(f_x, scrSize.width - FLOAT_WIDTH);
                            f_y = MIN(f_y, scrSize.height - FLOAT_HEIGHT);
                            CGRect rt = CGRectMake(f_x, f_y, FLOAT_WIDTH, FLOAT_HEIGHT);
                            [_app.webview setFrame:rt];
                        });
                    } else {
                        [UIApplication.sharedApplication _enqueueHIDEvent:event];
                    }
                }
            });
            
            static UIDeviceOrientation old_orient = UIDevice.currentDevice.orientation;
            static FBSOrientationObserver* orientObserver = [objc_getClass("FBSOrientationObserver") new];
            [orientObserver setHandler:^(FBSOrientationUpdate* update) {
                if (update.orientation == old_orient) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_app.webview setTransform:CGAffineTransformMakeRotation(orientationAngle(update.orientation))];
                });
                old_orient = update.orientation;
            }];
        }
    }
}
- (void)webViewDidFinishLoad:(UIWebView*)webview {
    [_mainWnd addSubview:webview];
    [_mainWnd bringSubviewToFront:webview];
    [self speedUpWebView: webview];
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
        NSArray* new_stat = [stat_hour subarrayWithRange:NSMakeRange(MAX((int)stat_hour.count - 24, 0), MIN(stat_hour.count, 24))];
        setlocalKV(@"stat_hour", new_stat);
    }
    if (stat_day.count == 0 || ![stat_day.lastObject[@"key"] isEqualToString:dayKey]) {
        NSMutableDictionary* mBatInfo = getFilteredMDic(bat_info, @[@"CycleCount", @"NominalChargeCapacity", @"UpdateTime"]);
        mBatInfo[@"key"] = dayKey;
        [stat_day addObject:mBatInfo];
        NSArray* new_stat = [stat_day subarrayWithRange:NSMakeRange(MAX((int)stat_day.count - 30, 0), MIN(stat_day.count, 30))];
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
        int temperature = temperature_.intValue / 100;
        if (enable_temp.boolValue && temperature >= charge_temp_above.intValue) {
            if (is_charging.boolValue) {
                NSFileLog(@"stop charging for high temperature");
                if (0 == setChargeStatus(NO)) {
                    perform_acccharge(NO);
                }
                return;
            }
        }
        if (capacity.intValue >= charge_above.intValue) {
            if (is_charging.boolValue) {
                NSFileLog(@"stop charging for capacity");
                if (0 == setChargeStatus(NO)) {
                    perform_acccharge(NO);
                }
            }
            return; // 电量满禁止操作
        }
        if ([mode isEqualToString:@"charge_on_plug"]) { // 此状态下禁用charge_below
            if (isAdaptorNewConnect(old_bat_info, bat_info)) {
                NSFileLog(@"start charging for plug in");
                if (0 == setChargeStatus(YES)) {
                    perform_acccharge(YES);
                }
                return;
            }
            if (enable_temp.boolValue && temperature <= charge_temp_below.intValue) {
                if (isAdaptorConnect(bat_info)) {
                    NSFileLog(@"start charging for low temperature");
                    if (0 == setChargeStatus(YES)) {
                        perform_acccharge(YES);
                    }
                    return;
                }
            }
            return;
        }
        if (capacity.intValue <= charge_below.intValue) {
            if (!is_charging.boolValue) {
                if (isAdaptorConnect(bat_info)) {
                    NSFileLog(@"start charging for capacity");
                    if (0 == setChargeStatus(YES)) {
                        perform_acccharge(YES);
                    }
                    return;
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
        NSMutableDictionary* kv = [cache_kv mutableCopy];
        kv[@"enable"] = @(g_enable);
        kv[@"floatwnd"] = @(g_enable_floatwnd);
        kv[@"dark"] = @(isDarkMode());
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
        isBlueEnable(); // init
        isLPMEnable();
    
        if (TRACE) { // todo delete
            static NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:600 repeats:YES block:^(NSTimer* timer) {
                NSFileLog(@"[%d] daemon alive", getpid());
            }];
            [timer fire];
        }
    }
}
@end


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


int main(int argc, char** argv) {
    @autoreleasepool {
        g_jbtype = getJBType();
        if (argc == 1) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (!localPortOpen(GSERV_PORT)) {
                    NSLog(@"%@ start daemon", log_prefix);
                    if (g_jbtype == JBTYPE_TROLLSTORE) {
                        spawn(@[getAppEXEPath(), @"daemon"], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
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

