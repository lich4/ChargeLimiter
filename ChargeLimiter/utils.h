#ifndef UTILS_H
#define UTILS_H

#include "common.h"

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
int32_t get_mem_limit(int pid);
int set_mem_limit(int pid, int mb);
BOOL localPortOpen(int port);
NSString* getSelfExePath();
NSArray* getUnusedFds();
NSArray* getFrontMostBid();

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
BOOL isAutoBrightEnable();
void setAutoBrightEnable(BOOL flag);

NSDictionary* getThermalData();
NSString* getPerfManState();
void DisablePerfMan();
NSString* getThermalSimulationMode();
void setThermalSimulationMode(NSString* mode);
NSString* getPPMSimulationMode();
void setPPMSimulationMode(NSString* mode);
BOOL isSmartChargeEnable(); // 系统自带电池优化
void setSmartChargeEnable(BOOL flag);

/* ---------------- App ---------------- */
id getlocalKV(NSString* key);
void setlocalKV(NSString* key, id val);
NSDictionary* getAllKV();
/* ---------------- App ---------------- */

#endif // UTILS_H

