#ifndef UI_H
#define UI_H

#include "common.h"
#import <IOKit/IOKit.h>
#include <IOKit/hid/IOHIDService.h>

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

@interface AppDelegate : UIViewController<UIApplicationDelegate, UIWindowSceneDelegate, UIWebViewDelegate>
@property(strong, nonatomic) UIWindow* window;
@property(retain) UIWebView* webview;
@end

@interface HUDMainWindow: UIWindow
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

#endif // UI_H

