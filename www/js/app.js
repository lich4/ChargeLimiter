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
            update_freq: "Update frequency",
            charge_below: "Start charge capacity below(%)",
            nocharge_above: "Stop charge capacity above(%)",
            nocharge_temp_above: "Stop charge temperature above(°C)",
            charge_btn_desc: "This button used to manually start or stop charging",
            start_serv: "Start service",
            mode: "mode",
            charge_on_plug: "Plug and charge",
            charge_on_plug_desc: "iDevice will start charging whenever adaptor plug in, and stop charging when capacity increase to max threshhold specified",
            edge_trigger: "Edge trigger",
            edge_trigger_desc: "iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified",
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
            update_freq: "更新频率",
            charge_below: "电量低于(%)开始充电",
            nocharge_above: "电量高于(%)停止充电",
            nocharge_temp_above: "温度高于(°C)停止充电",
            charge_btn_desc: "此按钮用于手动开始或停止充电",
            start_serv: "启动服务",
            mode: "模式",
            charge_on_plug: "插电即充",
            charge_on_plug_desc: "插入电源后开始充电,到达指定的最大电量时停止充电",
            edge_trigger: "边缘触发",
            edge_trigger_desc: "到达最大电量时停止充电,当且仅当电量低于指定的最小电量时开始充电",
            charge_on_plug: "插电即充",
            edge_trigger: "边缘触发",
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
            update_freq: "更新頻率",
            charge_below: "電量低於(%)開始充電",
            nocharge_above: "電量高於(%)停止充電",
            nocharge_temp_above: "溫度高於(°C)停止充電",
            charge_btn_desc: "此按鈕用於手動開始或停止充電",
            start_serv: "啟動服務",
            mode: "模式",
            charge_on_plug: "插電即充",
            charge_on_plug_desc: "插入電源後充電直到到達指定的最大電量時停止充電",
            edge_trigger: "邊緣觸發",
            edge_trigger_desc: "於電量低於最小電量時開始充電，並且到達最大電量時停止充電",
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
            mode: "charge_on_plug",
            msg_list: [],
            bat_info: {},
            adaptor_info: {},
            charge_below: 20,
            charge_above: 80,
            enable_temp: false,
            charge_temp_above: 35,
            count_msg: "",
            timer: null,
            marks_perc: range(0, 110, 10).reduce((m, o)=>{m[o] = o + "%"; return m;}, {}),
            marks_temp: range(20, 60, 5).reduce((m, o)=>{m[o] = o + "°C/" + t_c_to_f(o).toFixed(0) + "°F"; return m;}, {}),
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
        set_daemon_status: function(v) {
            if (!v) {
                this.ipc_send_wrapper({
                    api: "exit",
                });
                this.daemon_alive = false;
            } else { // 重启App即可打开服务
                location.href = "app://exit";
            }
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
        get_conf_cb: function(jdata) {
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
            console.log("change_lang", v);
            set_local_val("conf", "lang", v);
            this.reload_locale();
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "lang",
                val: v,
            });
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
})

if (location.port == 5500) {
    window.test = true;
}
