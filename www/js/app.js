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
    var lang = get_local_val("conf", "lang")
    if (!lang) {
        lang = navigator.language.split("-")[0];
        set_local_val("conf", "lang", lang);
    }
    return lang;
}

function range (start, stop, step) {
    return Array.from({ length: (stop - start) / step}, (_, i) => start + (i * step));
}

function ipc_send(req) {
    if (!window.test) {
        var rreq = JSON.stringify(req);
        $.post("/bridge", rreq, (data, status) => {
            var callback = req["callback"];
            if (callback) {
                eval(callback)(data);
            }
        });
    } else { // local test
        $.get("test.json", { _: $.now() }, (data, status) => {
            var api = req["api"];
            var callback = req["callback"];
            if (callback) {
                if (data[api]) {
                    eval(callback)(data[api]);
                } else {
                    console.log("ipc_send unhandled err " + api);
                }
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
            update_freq: "Update frequency",
            charge_below: "Start charge capacity below(%)",
            nocharge_above: "Stop charge capacity above(%)",
            Serial: "Serial",
            BootVoltage: "Boot voltage(V)",
            Voltage: "Voltage(V)",
            DesignCapacity: "Design capacity(mAh)",
            NominalChargeCapacity: "Nominal charge capacity(mAh)",
            InstantAmperage: "Instant amperage(mA)",
            CurrentCapacity: "Current capacity(%)",
            Temperature: "Temperature(°C)",
            CycleCount: "Cycle count",
            IsCharging: "Is charging",  
        },
        zh: { // html
            label: "中文",
            lang: "语言",
            suc: "成功",
            fail: "失败",
            setting: "设置",
            batinfo: "电池信息",
            update_freq: "更新频率",
            charge_below: "电量低于(%)开始充电",
            nocharge_above: "电量高于(%)停止充电",
            Serial: "序列号",
            BootVoltage: "开机电压(V)",
            Voltage: "当前电压(V)",
            DesignCapacity: "设计容量(mAh)",
            NominalChargeCapacity: "实际容量(mAh)",
            InstantAmperage: "电流(mA)",
            CurrentCapacity: "当前电量(%)",
            Temperature: "温度(°C)",
            CycleCount: "充电次数",
            IsCharging: "正在充电",
        }
    },
})

const App = {
    el: "#app",
    i18n,
    data: function () {
        return {
            title: "AlDentePro",
            loading: false,
            msg_list: [],
            bat_info: {},
            charge_below: 20,
            charge_above: 80,
            update_freq: 60,
            timer: null,
            marks: range(0, 110, 10).reduce((m, o)=>{m[o] = o + "%"; return m;}, {}),
            freqs: [
                {"label": "1 sec", "value": 1},
                {"label": "10 sec", "value": 10},
                {"label": "1 min", "value": 60},
                {"label": "10 min", "value": 600},
            ]
        }
    },
    methods: {
        block_ui: function (flag) {
            this.loading = flag;
        },
        get_bat_info_cb: function(jdata) {
            if (jdata.status == 0) {
                jdata.data.BootVoltage /= 1000;
                jdata.data.Voltage /= 1000;
                jdata.data.Temperature /= 100;
                this.bat_info = jdata.data;
            } else {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("fail") + ": " + jdata.status, 
                    "type": "error",
                    "time": 10000,
                });
            }
        },
        get_bat_info: function() {
            ipc_send({
                api: "get_bat_info",
                callback: "window.app.get_bat_info_cb",
            });
        },
        set_charge_status: function(v) {
            ipc_send({
                api: "set_charge_status",
                flag: v,
            });
            setTimeout(()=> {
                ipc_send({
                    api: "get_bat_info",
                    update: true,
                    callback: "window.app.get_bat_info_cb",
                });
            }, 1000);
        },
        set_charge_below: function(v) {
            ipc_send({
                api: "set_conf",
                key: "charge_below",
                val: v,
            });
        },
        set_charge_above: function(v) {
            ipc_send({
                api: "set_conf",
                key: "charge_above",
                val: v,
            });
        },
        change_update_freq: function(v) {
            ipc_send({
                api: "set_conf",
                key: "update_freq",
                val: v,
            });
            clearInterval(this.timer);
            this.timer = setInterval(this.get_bat_info, v * 1000);
        },
        get_conf_cb: function(jdata) {
            this.charge_below = jdata.data.charge_below;
            this.charge_above = jdata.data.charge_above;
            this.get_bat_info();
            this.timer = setInterval(this.get_bat_info, 60000);
        },
        get_conf: function() {
            ipc_send({
                api: "get_conf",
                callback: "window.app.get_conf_cb",
            });
        },
        change_lang: function(v) {
            set_local_val("conf", "lang", v);
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
                        //that.$delete(that.msg_list, index);
                        that.msg_list.splice(index, 1);
                    }
                }, time);
            }
        }
    },
    mounted: function () {
        this.get_conf()
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
})

if (location.port == 5500) {
    window.test = true;
}
