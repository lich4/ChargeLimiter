const model_dic = {
    "iPhone4,1": "iPhone 4S",
    "iPhone5,1": "iPhone 5",
    "iPhone5,2": "iPhone 5",
    "iPhone5,3": "iPhone 5C",
    "iPhone5,4": "iPhone 5C",
    "iPhone6,1": "iPhone 5S",
    "iPhone6,2": "iPhone 5S",
    "iPhone7,2": "iPhone 6",
    "iPhone7,1": "iPhone 6P",
    "iPhone8,1": "iPhone 6S",
    "iPhone8,2": "iPhone 6SP",
    "iPhone8,4": "iPhone SE",
    "iPhone9,1": "iPhone 7",
    "iPhone9,2": "iPhone 7P",
    "iPhone9,3": "iPhone 7",
    "iPhone9,4": "iPhone 7P",
    "iPhone10,1": "iPhone 8",
    "iPhone10,4": "iPhone 8",
    "iPhone10,2": "iPhone 8P",
    "iPhone10,5": "iPhone 8P",
    "iPhone10,3": "iPhone X",
    "iPhone10,6": "iPhone X",
    "iPhone11,2": "iPhone XS",
    "iPhone11,4": "iPhone XSMax",
    "iPhone11,6": "iPhone XSMax",
    "iPhone11,8": "iPhone XR",
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11Pro",
    "iPhone12,5": "iPhone 11ProMax",
    "iPhone12,8": "iPhone SE2",
    "iPhone13,1": "iPhone 12Mini",
    "iPhone13,2": "iPhone 12",
    "iPhone13,3": "iPhone 12Pro",
    "iPhone13,4": "iPhone 12ProMax",
    "iPhone14,4": "iPhone 13Mini",
    "iPhone14,5": "iPhone 13",
    "iPhone14,2": "iPhone 13Pro",
    "iPhone14,3": "iPhone 13ProMax",
    "iPhone14,6": "iPhone SE3",
    "iPhone14,7": "iPhone 14",
    "iPhone14,8": "iPhone 14Plus",
    "iPhone15,2": "iPhone 14Pro",
    "iPhone15,3": "iPhone 14ProMax",
    "iPhone15,4": "iPhone 15",
    "iPhone15,5": "iPhone 15Plus",
    "iPhone16,1": "iPhone 15Pro",
    "iPhone16,2": "iPhone 15ProMax",
    "iPad2,1": "iPad 2nd",
    "iPad2,2": "iPad 2nd",
    "iPad2,3": "iPad 2nd",
    "iPad2,4": "iPad 2nd",
    "iPad2,5": "iPad mini 1st",
    "iPad2,6": "iPad mini 1st",
    "iPad2,7": "iPad mini 1st",
    "iPad3,1": "iPad 3rd",
    "iPad3,2": "iPad 3rd",
    "iPad3,3": "iPad 3rd",
    "iPad3,4": "iPad 4th",
    "iPad3,5": "iPad 4th",
    "iPad3,6": "iPad 4th",
    "iPad4,1": "iPad Air 1st",
    "iPad4,2": "iPad Air 1st",
    "iPad4,3": "iPad Air 1st",
    "iPad4,4": "iPad mini 2nd",
    "iPad4,5": "iPad mini 2nd",
    "iPad4,6": "iPad mini 2nd",
    "iPad4,7": "iPad mini 3rd",
    "iPad4,8": "iPad mini 3rd",
    "iPad4,9": "iPad mini 3rd",
    "iPad5,1": "iPad mini 4th",
    "iPad5,2": "iPad mini 4th",
    "iPad5,3": "iPad Air 2nd",
    "iPad5,4": "iPad Air 2nd",
    "iPad6,3": "iPad Pro 9.7",
    "iPad6,4": "iPad Pro 9.7",
    "iPad6,7": "iPad Pro 12.9 1st",
    "iPad6,8": "iPad Pro 12.9 1st",
    "iPad6,11": "iPad 5th",
    "iPad6,12": "iPad 5th",
    "iPad7,1": "iPad Pro 12.9 2nd",
    "iPad7,2": "iPad Pro 12.9 2nd",
    "iPad7,3": "iPad Pro 10.5",
    "iPad7,4": "iPad Pro 10.5",
    "iPad7,5": "iPad 6th",
    "iPad7,6": "iPad 6th",
    "iPad7,11": "iPad 7th",
    "iPad7,12": "iPad 7th",
    "iPad8,1": "iPad Pro 11 1st",
    "iPad8,2": "iPad Pro 11 1st",
    "iPad8,3": "iPad Pro 11 1st",
    "iPad8,4": "iPad Pro 11 1st",
    "iPad8,5": "iPad Pro 12.9 3rd",
    "iPad8,6": "iPad Pro 12.9 3rd",
    "iPad8,7": "iPad Pro 12.9 3rd",
    "iPad8,8": "iPad Pro 12.9 3rd",
    "iPad8,9": "iPad Pro 11 2nd",
    "iPad8,10": "iPad Pro 11 2nd",
    "iPad8,11": "iPad Pro 12.9 4th",
    "iPad8,12": "iPad Pro 12.9 4th",
    "iPad11,1": "iPad mini 5th",
    "iPad11,2": "iPad mini 5th",
    "iPad11,3": "iPad Air 3rd",
    "iPad11,4": "iPad Air 3rd",
    "iPad11,6": "iPad 8th",
    "iPad11,7": "iPad 8th",
    "iPad12,1": "iPad 9th",
    "iPad12,2": "iPad 9th",
    "iPad13,1": "iPad Air 4th",
    "iPad13,2": "iPad Air 4th",
    "iPad13,4": "iPad Pro 11 3rd",
    "iPad13,5": "iPad Pro 11 3rd",
    "iPad13,6": "iPad Pro 11 3rd",
    "iPad13,7": "iPad Pro 11 3rd",
    "iPad13,8": "iPad Pro 12.9 5th",
    "iPad13,9": "iPad Pro 12.9 5th",
    "iPad13,10": "iPad Pro 12.9 5th",
    "iPad13,11": "iPad Pro 12.9 5th",
    "iPad13,16": "iPad Air 5th",
    "iPad13,17": "iPad Air 5th",
    "iPad13,18": "iPad 10th",
    "iPad13,19": "iPad 10th",
    "iPad14,1": "iPad mini 6th",
    "iPad14,2": "iPad mini 6th",
    "iPad14,3": "iPad Pro 11 4th",
    "iPad14,4": "iPad Pro 11 4th",
    "iPad14,5": "iPad Pro 12.9 6th",
    "iPad14,6": "iPad Pro 12.9 6th",
};

const i18n = new VueI18n({
    locale: get_local_lang(),
    messages: {
        en: { // html
            label: "English",
            lang: "Language",
            suc: "Success",
            fail: "Failed",
            setting: "Settings",
            batinfo: "Battery information",
            adaptorinfo: "Adaptor information",
            sysinfo: "System information",
            update_freq: "Update frequency",
            update_freq_desc: "Lower frequency, slower responses, but may save more power",
            charge_below: "Start charging if capacity below(%)",
            nocharge_above: "Stop charging if capacity above(%)",
            nocharge_temp_above: "Stop charging if temperature above(°C)",
            charge_temp_below: "Recover charging if temperature below(°C)",
            charge_btn_desc: "This button used to manually start or stop charging, the charging icon on system status bar is invalid, just ignore it",
            inflow_btn_desc: "This button used to manually start or stop inflow",
            enable: "Enable",
            floatwnd: "Floating window",
            mode: "mode",
            charge_on_plug: "Plug and charge",
            charge_on_plug_desc: "iDevice will start charging when replug the USB cable, and stop charging when capacity increase to max threshhold specified",
            edge_trigger: "Edge trigger",
            edge_trigger_desc: "iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified",
            temp_ctrl: "Temperature control",
            acc_charge: "Speedup charging",
            acc_charge_desc: "Enable Airplane Mode, disable WiFi, enable LPM, disable Bluetooth, and minimize brightness automatically during charging",
            acc_charge_airmode: "Enable Airplane Mode",
            acc_charge_wifi: "Disable WiFi",
            acc_charge_lpm: "Enable Lower Power Mode",
            acc_charge_blue: "Disable Bluetooth",
            acc_charge_bright: "Minimize brightness",
            action: "Action",
            adv: "Advanced",
            adv_prefer_smart: "Use SmartBattery",
            adv_predictive_inhibit_charge: "Predictive charging inhibit",
            adv_disable_inflow: "Control inflow",
            adv_thermal_simulate: "Thermal simulation(Powercuff) during charging",
            adv_ppm_simulate: "LowTemp/PeakPower performance(PPM)",
            thermal_simulate_mode: "Powercuff mode",
            ppm_simulate_mode: "PPM mode",
            none: "None",
            noti: "Notification",
            system: "system",
            sec: "sec",
            min: "min",
            Serial: "Serial",
            BootVoltage: "Boot voltage(V)",
            Voltage: "Voltage(V)",
            AdapterVoltage: "Voltage(V)",
            Current: "Current(mA)",
            Watts: "Watts(W)",
            DesignCapacity: "Design capacity(mAh)",
            NominalChargeCapacity: "Nominal charge capacity(mAh)",
            InstantAmperage: "Instant amperage(mA)",
            CurrentCapacity: "Current capacity",
            HardwareCapacity: "Hardware capacity",
            Temperature: "Temperature(°C)",
            CycleCount: "Cycle count",
            IsCharging: "Charging",  
            BatteryInstalled: "Battery installed",
            ExternalChargeCapable: "External charge capable",
            ExternalConnected: "External connected",
            Name: "Name",
            Description: "Description",
            Manufacturer: "Manufacturer",
            WirelessCharge: "Wireless charge",
            UpdateAt: "Updated at",
            Health: "Health",
            conn_adaptor: "Please connect to an adaptor first",
            wait_update: "Please wait {0} sec to take effect",
            conn_daemon_error: "Service connect failed",
            input_error: "Input error",
            wait: "Please wait",
            "batt": "Battery",
            "usb host": "Host USB",
            "baseline arcas": "Wireless charger",
            "pd charger": "PD charger",
            "usb charger": "USB charger",
            "magsafe acc": "MagSafe charger",
            sysver: "System version",
            model: "Device model",
            sysboot: "System boot time",
            servboot: "Service boot time",
            off: "Off",
            nominal: "Nominal",
            light: "Light",
            moderate: "Moderate",
            heavy: "Heavy",
            copy_to_pb: "Copy all data to pasteboard",
            view_hist: "History",
            open_safari: "Open in Safari",
            manual: "Manual",
            author: "Author",
            contact: "Contact",
        },
        zh_CN: { // html
            label: "简体中文",
            lang: "语言",
            suc: "成功",
            fail: "失败",
            setting: "设置",
            batinfo: "电池信息",
            adaptorinfo: "电源信息",
            sysinfo: "系统信息",
            update_freq: "更新频率",
            update_freq_desc: "降低频率后响应速度变慢,但可能更省电",
            charge_below: "电量低于(%)开始充电",
            nocharge_above: "电量高于(%)停止充电",
            nocharge_temp_above: "温度高于(°C)停止充电",
            charge_temp_below: "温度低于(°C)恢复充电",
            charge_btn_desc: "此按钮用于手动开始或停止充电,系统状态栏充电状态无效,以CL显示为准",
            inflow_btn_desc: "此按钮用于手动开始或停止禁流",
            enable: "开启",
            floatwnd: "悬浮窗",
            mode: "模式",
            charge_on_plug: "插电即充",
            charge_on_plug_desc: "(重新)插入电源后开始充电,到达指定的最大电量时停止充电",
            edge_trigger: "边缘触发",
            edge_trigger_desc: "到达最大电量时停止充电,当且仅当电量低于指定的最小电量时开始充电",
            temp_ctrl: "温度控制",
            acc_charge: "快速充电",
            acc_charge_desc: "充电时自动开启飞行模式,关闭WiFi,低电量模式,关闭蓝牙,调暗屏幕",
            acc_charge_airmode: "开启飞行模式",
            acc_charge_wifi: "关闭WiFi",
            acc_charge_lpm: "开启低电量模式",
            acc_charge_blue: "关闭蓝牙",
            acc_charge_bright: "亮度最低",
            action: "行为",
            adv: "高级",
            adv_prefer_smart: "使用SmartBattery",
            adv_predictive_inhibit_charge: "智能停充",
            adv_disable_inflow: "停充时启用禁流",
            adv_thermal_simulate: "充电时模拟温度(Powercuff)",
            adv_ppm_simulate: "低温性能/峰值性能(PPM)",
            thermal_simulate_mode: "Powercuff模式",
            ppm_simulate_mode: "PPM模式",
            off: "无",
            nominal: "正常",
            light: "轻度",
            moderate: "中度",
            heavy: "重度",
            none: "无",
            noti: "通知",
            system: "系统",
            sec: "秒",
            min: "分种",
            Serial: "序列号",
            BootVoltage: "开机电压(V)",
            Voltage: "电压(V)",
            AdapterVoltage: "电压(V)",
            Current: "电流(mA)",
            Watts: "功率(W)",
            DesignCapacity: "设计容量(mAh)",
            NominalChargeCapacity: "实际容量(mAh)",
            InstantAmperage: "电流(mA)",
            CurrentCapacity: "当前电量",
            HardwareCapacity: "硬件电量",
            Temperature: "温度(°C)",
            CycleCount: "充电次数",
            IsCharging: "正在充电",
            BatteryInstalled: "电池已安装",
            ExternalChargeCapable: "电源可充电",
            ExternalConnected: "电源已连接",
            Name: "名称",
            Description: "描述",
            Manufacturer: "厂商",
            WirelessCharge: "无线充电",
            UpdateAt: "更新于",
            Health: "健康度",
            conn_adaptor: "请先连接电源",
            wait_update: "请等待{0}秒生效",
            conn_daemon_error: "服务连接失败",
            input_error: "输入有误",
            "wait": "请等待",
            "batt": "电池",
            "usb host": "主机USB",
            "baseline arcas": "无线充电器",
            "pd charger": "PD快充器",
            "usb charger": "USB充电器",
            "magsafe acc": "MagSafe充电器",
            sysver: "系统版本",
            model: "设备型号",
            sysboot: "系统启动时间",
            servboot: "服务启动时间",
            copy_to_pb: "拷贝所有数据到剪贴板",
            view_hist: "历史统计",
            open_safari: "在Safari中打开",
            manual: "使用手册",
            author: "作者",
            contact: "联系方式",
        },
        zh_TW: { // html
            label: "繁體中文",
            lang: "語言",
            suc: "成功",
            fail: "失敗",
            setting: "設定",
            batinfo: "電池資訊",
            adaptorinfo: "電源資訊",
            sysinfo: "系統資訊",
            update_freq: "更新頻率",
            update_freq_desc: "降低頻率後響應速度變慢,但可能更省電",
            charge_below: "電量低於(%)開始充電",
            nocharge_above: "電量高於(%)停止充電",
            nocharge_temp_above: "溫度高於(°C)停止充電",
            charge_temp_below: "溫度低於(°C)恢復充電",
            charge_btn_desc: "此按鈕用於手動開始或停止充電,系統狀態欄充電狀態無效,以CL顯示為準",
            inflow_btn_desc: "此按鈕用於手動開始或停止禁流",
            enable: "開啟",
            floatwnd: "懸浮窗",
            mode: "模式",
            charge_on_plug: "插電即充",
            charge_on_plug_desc: "(重新)插入電源後充電直到到達指定的最大電量時停止充電",
            edge_trigger: "邊緣觸發",
            edge_trigger_desc: "於電量低於最小電量時開始充電，並且到達最大電量時停止充電",
            temp_ctrl: "溫度控制",
            acc_charge: "快速充電",
            acc_charge_desc: "充電時自動開啟飛行模式,關閉WiFi,低電量模式,關閉藍牙,調暗屏幕",
            acc_charge_airmode: "開啟飛行模式",
            acc_charge_wifi: "關閉WiFi",
            acc_charge_lpm: "開啟低電量模式",
            acc_charge_blue: "關閉藍牙",
            acc_charge_bright: "亮度最低",
            action: "行為",
            adv: "高級",
            adv_prefer_smart: "使用SmartBattery",
            adv_predictive_inhibit_charge: "智能停充",
            adv_disable_inflow: "停充時啟用禁流",
            adv_thermal_simulate: "充電時模擬溫度(Powercuff)",
            adv_ppm_simulate: "低溫性能/峰值性能設置",
            thermal_simulate_mode: "Powercuff模式",
            ppm_simulate_mode: "PPM模式",
            off: "無",
            nominal: "正常",
            light: "輕度",
            moderate: "中度",
            heavy: "重度",
            none: "無",
            noti: "通知",
            system: "系統",
            sec: "秒",
            min: "分鐘",
            Serial: "序號",
            BootVoltage: "開機電壓(V)",
            Voltage: "電壓(V)",
            AdapterVoltage: "電壓(V)",
            Current: "電流(mA)",
            Watts: "功率(W)",
            DesignCapacity: "表定容量(mAh)",
            NominalChargeCapacity: "實際容量(mAh)",
            InstantAmperage: "電流(mA)",
            CurrentCapacity: "目前電量",
            HardwareCapacity: "硬體電量",
            Temperature: "溫度(°C)",
            CycleCount: "充電次數",
            IsCharging: "正在充電",
            BatteryInstalled: "已安裝電池",
            ExternalChargeCapable: "電源可充電",
            ExternalConnected: "電源已連結",
            Name: "名稱",
            Description: "敘述",
            Manufacturer: "廠商",
            WirelessCharge: "無線充電",
            UpdateAt: "更新於",
            Health: "電池健康度",
            conn_adaptor: "請連接電源",
            wait_update: "請等待{0}秒生效",
            conn_daemon_error: "服務連結失敗",
            input_error: "輸入有誤",
            "wait": "請稍候",
            "batt": "電池",
            "usb host": "主機 USB",
            "baseline arcas": "無線充電器",
            "pd charger": "PD快充器",
            "usb charger": "USB充電器",
            "magsafe acc": "MagSafe充電器",
            sysver: "系統版本",
            model: "設備型號",
            sysboot: "系統啟動時間",
            servboot: "服務啟動時間",
            copy_to_pb: "拷貝所有數據到剪貼板",
            view_hist: "歷史統計",
            open_safari: "在Safari中打開",
            manual: "使用手冊",
            author: "作者",
            contact: "聯絡方式",
        }
    },
})

const App = {
    el: "#app",
    i18n,
    data: function () {
        return {
            title: "ChargeLimiter",
            loading: false,
            daemon_alive: false,
            enable: false,
            ver: "?",
            update_freq: 1,
            dark: get_local_val("conf", "dark", false),
            lang: get_local_val("conf", "lang", "en"),
            sysver: "",
            devmodel: "",
            floatwnd: false,
            mode: "charge_on_plug",
            msg_list: [],
            bat_info: {},
            adaptor_info: {},
            charge_below: 20,
            charge_above: 80,
            enable_temp: false,
            charge_temp_above: 35,
            charge_temp_below: 10,
            acc_charge: false,
            acc_charge_airmode: true,
            acc_charge_wifi: false,
            acc_charge_blue: false,
            acc_charge_bright: false,
            acc_charge_lpm: true,
            action: "",
            enable_adv: false, 
            adv_prefer_smart: false,
            adv_predictive_inhibit_charge: false,
            adv_disable_inflow: false,
            sys_boot: 0,
            serv_boot: 0,
            use_smart: false,
            count_msg: "",
            timer: null,
            marks_perc: range(0, 110, 10).reduce((m, o)=>{m[o] = o + "%"; return m;}, {}),
            marks_temp: range(0, 60, 5).reduce((m, o)=>{m[o] = o + "°C/" + t_c_to_f(o).toFixed(0) + "°F"; return m;}, {}),
            freqs: null,
            modes: null,
            actions: null,
            cuffmods: null,
        }
    },
    methods: {
        block_ui: function (flag) {
            this.loading = flag;
        },
        ipc_send_wrapper: function(req) {
            var that = this;
            ipc_send(req, status => {
                if (!status) {
                    this.msg_list.push({
                        "id": get_id(), 
                        "title": that.$t("conn_daemon_error"), 
                        "type": "error",
                        "time": 3000,
                    });
                }
                that.daemon_alive = status;
            });
        },
        get_bat_info_cb: function(jdata) {
            this.daemon_alive = true;
            if (jdata.status == 0) {
                this.bat_info = jdata.data;
                this.adaptor_info = jdata.data.AdapterDetails;
            } else {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("fail") + ": " + jdata.status, 
                    "type": "error",
                    "time": 3000,
                });
            }
        },
        get_bat_info: function() {
            this.ipc_send_wrapper({
                api: "get_bat_info",
                callback: "window.app.get_bat_info_cb",
            });
        },
        set_enable: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "enable",
                val: v,
            });
            this.enable = v;
            setTimeout(this.get_conf, tmout * 1000);
        },
        set_floatwnd: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "floatwnd",
                val: v,
            });
            this.floatwnd = v;
            setTimeout(this.get_conf, tmout * 1000);
        },
        set_inflow_status: function(v) {
            this.ipc_send_wrapper({
                api: "set_inflow_status",
                flag: v,
            });
            setTimeout(this.get_bat_info, tmout * 1000);
        },
        set_charge_status_cb: function(jdata) {
            var that = this;
            var status = jdata.status;
            if (status == 0) {
                var tmout = 0;
                if (this.bat_info.PostChargeWaitSeconds) {
                    tmout = this.bat_info.PostChargeWaitSeconds;
                    var tmout_count = tmout;
                    that.h_msg = {
                        "id": get_id(), 
                        "title": that.$t("wait_update").format(tmout_count),
                        "type": "info",
                        "time": tmout * 1000,
                    };
                    var old_status = that.bat_info.IsCharging;
                    that.h_ = setInterval(()=>{
                        tmout_count -= 1;
                        that.h_msg.title = that.$t("wait_update").format(tmout_count);
                        if (tmout_count <= 0 || old_status != that.bat_info.IsCharging) {
                            clearInterval(that.h_);
                            that.h_ = null;
                            var index = that.msg_list.findIndex(e => e.id == that.h_msg.id);
                            if (index > -1) {
                                that.msg_list.splice(index, 1);
                            }
                        }
                    }, 1000);
                    this.msg_list.push(that.h_msg);
                }
                tmout += 1;
                setTimeout(this.get_bat_info, tmout * 1000);
            } else if (status == -3) {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("conn_adaptor"), 
                    "type": "error",
                    "time": 3000,
                });
            } else {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("fail") + ":" + status, 
                    "type": "error",
                    "time": 3000,
                });
            }  
        },
        set_charge_status: function(v) {
            if (this.h_) {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("wait"), 
                    "type": "error",
                    "time": 3000,
                });
                return;
            }
            if (v) {
                if (!this.bat_info.ExternalChargeCapable) {
                    this.msg_list.push({
                        "id": get_id(), 
                        "title": this.$t("conn_adaptor"), 
                        "type": "error",
                        "time": 3000,
                    });
                    return;
                }
            }
            this.ipc_send_wrapper({
                api: "set_charge_status",
                callback: "window.app.set_charge_status_cb",
                flag: v,
            });
        },
        set_charge_below: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_below",
                val: v,
            });
            setTimeout(this.get_conf, tmout * 1000);
        },
        set_charge_above: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_above",
                val: v,
            });
            setTimeout(this.get_conf, tmout * 1000);
        },
        change_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "mode",
                val: v,
            });
            setTimeout(this.get_conf, tmout * 1000);
        },
        change_action: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "action",
                val: v,
            });
            setTimeout(this.get_conf, tmout * 1000);
        },
        set_use_smart: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_prefer_smart",
                val: v,
            });
            setTimeout(() => {
                location.href = "cl://start_daemon";
            }, 200);
            setTimeout(this.get_conf, 3000); // 须重启daemon
        },
        set_predictive_inhibit_charge: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_predictive_inhibit_charge",
                val: v,
            });
            this.adv_predictive_inhibit_charge = v;
            setTimeout(this.get_conf, 1000);
        },
        set_disable_inflow: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_disable_inflow",
                val: v,
            });
            this.adv_disable_inflow = v;
            setTimeout(this.get_conf, 1000);
        },
        get_health: function(item) {
            return Math.floor(item["NominalChargeCapacity"] / item["DesignCapacity"] * 100);
        },
        get_hardware_capacity: function() {
            var v = (this.bat_info.AppleRawCurrentCapacity / this.bat_info.NominalChargeCapacity * 100).toFixed(2);
            return v + "%";
        },
        get_adaptor_desc: function() {
            var s = "";
            if (this.adaptor_info.Description) {
                s += "[" + this.adaptor_info.Description + "] ";
            }
            if (this.adaptor_info.Manufacturer) {
                s += "[" + this.adaptor_info.Manufacturer + " ";
            }
            if (this.adaptor_info.Name) {
                s += this.adaptor_info.Name + " ";
            }
            return s;
        },
        get_adaptor_desc: function() {
            return this.$t(this.adaptor_info.Description) + "(" + this.adaptor_info.Description + ")";
        },
        get_devmodel_desc: function() {
            var name = model_dic[this.devmodel];
            if (!name) {
                return this.devmodel;
            }
            return name + "(" + this.devmodel + ")";
        },
        change_update_freq: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "update_freq",
                val: v,
            });
            if (this.floatwnd) {
                this.set_floatwnd(false);
            }
            clearInterval(this.timer);
            this.timer = setInterval(this.get_bat_info, v * 1000);
        },
        get_temp_desc: function() {
            var centigrade = this.bat_info.Temperature / 100;
            var fahrenheit = t_c_to_f(centigrade);
            return centigrade.toFixed(0) + "°C/" + fahrenheit.toFixed(0) + "°F";
        },
        set_enable_temp: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "enable_temp",
                val: v,
            });
            this.enable_temp = v;
            setTimeout(this.get_conf, 1000);
        },
        set_charge_temp_above: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_temp_above",
                val: this.charge_temp_above,
            });
            setTimeout(this.get_conf, 1000);
        },
        set_charge_temp_below: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_temp_below",
                val: this.charge_temp_below,
            });
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge",
                val: v,
            });
            this.acc_charge = v;
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge_airmode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_airmode",
                val: v,
            });
            this.acc_charge_airmode = v;
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge_wifi: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_wifi",
                val: v,
            });
            this.acc_charge_wifi = v;
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge_lpm: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_lpm",
                val: v,
            });
            this.acc_charge_lpm = v;
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge_blue: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_blue",
                val: v,
            });
            this.acc_charge_blue = v;
            setTimeout(this.get_conf, 1000);
        },
        set_acc_charge_bright: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_bright",
                val: v,
            });
            this.acc_charge_bright = v;
            setTimeout(this.get_conf, 1000);
        },
        open_safari: function() {
            location.href = "safari://";
        },
        copy_to_pb: function() {
            var copy_bat_info = Object.assign({}, this.bat_info);
            delete copy_bat_info["Serial"];
            copy_bat_info["System"] = {
                sysver: this.sysver,
                devmodel: this.devmodel,
            }
            var data = JSON.stringify(copy_bat_info, null, 2)
            this.ipc_send_wrapper({
                api: "set_pb",
                val: data,
            });
            this.msg_list.push({
                "id": get_id(), 
                "title": this.$t("suc"), 
                "type": "success",
                "time": 1000,
            });
        },
        get_conf_cb: function(jdata) {
            this.enable = jdata.data.enable;
            this.ver = jdata.data.ver;
            this.update_freq = jdata.data.update_freq;
            this.sysver = jdata.data.sysver;
            this.devmodel = jdata.data.devmodel;
            this.floatwnd = jdata.data.floatwnd;
            this.mode = jdata.data.mode;
            this.lang = jdata.data.lang;
            if (this.lang && this.lang != get_local_lang()) {
                i18n.locale = this.lang;
                set_local_val("conf", "lang", this.lang);
                this.reload_locale();
            }
            this.charge_below = jdata.data.charge_below;
            this.charge_above = jdata.data.charge_above;
            this.enable_temp = jdata.data.enable_temp;
            this.charge_temp_above = jdata.data.charge_temp_above;
            this.charge_temp_below = jdata.data.charge_temp_below;
            this.acc_charge = jdata.data.acc_charge;
            this.acc_charge_airmode = jdata.data.acc_charge_airmode;
            this.acc_charge_wifi = jdata.data.acc_charge_wifi;
            this.acc_charge_blue = jdata.data.acc_charge_blue;
            this.acc_charge_bright = jdata.data.acc_charge_bright;
            this.acc_charge_lpm = jdata.data.acc_charge_lpm;
            this.action = jdata.data.action;
            this.adv_prefer_smart = jdata.data.adv_prefer_smart;
            this.adv_predictive_inhibit_charge = jdata.data.adv_predictive_inhibit_charge;
            this.adv_disable_inflow = jdata.data.adv_disable_inflow;
            this.use_smart = jdata.data.use_smart;
            this.sys_boot = jdata.data.sys_boot;
            this.serv_boot = jdata.data.serv_boot;
            if (this.timer == null) {
                this.get_bat_info();
                this.timer = setInterval(this.get_bat_info, this.update_freq * 1000);
            }
        },
        get_conf: function() {
            this.ipc_send_wrapper({
                api: "get_conf",
                callback: "window.app.get_conf_cb",
            });
        },
        change_lang: function() {
            var v = i18n.locale;
            set_local_val("conf", "lang", v);
            this.reload_locale();
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "lang",
                val: v,
            });
        },
        switch_dark: function(flag) {
            this.dark = flag;
            set_local_val("conf", "dark", this.dark);
            if (flag) {
                $("body").attr("class", "night");
            } else {
                $("body").removeAttr("class", "night");
            }
        },
        reload_locale: function() {
            this.freqs = [
                {"label": "1 " + this.$t("sec"), "value": 1},
                {"label": "20 " + this.$t("sec"), "value": 20},
                {"label": "1 " + this.$t("min"), "value": 60},
                {"label": "10 " + this.$t("min"), "value": 600},
            ];
            this.modes = [
                {"label": this.$t("charge_on_plug"), "value": "charge_on_plug"},
                {"label": this.$t("edge_trigger"), "value": "edge_trigger"},
            ];
            this.actions = [
                {"label": this.$t("none"), "value": ""},
                {"label": this.$t("noti"), "value": "noti"},
            ];
            this.cuffmods = [
                {"label": this.$t("off"), "value": "off"},
                {"label": this.$t("nominal"), "value": "nominal"},
                {"label": this.$t("light"), "value": "light"},
                {"label": this.$t("moderate"), "value": "moderate"},
                {"label": this.$t("heavy"), "value": "heavy"},
            ];
        },
    },
    directives: {
        timeout: {
            bind(el, binding, vnode) {
                var that = vnode.context.$root;
                var time = binding.value;
                var id = el.attributes.bind_data.value;
                setTimeout(() => {
                    var index = that.msg_list.findIndex(e => e.id == id);
                    if (index > -1) {
                        that.msg_list.splice(index, 1);
                    }
                }, time);
            }
        }
    },
    mounted: function () {
        if (this.dark) {
            this.switch_dark(true);
        }
        this.reload_locale();
        this.get_conf();      
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
    $(".noclick").click(() => {
        return false;
    });
})

