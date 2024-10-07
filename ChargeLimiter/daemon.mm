#include <sqlite3.h>
#import <Foundation/Foundation.h>
#import <GCDWebServers/GCDWebServers.h>
#import <UserNotifications/UserNotifications.h>

#include "utils.h"

#define kHIDPage_PowerDevice                    0x84
#define kHIDUsage_PD_PeripheralDevice           0x06
#define kHIDPage_BatterySystem                  0x85
#define kHIDUsage_BS_PrimaryBattery             0x2e
#define kHIDPage_AppleVendor                    0xFF00
#define kHIDUsage_AppleVendor_AccessoryBattery  0x14

#define S_OK        0
#define S_FALSE     1

#define kIOMessageServiceIsTerminated           0xE0000010
#define kIOPMMessageBatteryStatusHasChanged     0xE0024100

typedef SInt32      HRESULT;
typedef UInt32      ULONG;
typedef void*       LPVOID;
typedef CFUUIDBytes REFIID;

typedef void (*IOUPSEventCallbackFunction)(void* target, IOReturn result, void* refcon, void* sender, CFDictionaryRef event);

struct IOUPSPlugInInterface {
    void*       _reserved;
    HRESULT     (*QueryInterface)(void* thisPointer, REFIID iid, LPVOID* ppv); // IUNKNOWN_C_GUTS
    ULONG       (*AddRef)(void* thisPointer); // IUNKNOWN_C_GUTS
    ULONG       (*Release)(void* thisPointer); // IUNKNOWN_C_GUTS
    IOReturn    (*getProperties)(void* thisPointer, CFDictionaryRef* properties);
    IOReturn    (*getCapabilities)(void* thisPointer, CFSetRef* capabilities);
    IOReturn    (*getEvent)(void* thisPointer, CFDictionaryRef* event);
    IOReturn    (*setEventCallback)(void* thisPointer, IOUPSEventCallbackFunction callback, void* target, void* refcon);
    IOReturn    (*sendCommand)(void* thisPointer, CFDictionaryRef command);
};

struct IOUPSPlugInInterface_v140 {
    void*       _reserved;
    HRESULT     (*QueryInterface)(void* thisPointer, REFIID iid, LPVOID* ppv); // IUNKNOWN_C_GUTS
    ULONG       (*AddRef)(void* thisPointer); // IUNKNOWN_C_GUTS
    ULONG       (*Release)(void* thisPointer); // IUNKNOWN_C_GUTS
    IOReturn    (*getProperties)(void* thisPointer, CFDictionaryRef* properties);
    IOReturn    (*getCapabilities)(void* thisPointer, CFSetRef* capabilities);
    IOReturn    (*getEvent)(void* thisPointer, CFDictionaryRef* event);
    IOReturn    (*setEventCallback)(void* thisPointer, IOUPSEventCallbackFunction callback, void* target, void* refcon);
    IOReturn    (*sendCommand)(void* thisPointer, CFDictionaryRef command);
    IOReturn    (*createAsyncEventSource)(void* thisPointer, CFTypeRef* source);
};

struct IOCFPlugInInterface {
    void*       _reserved;
    HRESULT     (*QueryInterface)(void* thisPointer, REFIID iid, LPVOID* ppv); // IUNKNOWN_C_GUTS
    ULONG       (*AddRef)(void* thisPointer); // IUNKNOWN_C_GUTS
    ULONG       (*Release)(void* thisPointer); // IUNKNOWN_C_GUTS
    UInt16      version;
    UInt16      revision;
    IOReturn    (*Probe)(void* thisPointer, CFDictionaryRef propertyTable, io_service_t service, SInt32* order);
    IOReturn    (*Start)(void* thisPointer, CFDictionaryRef propertyTable, io_service_t service);
    IOReturn    (*Stop)(void* thisPointer);
};

extern "C" {
kern_return_t IOCreatePlugInInterfaceForService(io_service_t service, CFUUIDRef pluginType, CFUUIDRef interfaceType, IOCFPlugInInterface*** theInterface, SInt32* theScore);
}

@interface UPSDataSlim: NSObject
@property IOUPSPlugInInterface_v140**   interface;
@property io_object_t                   noti;
@property CFRunLoopSourceRef            source;
@property CFRunLoopTimerRef             timer;
@property(retain) NSMutableDictionary*  props;
- (instancetype)init;
- (void)initDB;
- (void)updateProps:(NSDictionary*)props isEvent:(BOOL)event;
@end

enum {
    CL_MODE_PLUG = 1,
    CL_MODE_EDGE = 2,
};

static NSDictionary* bat_info = nil;
static BOOL g_enable = NO;
static BOOL g_enable_floatwnd = NO;
static BOOL g_use_smart = NO;
static int g_jbtype = -1;
static int g_serv_boot = 0;

static IONotificationPortRef gNotifyPort = NULL;
static io_object_t iopmpsNoti = IO_OBJECT_NULL;
static UPSDataSlim* gUPSPS = nil;

NSDictionary* handleReq(NSDictionary* nsreq);

@interface Service: NSObject<UNUserNotificationCenterDelegate>
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)initLocalPush;
- (void)localPush:(NSString*)title msg:(NSString*)msg;
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
        @"UpdateTime", @"VirtualTemperature", @"Voltage"];
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
    CFMutableDictionaryRef props = nil;
    IORegistryEntryCreateCFProperties(serv, &props, kCFAllocatorDefault, 0);
    if (props == nil) {
        return -2;
    }
    NSMutableDictionary* info = (__bridge_transfer NSMutableDictionary*)props;
    *pinfo = getBatSlimInfo(info);
    return 0;
}

static int getBatInfo(NSDictionary* __strong* pinfo, BOOL slim=YES) {
    io_service_t serv = getIOPMPSServ();
    if (serv == IO_OBJECT_NULL) {
        return -1;
    }
    CFMutableDictionaryRef props = nil;
    IORegistryEntryCreateCFProperties(serv, &props, kCFAllocatorDefault, 0);
    if (props == nil) {
        return -2;
    }
    NSMutableDictionary* info = (__bridge_transfer NSMutableDictionary*)props;
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

static BOOL isAdaptorConnect(NSDictionary* info, NSNumber* disableInflow) { // 是否连接电源
    if (gUPSPS != nil) { // UPS电源
        // 使用SBC时ExternalConnected/ExternalChargeCapable一直为false
        return YES;
    }
    // 某些充电器ExternalConnected为false,而禁流时ExternalConnected/ExternalChargeCapable均为false
    if (disableInflow.boolValue) { // 禁流模式下只能通过电源信息判断, 某些时候系统会缓存该信息导致不准确
        NSDictionary* AdapterDetails = info[@"AdapterDetails"];
        if (AdapterDetails == nil) {
            return NO;
        }
        NSString* PSDesc = AdapterDetails[@"Description"];
        if (PSDesc == nil || [PSDesc isEqualToString:@"batt"]) {
            return NO;
        }
        return YES;
    } else {
        NSNumber* ExternalChargeCapable = info[@"ExternalChargeCapable"];
        return ExternalChargeCapable.boolValue;
    }
}

static BOOL isAdaptorNewConnect(NSDictionary* oldInfo, NSDictionary* info, NSNumber* disableInflow) {
    return !isAdaptorConnect(oldInfo, disableInflow) && isAdaptorConnect(info, disableInflow);
}

static BOOL isAdaptorNewDisconnect(NSDictionary* oldInfo, NSDictionary* info, NSNumber* disableInflow) {
    return isAdaptorConnect(oldInfo, disableInflow) && !isAdaptorConnect(info, disableInflow);
}

static int setChargeStatus(BOOL flag) {
    NSNumber* adv_predictive_inhibit_charge = getlocalKV(@"adv_predictive_inhibit_charge");
    io_service_t serv = getIOPMPSServ();
    if (serv == IO_OBJECT_NULL) {
        return -1;
    }
    NSMutableDictionary* props = [NSMutableDictionary new];
    if (adv_predictive_inhibit_charge.boolValue) { // 目前测试PredictiveChargingInhibit在iOS>=13生效
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
    int ret = setChargeStatus(flag);
    NSNumber* adv_limit_inflow = getlocalKV(@"adv_limit_inflow");
    NSNumber* adv_thermal_mode_lock = getlocalKV(@"adv_thermal_mode_lock");
    if (!adv_thermal_mode_lock.boolValue && adv_limit_inflow.boolValue) {
        if (flag) {
            NSString* mode = getlocalKV(@"adv_limit_inflow_mode");
            setThermalSimulationMode(mode);
        } else {
            NSString* mode = getlocalKV(@"adv_def_thermal_mode");
            setThermalSimulationMode(mode);
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
                if (isAutoBrightEnable()) {
                    setAutoBrightEnable(NO);
                    cache_status[@"acc_charge_bright_auto"] = @YES;
                }
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
                if (cache_status[@"acc_charge_bright_auto"] != nil) {
                    setAutoBrightEnable(YES);
                }
            }
            if (acc_charge_lpm.boolValue) {
                setLPMEnable(NO);
            }
            cache_status = nil;
        }
    }
}

static NSString* getMsgForLang(NSString* msgid, NSString* lang) {
    static NSDictionary* messages = nil;
    if (messages == nil) {
        NSString* bundlePath = [getSelfExePath() stringByDeletingLastPathComponent];
        NSString* langPath = [bundlePath stringByAppendingString:@"/www/lang.json"];
        NSData* data = [NSData dataWithContentsOfFile:langPath];
        messages = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
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

static sqlite3* db = NULL;
static void updateDBData(const char* tbl, int tid, NSDictionary* info) {
    @autoreleasepool {
        if (!db) {
            return;
        }
        NSData* jdata = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
        if (jdata == nil) {
            return;
        }
        NSString* jstr = [[NSString alloc] initWithData:jdata encoding:NSUTF8StringEncoding];
        char sql[256];
        sprintf(sql, "insert or ignore into %s values(:1, :2)", tbl);
        sqlite3_stmt* stmt = NULL;
        sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
        sqlite3_bind_int(stmt, 1, tid);
        sqlite3_bind_text(stmt, 2, jstr.UTF8String, -1, SQLITE_STATIC);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }
}

static void initDB(NSString* batId) {
    @autoreleasepool {
        if (!db) {
            sqlite3* cdb = NULL;
            if (sqlite3_open(DB_PATH, &cdb) != SQLITE_OK) {
                return;
            }
            db = cdb;
        }
        if (db) {
            for (NSString* rawTbl in @[@"min5", @"hour", @"day", @"month"]) {
                NSString* tblName = rawTbl;
                if (batId != nil) {
                    tblName = [NSString stringWithFormat:@"%@.%@", batId, rawTbl];
                }
                NSString* sql = [NSString stringWithFormat:@"create table if not exists %@(id integer primary key, data text)", tblName];
                char* err;
                sqlite3_exec(db, sql.UTF8String, NULL, NULL, &err);
            }
        }
    }
}

static void uninitDB() {
    if (db != NULL) {
        sqlite3_close(db);
    }
}

static NSArray* getDBData(const char* tbl, int n, int last_id) {
    @autoreleasepool {
        if (!db) {
            return @[];
        }
        NSMutableArray* result = [NSMutableArray array];
        char sql[256];
        sprintf(sql, "select data from %s where id > %d order by id desc limit %d", tbl, last_id, n);
        sqlite3_stmt* stmt = NULL;
        sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const char* jstr = (const char*)sqlite3_column_text(stmt, 0);
            NSData* jdata = [NSData dataWithBytes:(void*)jstr length:strlen(jstr)];
            NSDictionary* jobj = [NSJSONSerialization JSONObjectWithData:jdata options:0 error:nil];
            if (jobj == nil) {
                continue;
            }
            [result addObject:jobj];
        }
        NSArray* result_ = [[result reverseObjectEnumerator] allObjects]; // order by id desc
        sqlite3_finalize(stmt);
        return result_;
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
    NSDictionary* info_h = nil;
    NSDictionary* info_d = nil;
    info_h = getFilteredMDic(bat_info, @[
        @"Amperage", @"AppleRawCurrentCapacity", @"CurrentCapacity", @"ExternalChargeCapable", @"ExternalConnected",
        @"InstantAmperage", @"IsCharging", @"Temperature", @"UpdateTime", @"Voltage"
    ]);
    updateDBData("min5", ts / 300, info_h);
    updateDBData("hour", ts / 3600, info_h);
    info_d = getFilteredMDic(bat_info, @[
        @"CycleCount", @"DesignCapacity", @"NominalChargeCapacity", @"UpdateTime"
    ]);
    updateDBData("day", ts / 86400, info_d);
    updateDBData("month", ts / 2592000, info_d);
    if (gUPSPS != nil && gUPSPS.props[@"Serial"] != nil && gUPSPS.props[@"UpdateTime"] != nil) {
        NSString* batId = gUPSPS.props[@"Serial"];
        NSString* tblMin5 = [batId stringByAppendingString:@".min5"];
        info_h = getFilteredMDic(gUPSPS.props, @[
            @"Amperage", @"AppleRawCurrentCapacity", @"CurrentCapacity", @"IncomingCurrent", @"IncomingVoltage", @"IsCharging", @"Temperature", @"UpdateTime", @"Voltage"
        ]);
        updateDBData(tblMin5.UTF8String, ts / 300, info_h);
        NSString* tblHour = [batId stringByAppendingString:@".hour"];
        updateDBData(tblHour.UTF8String, ts / 3600, info_h);
        info_d = getFilteredMDic(gUPSPS.props, @[
            @"CycleCount", @"MaxCapacity", @"NominalCapacity", @"UpdateTime"
        ]);
        NSString* tblDay = [batId stringByAppendingString:@".day"];
        updateDBData(tblDay.UTF8String, ts / 86400, info_d);
        NSString* tblMonth = [batId stringByAppendingString:@".month"];
        updateDBData(tblMonth.UTF8String, ts / 2592000, info_d);
    }
}

static void onBatteryEventEnd() {
    NSNumber* adv_thermal_mode_lock = getlocalKV(@"adv_thermal_mode_lock");
    if (adv_thermal_mode_lock.boolValue) {
        NSString* mode = getlocalKV(@"adv_def_thermal_mode");
        setThermalSimulationMode(mode);
    }
}

static float getTempAsC(NSString* key) {
    NSNumber* temp_mode = getlocalKV(@"temp_mode");
    NSNumber* temp = getlocalKV(key);
    float temp_c = temp.floatValue;
    if (temp_mode.intValue == 0) { // °C
        return temp_c;
    } else if (temp_mode.intValue == 1) { // °F
        float temp_f = (temp_c - 32) / 1.8;
        return temp_f;
    }
    return 0;
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
        NSString* raw_mode = getlocalKV(@"mode");
        int mode = 0;
        if ([raw_mode isEqualToString:@"charge_on_plug"]) {
            mode = CL_MODE_PLUG;
        } else if ([raw_mode isEqualToString:@"edge_trigger"]) {
            mode = CL_MODE_EDGE;
        }
        NSNumber* charge_below = getlocalKV(@"charge_below");
        NSNumber* charge_above = getlocalKV(@"charge_above");
        NSNumber* enable_temp = getlocalKV(@"enable_temp");
        NSNumber* capacity = bat_info[@"CurrentCapacity"];
        BOOL is_charging = [bat_info[@"IsCharging"] boolValue];
        NSNumber* is_inflow_enabled = bat_info[@"ExternalConnected"];
        NSNumber* adv_disable_inflow = getlocalKV(@"adv_disable_inflow");
        BOOL is_adaptor_connected = isAdaptorConnect(bat_info, adv_disable_inflow);
        BOOL is_adaptor_new_connected = isAdaptorNewConnect(old_bat_info, bat_info, adv_disable_inflow);
        BOOL is_adaptor_new_disconnected = isAdaptorNewDisconnect(old_bat_info, bat_info, adv_disable_inflow);
        NSNumber* temperature_ = bat_info[@"Temperature"];
        float charge_temp_above = getTempAsC(@"charge_temp_above");
        float charge_temp_below = getTempAsC(@"charge_temp_below");
        float temperature = temperature_.intValue / 100.0;
        if (is_adaptor_new_connected) {
            NSFileLog(@"detect plug in");
        } else if (is_adaptor_new_disconnected) {
            NSFileLog(@"detect unplug");
        }
        // 优先级: 电量极低 > 停充(电量>温度) > 充电(电量>温度) > 插电
        do {
            if (capacity.intValue <= 5) { // 电量极低,优先级=1
                // 防止误用或意外造成无法充电
                if (is_adaptor_connected && !is_charging) {
                    NSFileLog(@"start charging for extremely low capacity %@", capacity);
                    setInflowStatus(YES);
                    setBatteryStatus(YES);
                    performAcccharge(YES);
                }
                break;
            }
            if (capacity.intValue >= charge_above.intValue) { // 停充-电量高,优先级=2
                if (is_charging) {
                    NSFileLog(@"stop charging for high capacity %@ >= %@", capacity, charge_above);
                    setBatteryStatus(NO);
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
                if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                    NSFileLog(@"disable inflow for high capacity %@ >= %@", capacity, charge_above);
                    setInflowStatus(NO);
                }
                break;
            }
            if (enable_temp.boolValue && temperature >= charge_temp_above) { // 停充-温度高,优先级=3
                if (is_charging) {
                    NSFileLog(@"stop charging for high temperature %lf >= %lf", temperature, charge_temp_above);
                    setBatteryStatus(NO);
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
                if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                    NSFileLog(@"disable inflow for high temperature %lf >= %lf", temperature, charge_temp_above);
                    setInflowStatus(NO);
                }
                break;
            }
            if (capacity.intValue <= charge_below.intValue) { // 充电-电量低,优先级=4
                // 禁流模式下电量下降后恢复充电
                if (is_adaptor_connected) {
                    if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                        NSFileLog(@"enable inflow for low capacity %@ <= %@", capacity, charge_below);
                        setInflowStatus(YES);
                    }
                    NSFileLog(@"start charging for low capacity %@ <= %@", capacity, charge_below);
                    setBatteryStatus(YES);
                    performAction(@"start_charge");
                    performAcccharge(YES);
                }
                break;
            }
            if (mode == CL_MODE_PLUG) {
                if (enable_temp.boolValue && temperature <= charge_temp_below) { // 充电-温度低,优先级=5
                    if (is_adaptor_connected) {
                        if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                            NSFileLog(@"enable inflow for low temperature %lf < %lf", temperature, charge_temp_below);
                            setInflowStatus(YES);
                        }
                        if (!is_charging) {
                            NSFileLog(@"start charging for low temperature %lf < %lf", temperature, charge_temp_below);
                            setBatteryStatus(YES);
                            performAction(@"start_charge");
                            performAcccharge(YES);
                        }
                    }
                    break;
                }
                if (is_adaptor_new_connected) { // 充电-插电,优先级=6
                    if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                        NSFileLog(@"enable inflow for plug in");
                        setInflowStatus(YES);
                    }
                    NSFileLog(@"start charging for plug in");
                    setBatteryStatus(YES);
                    performAction(@"start_charge");
                    performAcccharge(YES);
                    break;
                }
            } else if (mode == CL_MODE_EDGE) {
                if (is_adaptor_new_connected) {
                    NSFileLog(@"stop charging for plug in");
                    setBatteryStatus(NO);
                    if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                        NSFileLog(@"disable inflow for plug in");
                        setInflowStatus(NO);
                    }
                }
                break;
            }
        } while(false);
        if (is_adaptor_new_disconnected) {
            performAcccharge(NO);
        }
        onBatteryEventEnd();
    }
}

static void initConf(BOOL reset) {
    BOOL predictive_inhibit_charge_avail = NO;
    if (@available(iOS 13.0, *)) {
        predictive_inhibit_charge_avail = YES;
    }
    BOOL adv_thermal_avail = getThermalData() != nil;
    NSDictionary* def_dic = @{
        @"charge_below": @20,
        @"charge_above": @80,
        @"enable_temp": @NO,
        @"temp_mode": @0,
        @"charge_temp_above": @35,
        @"charge_temp_below": @10,
        @"acc_charge": @NO,
        @"acc_charge_airmode": @YES,
        @"acc_charge_wifi": @NO,
        @"acc_charge_blue": @NO,
        @"acc_charge_bright": @NO,
        @"acc_charge_lpm": @YES,
        @"adv_prefer_smart": @NO, // iPhone8+ iOS13+
        @"adv_predictive_inhibit_charge": @(predictive_inhibit_charge_avail), // iPhone8+ iOS13+
        @"adv_disable_inflow": @NO, // all (iPhone8+ iOS13+会改变系统充电图标)
        @"adv_thermal_avail": @(adv_thermal_avail),
        @"adv_limit_inflow": @NO,
        @"adv_limit_inflow_mode": @"moderate",
        @"adv_def_thermal_mode": @"off", // powercuff
        @"adv_thermal_mode_lock": @NO,
        @"action": @"",
    };
    if (reset) {
        BOOL resetBattery = NO;
        BOOL restartDaemon = NO;
        for (NSString* key in def_dic) {
            id valDef = def_dic[key];
            id val = getlocalKV(key);
            if (![valDef isEqual:val]) {
                if ([@[@"adv_predictive_inhibit_charge", @"adv_disable_inflow"] containsObject:key]) {
                    resetBattery = YES;
                }
                if ([key isEqualToString:@"adv_prefer_smart"]) {
                    restartDaemon = YES;
                }
                setlocalKV(key, valDef);
            }
        }
        if (resetBattery) {
            resetBatteryStatus();
        }
        if (restartDaemon) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_global_queue(0, 0), ^{
                exit(0);
            });
        }
    } else {
        NSMutableDictionary* def_mdic = def_dic.mutableCopy;
        [def_mdic addEntriesFromDictionary:@{
            @"enable": @NO,
            @"disable_smart_charge": @YES, // Disable "Optimized Battery Charging" within Settings app
            @"mode": @"charge_on_plug",
            @"update_freq": @1,
            @"lang": @"en",
            @"floatwnd_auto": @NO,
        }];
        for (NSString* key in def_mdic) {
            id val = getlocalKV(key);
            if (val == nil) {
                setlocalKV(key, def_mdic[key]);
            }
        }
    }
    NSNumber* enable = getlocalKV(@"enable");
    g_enable = enable.boolValue;
}

static void showFloatwnd(BOOL flag) {
    static int floatwnd_pid = -1;
    if (flag) { // open
        if (floatwnd_pid == -1) {
            NSDictionary* param = @{
                @"close": getUnusedFds(),
            };
            NSString* bundlePath = [getSelfExePath() stringByDeletingLastPathComponent];
            NSString* appExePath = [bundlePath stringByAppendingPathComponent:@"ChargeLimiter"];
            spawn(@[appExePath, @"floatwnd"], nil, nil, &floatwnd_pid, SPAWN_FLAG_NOWAIT, param);
        }
    } else { // close
        if (floatwnd_pid != -1) {
            kill(floatwnd_pid, SIGKILL);
            floatwnd_pid = -1;
        }
    }
}

NSDictionary* handleReq(NSDictionary* nsreq) {
    NSString* api = nsreq[@"api"];
    if ([api isEqualToString:@"get_conf"]) {
        NSString* key = nsreq[@"key"];
        if (key == nil) {
            NSMutableDictionary* kv = [getAllKV() mutableCopy];
            kv[@"enable"] = @(g_enable);
            kv[@"floatwnd"] = @(g_enable_floatwnd);
            //kv[@"dark"] = @(isDarkMode());  daemon获取到的结果不随系统变化,需要从app获取
            kv[@"sysver"] = getSysVer();
            kv[@"devmodel"] = getDevMdoel();
            kv[@"ver"] = getAppVer();
            kv[@"serv_boot"] = @(g_serv_boot);
            kv[@"sys_boot"] = @(get_sys_boottime());
            kv[@"thermal_simulate_mode"] = getThermalSimulationMode();
            kv[@"ppm_simulate_mode"] = getPPMSimulationMode();
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
        if ([key isEqualToString:@"floatwnd"]) {
            g_enable_floatwnd = [val boolValue];
            showFloatwnd(g_enable_floatwnd);
        } else if ([key isEqualToString:@"ppm_simulate_mode"]) {
            setPPMSimulationMode(val);
        } else {
            setlocalKV(key, val);
        }
        if ([key isEqualToString:@"enable"]) {
            g_enable = [val boolValue];
            if (!g_enable) {
                resetBatteryStatus();
            } else { // 启用时检查
                NSNumber* val = getlocalKV(@"disable_smart_charge");
                if (val.boolValue) {
                    if (isSmartChargeEnable()) {
                        setSmartChargeEnable(NO);
                    }
                }
            }
        } else if ([key isEqualToString:@"action"]) {
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
        } else if ([key isEqualToString:@"adv_def_thermal_mode"]) {
            setThermalSimulationMode(val);
        } else if ([key isEqualToString:@"temp_mode"]) {
            NSArray* vals = nsreq[@"vals"];
            if (vals != nil && vals.count >= 2) {
                setlocalKV(@"charge_temp_below", vals[0]);
                setlocalKV(@"charge_temp_above", vals[1]);
            }
        }
        return @{
            @"status": @0,
        };
    } else if ([api isEqualToString:@"reset_conf"]) {
        initConf(YES);
        return @{
            @"status": @0,
        };
    } else if ([api isEqualToString:@"get_bat_info"]) {
        if (gUPSPS.props != nil) {
            return @{
                @"status": @0,
                @"data": bat_info,
                @"data_ups": gUPSPS.props,
            };
        }
        return @{
            @"status": @0,
            @"enable": @(g_enable), // for floatwnd
            @"data": bat_info,
        };
    } else if ([api isEqualToString:@"get_statistics"]) {
        NSDictionary* conf = nsreq[@"conf"];
        NSMutableDictionary* data = [NSMutableDictionary dictionary];
        for (NSString* tbl in conf) {
            NSDictionary* conf_for_tbl = conf[tbl];
            NSNumber* n = conf_for_tbl[@"n"];
            NSNumber* last_id = conf_for_tbl[@"last_id"];
            data[tbl] = getDBData(tbl.UTF8String, n.intValue, last_id.intValue);
        }
        return @{
            @"status": @0,
            @"data": data,
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
    }
    return @{
        @"status": @-10
    };
}

static void processUPSEventSource(UPSDataSlim* upsPS, CFTypeRef typeRef) {
    CFRunLoopTimerRef timer = nil;
    CFRunLoopSourceRef source = nil;
    if (CFGetTypeID(typeRef) == CFArrayGetTypeID()) {
        NSArray* arrayRef = (__bridge_transfer NSArray*)typeRef;
        for (CFIndex i = 0; i < arrayRef.count; i++) {
            CFTypeRef typeRefI = (__bridge CFTypeRef)arrayRef[i];
            if (CFGetTypeID(typeRefI) == CFRunLoopTimerGetTypeID()) {
                timer = (CFRunLoopTimerRef)typeRefI;
            } else if (CFGetTypeID(typeRefI) == CFRunLoopSourceGetTypeID()) {
                source = (CFRunLoopSourceRef)typeRefI;
            }
        }
    } else if (CFGetTypeID(typeRef) == CFRunLoopTimerGetTypeID()) {
        timer = (CFRunLoopTimerRef)typeRef;
    } else if (CFGetTypeID(typeRef) == CFRunLoopSourceGetTypeID()) {
        source = (CFRunLoopSourceRef)typeRef;
    }
    if (timer != nil) {
        upsPS.timer = timer;
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
    }
    if (source != nil) {
        upsPS.source = source;
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    }
}

static void releaseUPSBattery(UPSDataSlim* upsPS) {
    if (upsPS == nil) {
        return;
    }
    if (upsPS.interface != NULL) {
        (*upsPS.interface)->Release(upsPS.interface);
    }
    if (upsPS.source) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), upsPS.source, kCFRunLoopDefaultMode);
        CFRelease(upsPS.source);
    }
    if (upsPS.timer) {
        CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), upsPS.timer, kCFRunLoopDefaultMode);
        CFRelease(upsPS.timer);
    }
    if (upsPS.noti != MACH_PORT_NULL) {
        IOObjectRelease(upsPS.noti);
    }
}

static void addUPSBattery(void* refCon, io_iterator_t iterator) {
    @autoreleasepool {
        static CFUUIDRef kIOUPSPlugInTypeID             = CFUUIDCreateFromString(NULL, CFSTR("40A57A4E-26A0-11D8-9295-000A958A2C78"));
        static CFUUIDRef kIOUPSPlugInInterfaceID        = CFUUIDCreateFromString(NULL, CFSTR("63F8BFC4-26A0-11D8-88B4-000A958A2C78"));
        static CFUUIDRef kIOUPSPlugInInterfaceID_v140   = CFUUIDCreateFromString(NULL, CFSTR("E60E0799-9AA6-49DF-B55B-A5C94BA07A4A"));
        static CFUUIDRef kIOCFPlugInInterfaceID         = CFUUIDCreateFromString(NULL, CFSTR("C244E858-109C-11D4-91D4-0050E4C6426F"));
        io_object_t upsDevice = MACH_PORT_NULL;
        while ((upsDevice = IOIteratorNext(iterator))) {
            IOReturn kr = 0;
            HRESULT result = S_FALSE;
            IOCFPlugInInterface** plugInInterface = NULL;
            IOUPSPlugInInterface_v140** upsPlugInInterface = NULL;
            SInt32 score;
            kr = IOCreatePlugInInterfaceForService(upsDevice, kIOUPSPlugInTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
            if (kr == kIOReturnSuccess && plugInInterface != NULL) {
                UPSDataSlim* upsPS = [UPSDataSlim new];
                result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUPSPlugInInterfaceID_v140), (LPVOID*)&upsPlugInInterface);
                if (result == S_OK && upsPlugInInterface != nil) {
                    CFTypeRef typeRef = nil;
                    (*upsPlugInInterface)->createAsyncEventSource(upsPlugInInterface, &typeRef);
                    if (typeRef != nil) {
                        processUPSEventSource(upsPS, typeRef);
                    }
                } else {
                    result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUPSPlugInInterfaceID), (LPVOID*)&upsPlugInInterface);
                }
                if (result == S_OK && upsPlugInInterface != NULL) {
                    gUPSPS = upsPS;
                    gUPSPS.interface = upsPlugInInterface;
                    CFMutableDictionaryRef props = nil;
                    IORegistryEntryCreateCFProperties(upsDevice, &props, kCFAllocatorDefault, 0);
                    if (props != nil) {
                        [gUPSPS updateProps:(__bridge NSDictionary*)props isEvent:NO];
                    }
                    [gUPSPS initDB];
                    CFDictionaryRef upsEvent = nil;
                    kr = (*upsPlugInInterface)->getEvent(upsPlugInInterface, &upsEvent);
                    if (kr == kIOReturnSuccess && upsEvent != nil) {
                        [gUPSPS updateProps:(__bridge NSDictionary*)upsEvent isEvent:NO];
                    }
                    (*upsPlugInInterface)->setEventCallback(upsPlugInInterface, [](void* target, IOReturn kr, void* refcon, void* sender, CFDictionaryRef event) {
                        @autoreleasepool {
                            if (gUPSPS != nil && event != nil) {
                                [gUPSPS updateProps:(__bridge NSDictionary*)event isEvent:NO];
                            }
                        }
                    }, NULL, NULL);
                    io_object_t noti = IO_OBJECT_NULL;
                    IOServiceAddInterestNotification(gNotifyPort, upsDevice, "IOGeneralInterest", [](void* refcon, io_service_t service, uint32_t type, void* args) {
                        @autoreleasepool {
                            if (type == kIOMessageServiceIsTerminated) {
                                NSFileLog(@"detect ups battery unplug");
                                releaseUPSBattery(gUPSPS);
                                gUPSPS = nil;
                            }
                        }
                    }, nil, &noti);
                    gUPSPS.noti = noti;
                    NSFileLog(@"detect ups battery plug in");
                }
                (*plugInInterface)->Release(plugInInterface);
            }
            IOObjectRelease(upsDevice);
            if (gUPSPS != nil) {
                break;
            }
        }
    }
}

void detectUPSBattery() {
    @autoreleasepool {
        if (gUPSPS != nil) { // 存在电池则忽略
            return;
        }
        NSDictionary* dic = @{
            @"IOProviderClass": @"IOHIDDevice",
            @"DeviceUsagePairs": @[
                @{ // kDeviceTypeAccessoryBattery
                    @"DeviceUsagePage": @kHIDPage_AppleVendor,
                    @"DeviceUsage": @kHIDUsage_AppleVendor_AccessoryBattery,
                }, @{ // kDeviceTypeAccessoryBattery
                    @"DeviceUsagePage": @kHIDPage_PowerDevice,
                    @"DeviceUsage": @kHIDUsage_PD_PeripheralDevice,
                }, @{ // kDeviceTypeBatteryCase
                    @"DeviceUsagePage": @kHIDPage_BatterySystem,
                    @"DeviceUsage": @kHIDUsage_BS_PrimaryBattery,
                },
            ]
        };
        io_iterator_t gAddedIter = MACH_PORT_NULL;
        kern_return_t kr = IOServiceAddMatchingNotification(gNotifyPort, kIOMatchedNotification, (__bridge_retained CFDictionaryRef)dic, addUPSBattery, NULL, &gAddedIter);
        if (kr == kIOReturnSuccess) {
            if (gAddedIter != MACH_PORT_NULL) {
                addUPSBattery(NULL, gAddedIter);
                IOObjectRelease(gAddedIter);
            }
        }
    }
}

@implementation UPSDataSlim
- (instancetype)init {
    self = [super init];
    self.noti = IO_OBJECT_NULL;
    self.source = nil;
    self.timer = nil;
    self.props = [NSMutableDictionary dictionary];
    return self;
}
- (void)initDB {
    NSString* serial = self.props[@"Serial"];
    if (serial != nil) {
        initDB(serial);
    }
}
- (void)updateProps:(NSDictionary*)propsSrc isEvent:(BOOL)event {
    NSDictionary* keep = @{
        @"Authenticated": @"Authenticated",
        @"Manufacturer": @"Manufacturer",
        @"ModelNumber": @"ModelNumber",
        @"PrimaryUsagePage": @"UsagePage",
        @"PrimaryUsage": @"Usage",
        @"Product": @"Name",
        @"ProductID": @"ProductID",
        @"ReportInterval": @"ReportInterval",
        @"SerialNumber": @"Serial",
        @"Transport": @"Transport",
        @"VendorID": @"VendorID",
        @"VersionNumber": @"VersionNumber",
        @"AppleRawCurrentCapacity": @"AppleRawCurrentCapacity",
        @"BatteryCaseChargingVoltage": @"BatteryCaseChargingVoltage",
        @"Cell0Voltage": @"Cell0Voltage",
        @"Cell1Voltage": @"Cell1Voltage",
        @"Current": @"Amperage",
        @"CurrentCapacity": @"CurrentCapacity",
        @"CycleCount": @"CycleCount",
        @"IncomingCurrent": @"IncomingCurrent",
        @"IncomingVoltage": @"IncomingVoltage",
        @"IsCharging": @"IsCharging",
        @"MaxCapacity": @"MaxCapacity",
        @"NominalCapacity": @"NominalCapacity",
        @"PowerSourceState": @"PowerSourceState",
        @"Temperature": @"Temperature",
        @"Voltage": @"Voltage",
    };
    for (NSString* rawkey in propsSrc) {
        NSString* key = [rawkey stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (keep[key] == nil) {
            continue;
        } else {
            key = keep[key];
        }
        id val = propsSrc[rawkey];
        self.props[key] = val;
    }
    if (event) {
        self.props[@"UpdateTime"] = @(time(0));
    }
}
@end

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
    initConf(NO);
    initDB(nil);
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
        gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        CFRunLoopSourceRef runSrc = IONotificationPortGetRunLoopSource(gNotifyPort);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runSrc, kCFRunLoopDefaultMode);
        io_service_t serv = getIOPMPSServ();
        if (serv != IO_OBJECT_NULL) {
            IOServiceAddInterestNotification(gNotifyPort, serv, "IOGeneralInterest", [](void* refcon, io_service_t service, uint32_t type, void* args) { // type == kIOPMMessageBatteryStatusHasChanged
                @synchronized (Service.inst) {
                    detectUPSBattery(); // 在USB插拔事件中更新
                    onBatteryEvent(service);
                }
            }, nil, &iopmpsNoti);
            detectUPSBattery();
        }
        [LSApplicationWorkspace.defaultWorkspace addObserver:self];
        isBlueEnable(); // init
        isLPMEnable();
        isSmartChargeEnable();
    }
}
@end


int main(int argc, char** argv) { // daemon_main
    @autoreleasepool {
        g_jbtype = getJBType();
        if (argc == 1) {
            NSFileLog(@"CLv%@ start pid=%d", NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"], getpid());
            g_serv_boot = (int)time(0);
            if (g_jbtype == JBTYPE_TROLLSTORE) {
                signal(SIGHUP, SIG_IGN);
                signal(SIGTERM, SIG_IGN); // 防止App被Kill以后daemon退出
            } else {
                platformize_me(); // for jailbreak
                set_mem_limit(getpid(), 80);
            }
            [Service.inst serve];
            atexit_b(^{
                resetBatteryStatus();
                if (iopmpsNoti != IO_OBJECT_NULL) {
                    IOObjectRelease(iopmpsNoti);
                    iopmpsNoti = IO_OBJECT_NULL;
                }
                releaseUPSBattery(gUPSPS);
                if (gNotifyPort != 0) {
                    IONotificationPortDestroy(gNotifyPort);
                    gNotifyPort = 0;
                }
                showFloatwnd(NO);
                uninitDB();
                [LSApplicationWorkspace.defaultWorkspace removeObserver:Service.inst];
            });
            [NSRunLoop.mainRunLoop run];
            NSFileLog(@"daemon unexpected");
            return 0;
        } else if (argc > 1) {
            if (0 == strcmp(argv[1], "reset")) { // 越狱下卸载前重置
                resetBatteryStatus();
                return 0;
            } else if (0 == strcmp(argv[1], "watch_bat_info")) {
                BOOL slim = argc == 3;
                while (true) {
                    getBatInfo(&bat_info, slim);
                    NSLog(@"%@", bat_info);
                    [NSThread sleepForTimeInterval:1.0];
                    spawn(@[@"clear"], nil, nil, nil, 0, nil);
                }
                return 0;
            } else if (0 == strcmp(argv[1], "set_charge")) {
                bool flag = argv[2][0] - '0';
                setChargeStatus(flag);
                return 0;
            } else if (0 == strcmp(argv[1], "set_inflow")) {
                bool flag = argv[2][0] - '0';
                setInflowStatus(flag);
                return 0;
            }
        }
        return -1;
    }
}

