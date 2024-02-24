String.prototype.format = function () {
    var args = arguments;
    return this.replace(/{(\d+)}/g, function (match, number) {
        return typeof args[number]!='undefined'?args[number]:match;
    });
};

function set_local_val(path, key, val) {
    var data = localStorage.getItem(path);
    if (!data) {
        data = "{}";
    }
    var dic = JSON.parse(data);
    dic[key] = val;
    localStorage.setItem(path, JSON.stringify(dic));
}

function get_local_val(path, key) {
    var data = localStorage.getItem(path);
    if (!data) {
        return "";
    }
    var val = JSON.parse(data)[key];
    return val?val:"";
}

function get_local_lang() {
    var lang = get_local_val("conf", "lang");
    if (!lang) {
        var sp = navigator.language.split("-");
        if (sp[0] == "zh") {
            if (sp[1] == "TW") {
                lang = "zh_TW";
            } else {
                lang = "zh_CN";
            }
        } else {
            lang = sp[0];
        }
        set_local_val("conf", "lang", lang);
    }
    return lang;
}

function range (start, stop, step) {
    return Array.from({ length: (stop - start) / step}, (_, i) => start + (i * step));
}

function ts_to_date(timestamp) {
    var date = new Date(timestamp * 1000);
    var Y = date.getFullYear();
    var M = (date.getMonth() + 1 < 10 ? '0' + (date.getMonth() + 1) : date.getMonth() + 1);
    var D = (date.getDate() < 10)?'0' + date.getDate() : date.getDate();
    var h = (date.getHours() < 10)?'0' + date.getHours() : date.getHours();
    var m = (date.getMinutes() < 10)?'0' + date.getMinutes() : date.getMinutes();
    var s = (date.getSeconds() < 10)?'0' + date.getSeconds() : date.getSeconds();
    return Y + '-' + M + '-' + D + ' ' + h + ':' + m + ':' + s;
}

$.ajaxSetup({
    timeout: 1000,
});

function ipc_send(req, net_status_cb) {
    if (!window.test) {
        var rreq = JSON.stringify(req);
        $.post("/bridge", rreq, (data, status) => {
            if (net_status_cb) {
                net_status_cb(true);
            }
            var callback = req["callback"];
            if (callback) {
                eval(callback)(data);
            }
        }).fail(() => {
            if (net_status_cb) {
                net_status_cb(false);
            }
        });
    } else { // local test
        $.get("test.json", { _: $.now() }, (data, status) => {
            if (net_status_cb) {
                net_status_cb(true);
            }
            if (!data) {
                return;
            }
            var api = req["api"];
            var callback = req["callback"];
            if (callback) {
                if (data[api]) {
                    eval(callback)(data[api]);
                } else {
                    console.log("ipc_send unhandled err " + api);
                }
            }
        }).fail(() => {
            if (net_status_cb) {
                net_status_cb(false);
            }
        });
    }
}

function get_id() {
    return Date.now();
}

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
            charge_below: "Start charging if capacity below(%)",
            nocharge_above: "Stop charging if capacity above(%)",
            nocharge_temp_above: "Stop charging if temperature above(°C)",
            charge_temp_below: "Recover charging if temperature below(°C)",
            charge_btn_desc: "This button used to manually start or stop charging",
            enable: "Enable",
            floatwnd: "Floating",
            mode: "mode",
            charge_on_plug: "Plug and charge",
            charge_on_plug_desc: "iDevice will start charging whenever adaptor plug in, and stop charging when capacity increase to max threshhold specified",
            edge_trigger: "Edge trigger",
            edge_trigger_desc: "iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified",
            acc_charge: "Speedup charging",
            acc_charge_desc: "Enable Airplain Mode, enable LPM, disable Bluetooth, and minimize brightness automatically during charging",
            acc_charge_airmode: "Enable Airplain Mode",
            acc_charge_lpm: "Enable Lower Power Mode",
            acc_charge_blue: "Disable Bluetooth",
            acc_charge_bright: "Minimize brightness",
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
            "usb host": "Host USB",
            "baseline arcas": "Wireless charger",
            "pd charger": "PD charger",
            "usb charger": "USB charger",
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
            charge_below: "电量低于(%)开始充电",
            nocharge_above: "电量高于(%)停止充电",
            nocharge_temp_above: "温度高于(°C)停止充电",
            charge_temp_below: "温度低于(°C)恢复充电",
            charge_btn_desc: "此按钮用于手动开始或停止充电",
            enable: "开启",
            floatwnd: "悬浮窗",
            mode: "模式",
            charge_on_plug: "插电即充",
            charge_on_plug_desc: "插入电源后开始充电,到达指定的最大电量时停止充电",
            edge_trigger: "边缘触发",
            edge_trigger_desc: "到达最大电量时停止充电,当且仅当电量低于指定的最小电量时开始充电",
            acc_charge: "快速充电",
            acc_charge_desc: "充电时自动开启飞行模式,低电量模式,关闭蓝牙,调暗屏幕",
            acc_charge_airmode: "开启飞行模式",
            acc_charge_lpm: "开启低电量模式",
            acc_charge_blue: "关闭蓝牙",
            acc_charge_bright: "亮度最低",
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
            "usb host": "主机USB",
            "baseline arcas": "无线充电器",
            "pd charger": "PD快充器",
            "usb charger": "USB充电器",
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
            charge_below: "電量低於(%)開始充電",
            nocharge_above: "電量高於(%)停止充電",
            nocharge_temp_above: "溫度高於(°C)停止充電",
            charge_temp_below: "溫度低於(°C)恢復充電",
            charge_btn_desc: "此按鈕用於手動開始或停止充電",
            enable: "開啟",
            floatwnd: "懸浮窗",
            mode: "模式",
            charge_on_plug: "插電即充",
            charge_on_plug_desc: "插入電源後充電直到到達指定的最大電量時停止充電",
            edge_trigger: "邊緣觸發",
            edge_trigger_desc: "於電量低於最小電量時開始充電，並且到達最大電量時停止充電",
            acc_charge: "快速充電",
            acc_charge_desc: "充電時自動開啟飛行模式,低電量模式,關閉藍牙,調暗屏幕",
            acc_charge_airmode: "開啟飛行模式",
            acc_charge_lpm: "開啟低電量模式",
            acc_charge_blue: "關閉藍牙",
            acc_charge_bright: "亮度最低",
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
            "usb host": "主機 USB",
            "baseline arcas": "無線充電器",
            "pd charger": "PD 快充器",
            "usb charger": "USB 充電器",
            author: "作者",
            contact: "聯絡方式",
        }
    },
})

function t_c_to_f(v) {
    return 32 + 1.8 * v;
}

const App = {
    el: "#app",
    i18n,
    data: function () {
        return {
            title: "ChargeLimiter",
            loading: false,
            daemon_alive: false,
            enable: false,
            dark: false,
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
            acc_charge_blue: false,
            acc_charge_bright: false,
            acc_charge_lpm: true,
            count_msg: "",
            timer: null,
            marks_perc: range(0, 110, 10).reduce((m, o)=>{m[o] = o + "%"; return m;}, {}),
            marks_temp: range(0, 60, 5).reduce((m, o)=>{m[o] = o + "°C/" + t_c_to_f(o).toFixed(0) + "°F"; return m;}, {}),
            modes: null,
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
            this.enable = v;
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "enable",
                val: v,
            });
        },
        set_floatwnd: function(v) {
            this.floatwnd = v;
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "floatwnd",
                val: v,
            });
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
                    that.h_ = setInterval(()=>{
                        tmout_count -= 1;
                        that.h_msg.title = that.$t("wait_update").format(tmout_count);
                        if (tmout_count <= 0) {
                            clearInterval(that.h_);
                            that.h_ = null;
                        }
                    }, 1000);
                    this.msg_list.push(that.h_msg);
                }
                tmout += 1;
                setTimeout(()=> {
                    that.ipc_send_wrapper({
                        api: "get_bat_info",
                        update: true,
                        callback: "window.app.get_bat_info_cb",
                    });
                }, tmout * 1000);
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
                if (!this.bat_info.ExternalConnected) {
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
        },
        set_charge_above: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_above",
                val: v,
            });
        },
        change_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "mode",
                val: v,
            });
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
        },
        set_charge_temp_above: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_temp_above",
                val: this.charge_temp_above,
            });
        },
        set_charge_temp_below: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_temp_below",
                val: this.charge_temp_below,
            });
        },
        set_acc_charge: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge",
                val: v,
            });
            this.acc_charge = v;
        },
        set_acc_charge_airmode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_airmode",
                val: v,
            });
            this.acc_charge_airmode = v;
        },
        set_acc_charge_lpm: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_lpm",
                val: v,
            });
            this.acc_charge_lpm = v;
        },
        set_acc_charge_blue: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_blue",
                val: v,
            });
            this.acc_charge_blue = v;
        },
        set_acc_charge_bright: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_bright",
                val: v,
            });
            this.acc_charge_bright = v;
        },
        get_conf_cb: function(jdata) {
            this.enable = jdata.data.enable;
            this.dark = jdata.data.dark;
            if (this.dark) {
                this.switch_dark(true);
            }
            this.floatwnd = jdata.data.floatwnd;
            this.mode = jdata.data.mode;
            var lang = jdata.data.lang;
            if (lang && lang != get_local_lang()) {
                i18n.locale = lang;
                set_local_val("conf", "lang", lang);
                this.reload_locale();
            }
            this.charge_below = jdata.data.charge_below;
            this.charge_above = jdata.data.charge_above;
            this.enable_temp = jdata.data.enable_temp;
            this.charge_temp_above = jdata.data.charge_temp_above;
            this.charge_temp_below = jdata.data.charge_temp_below;
            this.acc_charge = jdata.data.acc_charge;
            this.acc_charge_airmode = jdata.data.acc_charge_airmode;
            this.acc_charge_blue = jdata.data.acc_charge_blue;
            this.acc_charge_bright = jdata.data.acc_charge_bright;
            this.acc_charge_lpm = jdata.data.acc_charge_lpm;
            this.get_bat_info();
            this.timer = setInterval(this.get_bat_info, 1000);
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
            if (flag) {
                $("body").attr("class", "night");
            } else {
                $("body").removeAttr("class", "night");
            }
        },
        reload_locale: function() {
            this.modes = [
                {"label": this.$t("charge_on_plug"), "value": "charge_on_plug"},
                {"label": this.$t("edge_trigger"), "value": "edge_trigger"},
            ];
        }
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

if (location.port >= 5500 && location.port <= 5510) {
    window.test = true;
}

