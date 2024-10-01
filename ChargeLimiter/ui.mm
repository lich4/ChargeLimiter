#include "ui.h"
#include "utils.h"

static int g_jbtype     = -1;
static int g_wind_type  = 0; // 1: HUD

static void daemonRun(NSArray* nsreq);

static BOOL isDarkMode() {
    if (@available(iOS 13, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
    return NO;
}

@implementation HUDMainWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}
- (BOOL)_isWindowServerHostingManaged {
    return NO;
}
@end

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
            daemonRun(@[@"set_charge", @"1"]);
        } else if ([cmd isEqualToString:@"nocharge"]) {
            daemonRun(@[@"set_charge", @"0"]);
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
                            int f_y = MAX(y - FLOAT_HEIGHT/2, 50); // 防止刘海屏上拉残缺
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
#define     FRONTMOST_DELAY   20
                    static int last_access_time = 0;
                    static bool in_process = false;
                    int ts = (int)time(0);
                    last_access_time = ts;
                    if (in_process) {
                        return;
                    }
                    NSString* self_bid = NSBundle.mainBundle.bundleIdentifier;
                    NSArray* white_list = @[@"", self_bid]; // 作为前台桌面的进程
                    static NSString* old_bid = self_bid; // 悬浮窗从CL诞生
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        @autoreleasepool {
                            in_process = true;
                            for (int i = ts; i < last_access_time + FRONTMOST_DELAY; i++) { // 每次通知增加上限时间,等待bid变化
                                NSArray* cur_bid_list = getFrontMostBid();
                                NSString* cur_bid = @"";
                                if (cur_bid_list.count > 0) {
                                    if ([cur_bid_list containsObject:self_bid]) {
                                        cur_bid = self_bid;
                                    } else {
                                        cur_bid = cur_bid_list.firstObject;
                                    }
                                }
                                if (![old_bid isEqualToString:cur_bid]) {
                                    NSNumber* floatwnd_auto = getlocalKV(@"floatwnd_auto");
                                    if (floatwnd_auto.boolValue) {
                                        if ([white_list containsObject:cur_bid]) {
                                            NSFileLog(@"floatwnd unhide for %@", cur_bid);
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                _app.webview.hidden = NO;
                                            });
                                        } else {
                                            NSFileLog(@"floatwnd hide for %@", cur_bid);
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                _app.webview.hidden = YES;
                                            });
                                        }
                                    }
                                    old_bid = cur_bid;
                                    break; // 已变化,满足条件退出
                                }
                                old_bid = cur_bid;
                                [NSThread sleepForTimeInterval:1.0];
                            }
                            in_process = false;
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
    if (@available(iOS 17.0, *)) {
        static BOOL ios17plusInit = NO;
        if (!ios17plusInit) { // 修复iOS17 UIWebView无法滑动
            ios17plusInit = YES;
            [webview stringByEvaluatingJavaScriptFromString:@"window.location.reload()"];
            return;
        }
    }
    [self speedUpWebView:webview];
    if (isDarkMode()) {
        [webview stringByEvaluatingJavaScriptFromString:@"window.app.switch_dark(true)"];
    } else {
        [webview stringByEvaluatingJavaScriptFromString:@"window.app.switch_dark(false)"];
    }
    [webview stringByEvaluatingJavaScriptFromString:@"window.source='CL'"];
    JSContext* context = [webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"set_pb"] = ^{
        @autoreleasepool {
            NSArray* args = [JSContext currentArguments];
            JSValue* val = args[0];
            UIPasteboard* pb = [UIPasteboard generalPasteboard];
            pb.string = val.toString;
        }
    };
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
    }
    return YES;
}
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
            uint32_t* runMethodPtr = (uint32_t*)make_sym_readable((void *)runMethodIMP);
            void (*orig_UIEventDispatcher__installEventRunLoopSources_)(id, SEL, CFRunLoopRef) = NULL;
            for (int i = 0; i < 0x140; i++) {
                // mov x2, x0
                // mov x0, x?
                if (runMethodPtr[i] != 0xaa0003e2 || (runMethodPtr[i + 1] & 0xff000000) != 0xaa000000) {
                    continue;
                }
                // bl -[UIEventDispatcher _installEventRunLoopSources:]
                uint32_t blInst = runMethodPtr[i + 2];
                uint32_t* blInstPtr = &runMethodPtr[i + 2];
                if ((blInst & 0xfc000000) != 0x94000000) {
                    continue;
                }
                int32_t blOffset = blInst & 0x03ffffff;
                if (blOffset & 0x02000000)
                    blOffset |= 0xfc000000;
                blOffset <<= 2;
                uint64_t blAddr = (uint64_t)blInstPtr + blOffset;
                // cbz x0, loc_?????????
                uint32_t cbzInst = *((uint32_t*)make_sym_readable((void*)blAddr));
                if ((cbzInst & 0xff000000) != 0xb4000000) {
                    continue;
                }
                orig_UIEventDispatcher__installEventRunLoopSources_ = (void (*)(id __strong, SEL, CFRunLoopRef))make_sym_callable((void*)blAddr);
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


void daemonRun(NSArray* argv) {
    NSString* bundlePath = [getSelfExePath() stringByDeletingLastPathComponent];
    NSString* daemonPath = [bundlePath stringByAppendingPathComponent:@"ChargeLimiterDaemon"];
    NSMutableArray* mArgv = [NSMutableArray array];
    [mArgv addObject:daemonPath];
    if (argv != nil) {
        [mArgv addObjectsFromArray:argv];
    }
    spawn(mArgv, nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
}

static void start_daemon() {
    @autoreleasepool {
        if (g_jbtype == JBTYPE_TROLLSTORE) {
            NSTimer* start_daemon_timer = [NSTimer timerWithTimeInterval:10 repeats:YES block:^(NSTimer* timer) {
                @autoreleasepool {
                    if (!localPortOpen(GSERV_PORT)) {
                        daemonRun(nil);
                    }
                }
            }];
            [start_daemon_timer fire];
            [NSRunLoop.currentRunLoop addTimer:start_daemon_timer forMode:NSDefaultRunLoopMode];
        }
    }
}

int main(int argc, char** argv) { // ChargeLimiter
    @autoreleasepool {
        g_jbtype = getJBType();
        if (argc == 1) {
            start_daemon();
            return UIApplicationMain(argc, argv, nil, @"AppDelegate");
        } else if (argc > 1) {
            if (0 == strcmp(argv[1], "floatwnd")) {
                start_daemon();
                g_wind_type = 1;
                static id<UIApplicationDelegate> appDelegate = [AppDelegate new];
                UIApplicationInstantiateSingleton(HUDMainApplication.class);
                static UIApplication* app = [UIApplication sharedApplication];
                [app setDelegate:appDelegate];
                [app __completeAndRunAsPlugin];
                CFRunLoopRun();
                return 0;
            }
        }
        return -1;
    }
}

