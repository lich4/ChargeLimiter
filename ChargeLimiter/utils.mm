#include "utils.h"
#include <sys/utsname.h>
#include <sys/sysctl.h>

int platformize_me() {
    int ret = 0;
    #define FLAG_PLATFORMIZE (1 << 1)
    void* h_jailbreak = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (h_jailbreak) {
        const char* dlsym_error = 0;
        dlerror();
        typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
        fix_entitle_prt_t jb_oneshot_entitle_now = (fix_entitle_prt_t)dlsym(h_jailbreak, "jb_oneshot_entitle_now");
        dlsym_error = dlerror();
        if (jb_oneshot_entitle_now && !dlsym_error) {
            jb_oneshot_entitle_now(getpid(), FLAG_PLATFORMIZE);
        }
        dlerror();
        typedef void (*fix_setuid_prt_t)(pid_t pid);
        fix_setuid_prt_t jb_oneshot_fix_setuid_now = (fix_setuid_prt_t)dlsym(h_jailbreak, "jb_oneshot_fix_setuid_now");
        dlsym_error = dlerror();
        if (jb_oneshot_fix_setuid_now && !dlsym_error) {
            jb_oneshot_fix_setuid_now(getpid());
        }
    }
    ret += setuid(0);
    ret += setgid(0);
    return ret;
}

#define MEMORYSTATUS_CMD_GET_PRIORITY_LIST            1
#define MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK   5
typedef struct memorystatus_priority_entry {
    pid_t pid;
    int32_t priority;
    uint64_t user_data;
    int32_t limit;
    uint32_t state;
} memorystatus_priority_entry_t;
extern "C" {
int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void* buffer, size_t buffersize);
}
int32_t get_mem_limit(int pid) {
    int rc = memorystatus_control(MEMORYSTATUS_CMD_GET_PRIORITY_LIST, 0, 0, 0, 0);
    if (rc < 1) {
        return -1;
    }
    struct memorystatus_priority_entry* buf = (struct memorystatus_priority_entry*)malloc(rc);
    rc = memorystatus_control(MEMORYSTATUS_CMD_GET_PRIORITY_LIST, 0, 0, buf, rc);
    int32_t limit = -1;
    for (int i = 0 ; i < rc; i++) {
        if (buf[i].pid == pid) {
            limit = buf[i].limit;
            break;
        }
    }
    free((void*)buf);
    return limit;
}

int set_mem_limit(int pid, int mb) {
    if (get_mem_limit(pid) < mb) { // 单位MB
        return memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, pid, mb, 0, 0);
    }
    return 0;
}


#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" {
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
}

int fd_is_valid(int fd) {
    return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}

NSString* getNSStringFromFile(int fd) {
    NSMutableString* ms = [NSMutableString new];
    ssize_t num_read;
    char c;
    if (!fd_is_valid(fd)) {
        return @"";
    }
    while ((num_read = read(fd, &c, sizeof(c)))) {
        [ms appendString:[NSString stringWithFormat:@"%c", c]];
        //if(c == '\n') {
        //    break;
        //}
    }
    return ms.copy;
}

extern char** environ;
int spawn(NSArray* args, NSString** stdOut, NSString** stdErr, pid_t* pidPtr, int flag, NSDictionary* param) {
    NSString* file = args.firstObject;
    NSUInteger argCount = [args count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));
    for (NSUInteger i = 0; i < argCount; i++) {
        argsC[i] = strdup([[args objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    if ((flag & SPAWN_FLAG_ROOT) != 0) {
        posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
        posix_spawnattr_set_persona_uid_np(&attr, 0);
        posix_spawnattr_set_persona_gid_np(&attr, 0);
    }
    if ((flag & SPAWN_FLAG_SUSPEND) != 0) {
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED);
    }
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    if (param != nil) {
        if (param[@"cwd"] != nil) {
            NSString* path = param[@"cwd"];
            posix_spawn_file_actions_addchdir_np(&action, path.UTF8String);
        }
        if (param[@"close"] != nil) {
            NSArray* closes_fds = param[@"close"];
            for (NSNumber* nfd in closes_fds) {
                posix_spawn_file_actions_addclose(&action, nfd.intValue);
            }
        }
    }
    int outErr[2];
    if(stdErr) {
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }
    int out[2];
    if(stdOut) {
        pipe(out);
        posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, out[0]);
    }
    pid_t task_pid = -1;
    pid_t* task_pid_ptr = &task_pid;
    if (pidPtr != 0) {
        *pidPtr = -1;
        task_pid_ptr = pidPtr;
    }
    int status = -200;
    int spawnError = posix_spawnp(task_pid_ptr, [file UTF8String], &action, &attr, (char* const*)argsC, environ);
    NSLog(@"%@ posix_spawn %@ ret=%d -> %d", log_prefix, args.firstObject, spawnError, *task_pid_ptr);
    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&action);
    for (NSUInteger i = 0; i < argCount; i++) {
        free(argsC[i]);
    }
    free(argsC);
    if(spawnError != 0) {
        NSLog(@"%@ posix_spawn error %d\n", log_prefix, spawnError);
        return spawnError;
    }
    if ((flag & SPAWN_FLAG_NOWAIT) != 0) {
        return 0;
    }
    __block volatile BOOL _isRunning = YES;
    NSMutableString* outString = [NSMutableString new];
    NSMutableString* errString = [NSMutableString new];
    dispatch_semaphore_t sema = 0;
    dispatch_queue_t logQueue;
    if(stdOut || stdErr) {
        logQueue = dispatch_queue_create("com.opa334.TrollStore.LogCollector", NULL);
        sema = dispatch_semaphore_create(0);
        int outPipe = out[0];
        int outErrPipe = outErr[0];
        __block BOOL outEnabled = stdOut != nil;
        __block BOOL errEnabled = stdErr != nil;
        dispatch_async(logQueue, ^{
            while(_isRunning) {
                @autoreleasepool {
                    if(outEnabled) {
                        [outString appendString:getNSStringFromFile(outPipe)];
                    }
                    if(errEnabled) {
                        [errString appendString:getNSStringFromFile(outErrPipe)];
                    }
                }
            }
            dispatch_semaphore_signal(sema);
        });
    }
    do {
        if (waitpid(task_pid, &status, 0) != -1) {
            NSLog(@"%@ Child status %d", log_prefix, WEXITSTATUS(status));
        } else {
            perror("waitpid");
            _isRunning = NO;
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    _isRunning = NO;
    if (stdOut || stdErr) {
        if(stdOut) {
            close(out[1]);
        }
        if(stdErr) {
            close(outErr[1]);
        }
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        if(stdOut) {
            *stdOut = outString.copy;
        }
        if(stdErr) {
            *stdErr = errString.copy;
        }
    }
    return WEXITSTATUS(status);
}

void addPathEnv(NSString* path, BOOL tail) {
    const char* c_path_env = getenv("PATH");
    NSMutableArray* path_arr = [NSMutableArray new];
    if (c_path_env != 0) {
        path_arr = [[@(c_path_env) componentsSeparatedByString:@":"] mutableCopy];
    }
    if (tail) {
        [path_arr addObject:path];
    } else {
        [path_arr insertObject:path atIndex:0];
    }
    NSString* path_env = [path_arr componentsJoinedByString:@":"];
    setenv("PATH", path_env.UTF8String, 1);
}

int get_pid_of(const char* name) {
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    size_t length = 0;
    sysctl(mib, 3, 0, &length, 0, 0);
    length += sizeof(kinfo_proc) * 3;
    kinfo_proc* proc_list = (kinfo_proc*)malloc(length);
    int result = -1;
    if (0 == sysctl(mib, 3, proc_list, &length, 0, 0)) {
        for (int i = 0; i < length / sizeof(kinfo_proc); i++) {
            int pid = proc_list[i].kp_proc.p_pid;
            if (0 == strncmp(proc_list[i].kp_proc.p_comm, name, MAXCOMLEN)) {
                result = pid;
                break;
            }
        }
    }
    free((void*)proc_list);
    return result;
}

int get_sys_boottime() {
    static int ts = 0;
    if (ts == 0) {
        int mib[] = {CTL_KERN, KERN_BOOTTIME};
        struct timeval boottime;
        size_t sz = sizeof(boottime);
        sysctl(mib, 2, &boottime, &sz, 0, 0);
        ts = (int)boottime.tv_sec;
    }
    return ts;
}

NSString* findAppPath(NSString* name) {
    if (name == nil) {
        return nil;
    }
    NSString* appContainersPath = @"/var/containers/Bundle/Application";
    NSError* error = nil;
    NSArray* containers = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appContainersPath error:&error];
    if (!containers) {
        return nil;
    }
    for (NSString* container in containers) {
        NSString* containerPath = [appContainersPath stringByAppendingPathComponent:container];
        BOOL isDirectory = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:containerPath isDirectory:&isDirectory];
        if (exists && isDirectory) {
            NSString* path = [containerPath stringByAppendingFormat:@"/%@.app", name];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                return path;
            }
        }
    }
    return nil;
}

NSString* getLocalIP() { // 获取wifi ipv4
    NSString* result = nil;
    struct ifaddrs* interfaces = 0;
    struct ifaddrs* temp_addr = 0;
    if (0 == getifaddrs(&interfaces)) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if(!strcmp(temp_addr->ifa_name, "en0")) {
                    char* ip = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);
                    result = @(ip);
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        freeifaddrs(interfaces);
    }
    return result;
}

BOOL localPortOpen(int port) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in ip4;
    memset(&ip4, 0, sizeof(struct sockaddr_in));
    ip4.sin_len = sizeof(ip4);
    ip4.sin_family = AF_INET;
    ip4.sin_port = htons(port);
    inet_aton("127.0.0.1", &ip4.sin_addr);
    int so_error = -1;
    struct timeval tv;
    fd_set fdset;
    fcntl(sock, F_SETFL, O_NONBLOCK);
    connect(sock, (struct sockaddr*)&ip4, sizeof(ip4));
    FD_ZERO(&fdset);
    FD_SET(sock, &fdset);
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    if (select(sock + 1, NULL, &fdset, NULL, &tv) == 1) {
        socklen_t len = sizeof(so_error);
        getsockopt(sock, SOL_SOCKET, SO_ERROR, &so_error, &len);
    }
    close(sock);
    return 0 == so_error;
}

extern "C" int _NSGetExecutablePath(char* buf, uint32_t* bufsize);
NSString* getAppEXEPath() {
    char exe[256];
    uint32_t bufsize = sizeof(exe);
    _NSGetExecutablePath(exe, &bufsize);
    return @(exe);
}

int getJBType() {
    /*  EXE和DAEMON路径可能不同,需要综合判断
        有根越狱: /Applications/ChargeLimiter.app/ChargeLimiter (也可能是roothide)
        无根越狱: /var/jb/Applications/ChargeLimiter.app/ChargeLimiter
                [/private]/preboot/[UUID]/jb-[UUID]/procursus/Applications/ChargeLimiter.app/ChargeLimiter
                [/private]/preboot/[UUID]/dopamine-[UUID]/procursus/Applications/ChargeLimiter.app/ChargeLimiter
        roothide:/var/containers/Bundle/Application/.jbroot-[UUID]/Applications/ChargeLimiter.app/ChargeLimiter
        TrollStore/AppStore: [/private]/var/containers/Bundle/Application/[UUID]/ChargeLimiter.app/ChargeLimiter
     */
#ifdef THEOS_PACKAGE_INSTALL_PREFIX
    return JBTYPE_ROOTLESS;
#endif
    NSString* path = getAppEXEPath();
    if ([path hasPrefix:@"/Applications"]) {
        return JBTYPE_ROOT; // may be roothide for daemon
    }
    if ([path hasPrefix:@"/private"]) {
        path = [path substringFromIndex:8];
    }
    if ([path hasPrefix:@"/var/jb"]) {
        return JBTYPE_ROOTLESS;
    }
    NSArray* parts = [path componentsSeparatedByString:@"/"];
    if (parts.count < 4) {
        return JBTYPE_UNKNOWN;
    }
    NSString* path_3 = parts[parts.count - 3];
    if (path_3.length == 36) { // UUID
        return JBTYPE_TROLLSTORE;
    }
    NSString* path_4 = parts[parts.count - 4];
    if ([path_4 hasPrefix:@".jbroot-"]) {
        return JBTYPE_ROOTHIDE;
    }
    return JBTYPE_ROOT;
}

void NSFileLog(NSString* fmt, ...) {
#define LOG_PATH    "/var/root/aldente.log"
    va_list va;
    va_start(va, fmt);
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateStr = [formatter stringFromDate:NSDate.date];
    NSString* content = [[NSString alloc] initWithFormat:fmt arguments:va];
    content = [NSString stringWithFormat:@"%@ %@\n", dateStr, content];
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:@LOG_PATH];
    if (handle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:@LOG_PATH contents:nil attributes:nil];
        handle = [NSFileHandle fileHandleForWritingAtPath:@LOG_PATH];
    }
    [handle seekToEndOfFile];
    [handle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

BOOL isDarkMode() {
    if (@available(iOS 13, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
    return NO;
}

NSString* getAppVer() {
    static NSString* ver = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return ver;
}

NSString* getSysVer() {
    static NSString* ver = UIDevice.currentDevice.systemVersion;
    return ver;
}

NSOperatingSystemVersion getSysVerInt() {
    static NSOperatingSystemVersion ver = NSProcessInfo.processInfo.operatingSystemVersion;
    return ver;
}

NSString* getDevMdoel() {
    static NSString* model = nil;
    if (model == nil) {
        struct utsname name;
        uname(&name);
        model = @(name.machine);
    }
    return model;
}

CGFloat getOrientAngle(UIDeviceOrientation orientation) {
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

NSArray* getUnusedFds() { // posix_spawn会将socket等fd继承给子进程
    NSMutableArray* result = [NSMutableArray new];
    for (int fd = 0; fd < 100; fd++) {
        struct stat st;
        if (0 == fstat(fd, &st)) {
            if (S_ISSOCK(st.st_mode)) { // 避免子进程端口占用造成不必要的麻烦
                [result addObject:@(fd)];
            }
        }
    }
    return result;
}


#define PROC_PIDPATHINFO                11
#define PROC_PIDPATHINFO_SIZE           (MAXPATHLEN)

extern "C" {
int proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int buffersize);
}

@interface BKSApplicationStateMonitor: NSObject
- (NSDictionary*)applicationInfoForApplication:(NSString*)bid;
- (NSDictionary*)applicationInfoForPID:(int)pid;
@end

static NSArray* getAllAppProcs() {
    NSMutableArray* result = [NSMutableArray array];
    size_t length = 0;
    int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    if (0 != sysctl(name, 3, 0, &length, 0, 0)) {
        return nil;
    }
    length += 3 * sizeof(struct kinfo_proc);
    struct kinfo_proc* proc_list = (struct kinfo_proc*)malloc(length);
    if (0 != sysctl(name, 3, proc_list, &length, 0, 0)) {
        free((void*)proc_list);
        return nil;
    }
    int proc_count = int(length / sizeof(struct kinfo_proc));
    if (proc_count > 4096) {
        proc_count = 4096;
    }
    for (int i = 0; i < proc_count; i++) {
        char path[PROC_PIDPATHINFO_SIZE];
        pid_t pid = proc_list[i].kp_proc.p_pid;
        int ret = proc_pidinfo(pid, PROC_PIDPATHINFO, 0, path, sizeof(path));
        if (ret == 0) {
            if (strstr(path, ".app/") != 0) {
                [result addObject:@(pid)];
            }
        }
    }
    free((void*)proc_list);
    return result;
}

NSString* getFrontMostBid() {
    if (false) { // for iOS<=13 || 注入SpringBoard || 二进制在系统分区
        static mach_port_t (*SBSSpringBoardServerPort_)() = (__typeof(SBSSpringBoardServerPort_))dlsym(RTLD_DEFAULT, "SBSSpringBoardServerPort");
        static void (*SBFrontmostApplicationDisplayIdentifier_)(mach_port_t port, char *result) = (__typeof(SBFrontmostApplicationDisplayIdentifier_))dlsym(RTLD_DEFAULT, "SBFrontmostApplicationDisplayIdentifier");
        static mach_port_t sb_port = SBSSpringBoardServerPort_();
        char buf[PATH_MAX];
        memset(buf, 0, sizeof(buf));
        NSString* bid = @"";
        SBFrontmostApplicationDisplayIdentifier_(sb_port, buf);
        if (buf[0] < 'A' || buf[0] > 'z') { // 缓冲区有乱码
            bid = @"";
        } else {
            bid = @(buf);
        }
        return bid;
    }
    NSArray* allAppPids = getAllAppProcs();
    BKSApplicationStateMonitor* monitor = [objc_getClass("BKSApplicationStateMonitor") new];
    for (NSNumber* pid in allAppPids) {
        NSDictionary* appInfo = [monitor applicationInfoForPID:pid.intValue];
        if (appInfo != nil) {
            NSNumber* isFrontMost = appInfo[@"BKSApplicationStateAppIsFrontmost"];
            if (isFrontMost.boolValue) {
                if (appInfo[@"SBApplicationStateDisplayIDKey"] != nil) {
                    return appInfo[@"SBApplicationStateDisplayIDKey"];
                }
                return @"";
            }
        }
    }
    return @"";
}


@interface RadiosPreferences : NSObject
- (BOOL)airplaneMode;
- (void)setAirplaneMode:(BOOL)flag;
- (void)setAirplaneModeWithoutMirroring:(BOOL)flag;
@end

static RadiosPreferences* getAirMan() {
    static RadiosPreferences* radio = [objc_getClass("RadiosPreferences") new];
    return radio;
}

BOOL isAirEnable() {
    RadiosPreferences* radio = getAirMan();
    return radio.airplaneMode;
}

void setAirEnable(BOOL flag) {
    RadiosPreferences* radio = getAirMan();
    if (radio.airplaneMode != flag) {
        [radio setAirplaneMode:flag];
    }
}

typedef struct __WiFiManagerClient* WiFiManagerClientRef;
static int (*WiFiManagerClientSetPower_)(WiFiManagerClientRef manager, BOOL on);
static BOOL (*WiFiManagerClientGetPower_)(WiFiManagerClientRef manager);
static WiFiManagerClientRef (*WiFiManagerClientCreate_)(CFAllocatorRef allocator, int type);

static WiFiManagerClientRef getWiFiMan() {
    static WiFiManagerClientRef man = nil;
    if (man == nil) {
        NSBundle* b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/MobileWiFi.framework"];
        [b load];
        WiFiManagerClientSetPower_ = (__typeof(WiFiManagerClientSetPower_))dlsym(RTLD_DEFAULT, "WiFiManagerClientSetPower");
        WiFiManagerClientGetPower_ = (__typeof(WiFiManagerClientGetPower_))dlsym(RTLD_DEFAULT, "WiFiManagerClientGetPower");
        WiFiManagerClientCreate_ = (__typeof(WiFiManagerClientCreate_))dlsym(RTLD_DEFAULT, "WiFiManagerClientCreate");
        man = WiFiManagerClientCreate_(kCFAllocatorDefault, 0);
    }
    return man;
}

BOOL isWiFiEnable() {
    WiFiManagerClientRef man = getWiFiMan();
    return WiFiManagerClientGetPower_(man);
}

void setWiFiEnable(BOOL flag) {
    WiFiManagerClientRef man = getWiFiMan();
    BOOL status = WiFiManagerClientGetPower_(man);
    if (status != flag) {
        WiFiManagerClientSetPower_(man, flag);
    }
}

@interface BluetoothManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)enabled;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)connected;
- (BOOL)available;
- (BOOL)powered;
- (BOOL)setPowered:(BOOL)powered;
- (BOOL)connectable;
- (void)setConnectable:(BOOL)connectable;
- (BOOL)isDiscoverable;
- (void)setDiscoverable:(BOOL)discoverable;
@end

static id getBTMan() { // 注意: BluetoothManager必须在RunLoop中使用,初始化必须用主线程
    static BluetoothManager* man = nil;
    if (man == nil) {
        NSBundle* b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/BluetoothManager.framework"];
        [b load];
        man = [objc_getClass("BluetoothManager") sharedInstance];
    }
    return man;
}

BOOL isBlueEnable() {
    BluetoothManager* man = getBTMan();
    return man.enabled;
}
void setBlueEnable(BOOL flag) {
    BluetoothManager* man = getBTMan();
    if (man.enabled != flag) {
        [man setEnabled:flag];
        [man setDiscoverable:flag];
        [man setConnectable:flag];
        [man setPowered:flag];
    }
}

@interface LPMManager : NSObject
- (void)setPowerMode:(int64_t)mode fromSource:(NSString*)src withCompletion:(void(^)())block;
- (BOOL)setPowerMode:(int64_t)mode fromSource:(NSString*)src;
//- (void)setPowerMode:(int64_t)mode withCompletion:(void(^)(int,NSError*))block;   // _CDBatterySaver
// - (BOOL)setPowerMode:(int64_t)mode error:(NSError**)err; // _CDBatterySaver
// setPowerMode:fromSource:withParams:; // _PMLowPowerMode
// setPowerMode:fromSource:withParams:withCompletion:; // _PMLowPowerMode
- (int64_t)getPowerMode;
- (int64_t)setMode:(int64_t)mode;
@end

static id getLPMMan() {
    static LPMManager* saver = nil;
    if (saver == nil) {
        NSBundle* b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/LowPowerMode.framework"];
        [b load];
        Class cls_LPMManager = objc_getClass("_PMLowPowerMode");
        if (cls_LPMManager == nil) {
            NSBundle* b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CoreDuet.framework"];
            [b load];
            cls_LPMManager = objc_getClass("_CDBatterySaver");
        }
        saver = [cls_LPMManager sharedInstance];
    }
    return saver;
}

BOOL isLPMEnable() {
    LPMManager* saver = getLPMMan();
    return saver.getPowerMode != 0;
}
void setLPMEnable(BOOL flag) {
    LPMManager* saver = getLPMMan();
    BOOL enable = saver.getPowerMode != 0;
    if (enable != flag) {
        [saver setPowerMode:flag?1:0 fromSource:@"Settings"];
    }
}

@interface CLLocationManager
+ (void)setLocationServicesEnabled:(BOOL)flag;
- (BOOL)locationServicesEnabled;
@end

static id getLocMan() {
    static Class man = nil;
    if (man == nil) {
        NSBundle* b = [NSBundle bundleWithPath:@"/System/Library/Frameworks/CoreLocation.framework/CoreLocation"];
        [b load];
        man = objc_getClass("CLLocationManager");
    }
    return man;
}

BOOL isLocEnable() {
    id locman = getLocMan();
    return [locman locationServicesEnabled];
}

void setLocEnable(BOOL flag) {
    id locman = getLocMan();
    BOOL enable = [locman locationServicesEnabled];
    if (enable != flag) {
        [locman setLocationServicesEnabled:flag];
    }
}

static float (*BrightnessGet)();
static CFTypeRef (*BrightnessCreate)(CFAllocatorRef allocator);
static void (*BrightnessSet)(float brightness, NSInteger unknown);
extern "C" {
void BKSDisplayBrightnessSetAutoBrightnessEnabled(Boolean enabled);
}

void initBrightness() {
    static bool inited = false;
    if (!inited) {
        BrightnessGet = (__typeof(BrightnessGet))dlsym(RTLD_DEFAULT, "BKSDisplayBrightnessGetCurrent");
        BrightnessCreate = (__typeof(BrightnessCreate))dlsym(RTLD_DEFAULT, "BKSDisplayBrightnessTransactionCreate");
        BrightnessSet = (__typeof(BrightnessSet))dlsym(RTLD_DEFAULT, "BKSDisplayBrightnessSet");
        inited = true;
    }
}

float getBrightness() {
    initBrightness();
    return BrightnessGet();
}

void setBrightness(float val) {
    initBrightness();
    BrightnessCreate(kCFAllocatorDefault);
    BrightnessSet(val, 1);
}

void setAutoBrightEnable(BOOL flag) {
    BKSDisplayBrightnessSetAutoBrightnessEnabled(flag);
}

NSString* getThermalSimulationMode() {
    NSUserDefaults* defs = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.cltm"];
    NSString* mode = [defs objectForKey:@"thermalSimulationMode"];
    if (mode == nil) {
        mode = @"off";
    }
    return mode;
}

void setThermalSimulationMode(NSString* mode) {
    NSUserDefaults* defs = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.cltm"];
    [defs setObject:mode forKey:@"thermalSimulationMode"]; // off/nominal/light/moderate/heavy
    [defs synchronize];
}

NSString* getPPMSimulationMode() {
    NSUserDefaults* defs = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.cltm"];
    NSString* mode = [defs objectForKey:@"ppmSimulationMode"];
    if (mode == nil) {
        mode = @"off";
    }
    return mode;
}

void setPPMSimulationMode(NSString* mode) {
    NSUserDefaults* defs = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.cltm"];
    [defs setObject:mode forKey:@"ppmSimulationMode"]; // off/nominal/light/moderate/heavy
    [defs synchronize];
}

