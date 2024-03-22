#include <arpa/inet.h>
#include <dlfcn.h>
#include <ifaddrs.h>
#include <objc/runtime.h>
#include <spawn.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#import <Foundation/Foundation.h>
#import <os/log.h>
#import <UIKit/UIKit.h>

#define NSLog2(FORMAT, ...) os_log(OS_LOG_DEFAULT,"%{public}@", [NSString stringWithFormat:FORMAT, ##__VA_ARGS__])

extern NSString* log_prefix;

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString* bundleIdentifier;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;
@end

enum {
    SPAWN_FLAG_ROOT     = 1,
    SPAWN_FLAG_NOWAIT   = 2,
    SPAWN_FLAG_SUSPEND  = 4,
};
int spawn(NSArray* args, NSString** stdOut, NSString** stdErr, pid_t* pidPtr, int flag, NSDictionary* param=nil);
void addPathEnv(NSString* path, BOOL tail);
int get_pid_of(const char* name);
int get_sys_boottime();
NSString* findAppPath(NSString* name);
int platformize_me();
int set_memory_limit(int pid, int mb);
BOOL localPortOpen(int port);
NSString* getAppEXEPath();
NSArray* getUnusedFds();
NSString* getFrontMostBid();

#define STR(X) #X

#ifdef THEOS_PACKAGE_INSTALL_PREFIX
#define ROOTDIR STR(THEOS_PACKAGE_INSTALL_PREFIX)
#else
#define ROOTDIR
#endif
enum {
    JBTYPE_UNKNOWN      = -1,
    JBTYPE_ROOTLESS     = 0,
    JBTYPE_ROOT         = 1,
    JBTYPE_ROOTHIDE     = 2,
    JBTYPE_TROLLSTORE   = 8, // TrollStore/AppStore
};
int getJBType();
void NSFileLog(NSString* fmt, ...);
BOOL isDarkMode();
NSString* getAppVer();
NSString* getSysVer();
NSOperatingSystemVersion getSysVerInt();
NSString* getDevMdoel();
CGFloat getOrientAngle(UIDeviceOrientation orientation);

BOOL isAirEnable();
void setAirEnable(BOOL flag);
BOOL isWiFiEnable();
void setWiFiEnable(BOOL flag);
BOOL isBlueEnable();
void setBlueEnable(BOOL flag);
BOOL isLPMEnable();
void setLPMEnable(BOOL flag);
BOOL isLocEnable();
void setLocEnable(BOOL flag);
float getBrightness();
void setBrightness(float val);
void setAutoBrightEnable(BOOL flag);
NSString* getThermalSimulationMode();
void setThermalSimulationMode(NSString* mode);
NSString* getPPMSimulationMode();
void setPPMSimulationMode(NSString* mode);

