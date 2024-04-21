#import <Foundation/Foundation.h>
#import <GCDWebServers/GCDWebServers.h>
#import <UserNotifications/UserNotifications.h>
#include "ui.h"
#include "utils.h"
#include <sqlite3.h>

NSString* log_prefix = @(PRODUCT "Logger");
int log_level = 1; // 0:normal 1:detail // todo
static NSDictionary* bat_info = nil;
static BOOL g_enable = YES;
static BOOL g_enable_floatwnd = NO;
static BOOL g_use_smart = NO;
static int g_jbtype = -1;
static int g_serv_boot = 0;
int g_wind_type = 0; // 1: HUD

NSDictionary* handleReq(NSDictionary* nsreq);
static void start_daemon();

@interface Service: NSObject<UNUserNotificationCenterDelegate> 
+ (instancetype)inst;
- (instancetype)init;
- (void)serve;
- (void)initLocalPush;
- (void)localPush:(NSString*)title msg:(NSString*)msg;
@end

static NSMutableDictionary* cache_kv = nil;
id getlocalKV(NSString* key) {
    if (cache_kv == nil) {
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:@CONF_PATH];
    }
    if (cache_kv == nil) {
        return nil;
    }
    return cache_kv[key];
}

void setlocalKV(NSString* key, id val) {
    if (cache_kv == nil) {
        cache_kv = [NSMutableDictionary dictionaryWithContentsOfFile:@CONF_PATH];
        if (cache_kv == nil) {
            cache_kv = [NSMutableDictionary new];
        }
    }
    cache_kv[key] = val;
    [cache_kv writeToFile:@CONF_PATH atomically:YES];
}

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

static BOOL isAdaptorConnect(NSDictionary* info) { // 是否连接电源
    // 某些充电器ExternalConnected为false,而禁流时ExternalConnected/ExternalChargeCapable均为false
    NSDictionary* AdapterDetails = info[@"AdapterDetails"];
    if (AdapterDetails == nil) {
        return NO;
    }
    NSString* PSDesc = AdapterDetails[@"Description"];
    if (PSDesc == nil || [PSDesc isEqualToString:@"batt"]) {
        return NO;
    }
    return YES;
}

static BOOL isAdaptorNewConnect(NSDictionary* oldInfo, NSDictionary* info) {
    return !isAdaptorConnect(oldInfo) && isAdaptorConnect(info);
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
        @"start_charge": @"Start charging",
        @"stop_charge": @"Stop charging",
    },
    @"zh_CN": @{
        @"start_charge": @"开始充电",
        @"stop_charge": @"停止充电",
    },
    @"zh_TW": @{
        @"start_charge": @"開始充電",
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

static void initDB() {
    @autoreleasepool {
        sqlite3* cdb = NULL;
        if (sqlite3_open(DB_PATH, &cdb) != SQLITE_OK) {
            return;
        }
        char* err;
        const char* tbls[] = {"min5", "hour", "day", "month", NULL};
        for (int i = 0; tbls[i]; i++) {
            char sql[256];
            sprintf(sql, "create table if not exists %s(id integer primary key, data text)", tbls[i]);
            if (sqlite3_exec(cdb, sql, NULL, NULL, &err) != SQLITE_OK) {
                sqlite3_close(cdb);
                return;
            }
        }
        db = cdb;
        // 迁移老数据
        NSArray* arr = getlocalKV(@"stat_min5");
        if (arr != nil && arr.count > 0) {
            for (NSDictionary* item in arr) {
                NSMutableDictionary* mitem = item.mutableCopy;
                NSString* key = mitem[@"key"];
                [mitem removeObjectForKey:@"key"];
                updateDBData("min5", key.intValue, mitem);
            }
            setlocalKV(@"stat_min5", nil);
        }
        arr = getlocalKV(@"stat_hour");
        if (arr != nil && arr.count > 0) {
            for (NSDictionary* item in arr) {
                NSMutableDictionary* mitem = item.mutableCopy;
                NSString* key = mitem[@"key"];
                [mitem removeObjectForKey:@"key"];
                updateDBData("hour", key.intValue, mitem);
            }
            setlocalKV(@"stat_hour", nil);
        }
        arr = getlocalKV(@"stat_day");
        if (arr != nil && arr.count > 0) {
            for (NSDictionary* item in getlocalKV(@"stat_day")) {
                NSMutableDictionary* mitem = item.mutableCopy;
                NSString* key = mitem[@"key"];
                [mitem removeObjectForKey:@"key"];
                updateDBData("day", key.intValue, mitem);
            }
            setlocalKV(@"stat_day", nil);
        }
        arr = getlocalKV(@"stat_month");
        if (arr != nil && arr.count > 0) {
            for (NSDictionary* item in getlocalKV(@"stat_month")) {
                NSMutableDictionary* mitem = item.mutableCopy;
                NSString* key = mitem[@"key"];
                [mitem removeObjectForKey:@"key"];
                updateDBData("month", key.intValue, mitem);
            }
            setlocalKV(@"stat_month", nil);
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
        sprintf(sql, "select data from %s where id > %d order by id asc limit %d", tbl, last_id, n);
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
        sqlite3_finalize(stmt);
        return result;
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
    NSDictionary* info_h = getFilteredMDic(bat_info, @[
        @"Amperage", @"AppleRawCurrentCapacity", @"CurrentCapacity", @"ExternalChargeCapable", @"ExternalConnected",
        @"InstantAmperage", @"IsCharging", @"Temperature", @"UpdateTime", @"Voltage"
    ]);
    updateDBData("min5", ts / 300, info_h);
    updateDBData("hour", ts / 3600, info_h);
    NSDictionary* info_d = getFilteredMDic(bat_info, @[
        @"CycleCount", @"DesignCapacity", @"NominalChargeCapacity", @"UpdateTime"
    ]);
    updateDBData("day", ts / 86400, info_d);
    updateDBData("month", ts / 2592000, info_d);
}

static void onBatteryEventEnd() {
    NSNumber* adv_thermal_mode_lock = getlocalKV(@"adv_thermal_mode_lock");
    if (adv_thermal_mode_lock.boolValue) {
        NSString* mode = getlocalKV(@"adv_def_thermal_mode");
        setThermalSimulationMode(mode);
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
        NSNumber* is_inflow_enabled = bat_info[@"ExternalConnected"];
        BOOL is_adaptor_connected = isAdaptorConnect(bat_info);
        NSNumber* adv_disable_inflow = getlocalKV(@"adv_disable_inflow");
        NSNumber* temperature_ = bat_info[@"Temperature"];
        float temperature = temperature_.intValue / 100.0;
        // 优先级: 电量极低 > 停充(电量>温度) > 充电(电量>温度) > 插电
        do {
            if (capacity.intValue <= 5) { // 电量极低,优先级=1
                // 防止误用或意外造成无法充电
                if (is_adaptor_connected && !is_charging.boolValue) {
                    NSFileLog(@"start charging for extremely low capacity");
                    setInflowStatus(YES);
                    setBatteryStatus(YES);
                    performAcccharge(YES);
                }
                break;
            }
            if (capacity.intValue >= charge_above.intValue) { // 停充-电量高,优先级=2
                if (is_charging.boolValue) {
                    NSFileLog(@"stop charging for high capacity");
                    setBatteryStatus(NO);
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
                if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                    NSFileLog(@"disable inflow for high capacity");
                    setInflowStatus(NO);
                }
                break;
            }
            if (enable_temp.boolValue && temperature >= charge_temp_above.intValue) { // 停充-温度高,优先级=3
                if (is_charging.boolValue) {
                    NSFileLog(@"stop charging for high temperature");
                    setBatteryStatus(NO);
                    performAction(@"stop_charge");
                    performAcccharge(NO);
                }
                if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                    NSFileLog(@"disable inflow for high temperature");
                    setInflowStatus(NO);
                }
                break;
            }
            if (capacity.intValue <= charge_below.intValue) { // 充电-电量低,优先级=4
                // 禁流模式下电量下降后恢复充电
                if (is_adaptor_connected) {
                    if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                        NSFileLog(@"enable inflow for low capacity");
                        setInflowStatus(YES);
                    }
                    if (!is_charging.boolValue) {
                        NSFileLog(@"start charging for low capacity");
                        setBatteryStatus(YES);
                        performAction(@"start_charge");
                        performAcccharge(YES);
                    }
                }
                break;
            }
            if ([mode isEqualToString:@"charge_on_plug"]) {
                if (enable_temp.boolValue && temperature <= charge_temp_below.intValue) { // 充电-温度低,优先级=5
                    if (is_adaptor_connected) {
                        if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                            NSFileLog(@"enable inflow for low temperature");
                            setInflowStatus(YES);
                        }
                        if (!is_charging.boolValue) {
                            NSFileLog(@"start charging for low temperature");
                            setBatteryStatus(YES);
                            performAction(@"start_charge");
                            performAcccharge(YES);
                        }
                    }
                    break;
                }
                if (isAdaptorNewConnect(old_bat_info, bat_info)) { // 充电-插电,优先级=6
                    if (adv_disable_inflow.boolValue && !is_inflow_enabled.boolValue) {
                        NSFileLog(@"enable inflow for plug in");
                        setInflowStatus(YES);
                    }
                    if (!is_charging.boolValue) {
                        NSFileLog(@"start charging for plug in");
                        setBatteryStatus(YES);
                        performAction(@"start_charge");
                        performAcccharge(YES);
                    }
                    break;
                }
            } else if ([mode isEqualToString:@"edge_trigger"]) {
                if (isAdaptorNewConnect(old_bat_info, bat_info)) {
                    if (!is_charging.boolValue) {
                        NSFileLog(@"stop charging for plug in");
                        setBatteryStatus(NO);
                    }
                    if (adv_disable_inflow.boolValue && is_inflow_enabled.boolValue) {
                        NSFileLog(@"disable inflow for plug in");
                        setInflowStatus(NO);
                    }
                }
                break;
            }
        } while(false);
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
            @"enable": @YES,
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
            spawn(@[getAppEXEPath(), @"floatwnd"], nil, nil, &floatwnd_pid, SPAWN_FLAG_NOWAIT, param);
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
            NSMutableDictionary* kv = [cache_kv mutableCopy];
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
        return @{
            @"status": @0,
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
    initConf(NO);
    initDB();
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

static void start_daemon() {
    if (g_jbtype == JBTYPE_TROLLSTORE) {
        NSTimer* start_daemon_timer = [NSTimer timerWithTimeInterval:10 repeats:YES block:^(NSTimer* timer) {
            if (!localPortOpen(GSERV_PORT)) {
                spawn(@[getAppEXEPath(), @"daemon"], nil, nil, 0, SPAWN_FLAG_ROOT | SPAWN_FLAG_NOWAIT);
            }
        }];
        [start_daemon_timer fire];
        [NSRunLoop.currentRunLoop addTimer:start_daemon_timer forMode:NSDefaultRunLoopMode];
    }
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
                    set_mem_limit(getpid(), 80);
                }
                [Service.inst serve];
                atexit_b(^{
                    resetBatteryStatus();
                    showFloatwnd(NO);
                    uninitDB();
                    [LSApplicationWorkspace.defaultWorkspace removeObserver:Service.inst];
                });
                [NSRunLoop.mainRunLoop run];
                NSFileLog(@"daemon unexpected");
                return 0;
            } else if (0 == strcmp(argv[1], "floatwnd")) {
                start_daemon();
                g_wind_type = 1;
                static id<UIApplicationDelegate> appDelegate = [AppDelegate new];
                UIApplicationInstantiateSingleton(HUDMainApplication.class);
                static UIApplication* app = [UIApplication sharedApplication];
                [app setDelegate:appDelegate];
                [app __completeAndRunAsPlugin];
                CFRunLoopRun();
                return 0;
            } else if (0 == strcmp(argv[1], "reset")) { // 越狱下卸载前重置
                resetBatteryStatus();
                return 0;
            } else if (0 == strcmp(argv[1], "get_bat_info")) {
                BOOL slim = argc == 3;
                getBatInfo(&bat_info, slim);
                NSLog(@"%@", bat_info);
            }
        }
        return -1;
    }
}

