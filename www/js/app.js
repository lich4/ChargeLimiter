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
    "iPad6,7": "iPad Pro 12.9' 1st",
    "iPad6,8": "iPad Pro 12.9' 1st",
    "iPad6,11": "iPad 5th",
    "iPad6,12": "iPad 5th",
    "iPad7,1": "iPad Pro 12.9' 2nd",
    "iPad7,2": "iPad Pro 12.9' 2nd",
    "iPad7,3": "iPad Pro 10.5'",
    "iPad7,4": "iPad Pro 10.5'",
    "iPad7,5": "iPad 6th",
    "iPad7,6": "iPad 6th",
    "iPad7,11": "iPad 7th",
    "iPad7,12": "iPad 7th",
    "iPad8,1": "iPad Pro 11' 1st",
    "iPad8,2": "iPad Pro 11' 1st",
    "iPad8,3": "iPad Pro 11' 1st",
    "iPad8,4": "iPad Pro 11' 1st",
    "iPad8,5": "iPad Pro 12.9' 3rd",
    "iPad8,6": "iPad Pro 12.9' 3rd",
    "iPad8,7": "iPad Pro 12.9' 3rd",
    "iPad8,8": "iPad Pro 12.9' 3rd",
    "iPad8,9": "iPad Pro 11' 2nd",
    "iPad8,10": "iPad Pro 11' 2nd",
    "iPad8,11": "iPad Pro 12.9' 4th",
    "iPad8,12": "iPad Pro 12.9' 4th",
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
    "iPad13,4": "iPad Pro 11' 3rd",
    "iPad13,5": "iPad Pro 11' 3rd",
    "iPad13,6": "iPad Pro 11' 3rd",
    "iPad13,7": "iPad Pro 11' 3rd",
    "iPad13,8": "iPad Pro 12.9' 5th",
    "iPad13,9": "iPad Pro 12.9' 5th",
    "iPad13,10": "iPad Pro 12.9' 5th",
    "iPad13,11": "iPad Pro 12.9' 5th",
    "iPad13,16": "iPad Air 5th",
    "iPad13,17": "iPad Air 5th",
    "iPad13,18": "iPad 10th",
    "iPad13,19": "iPad 10th",
    "iPad14,1": "iPad mini 6th",
    "iPad14,2": "iPad mini 6th",
    "iPad14,3": "iPad Pro 11' 4th",
    "iPad14,4": "iPad Pro 11' 4th",
    "iPad14,5": "iPad Pro 12.9' 6th",
    "iPad14,6": "iPad Pro 12.9' 6th",
    "iPad14,8": "iPad Air 11' 6th",
    "iPad14,9": "iPad Air 11' 6th",
    "iPad14,10": "iPad Air 13' 6th",
    "iPad14,11": "iPad Air 13' 6th",
};

var lang_data = null;
$.ajax({
    url : "lang.json",
    type : "get",
    async: false,
    dataType: "json",
    success: function(res) {
        lang_data = res;
    }
});

const i18n = new VueI18n({
    locale: get_local_lang(),
    messages: lang_data,
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
            floatwnd_auto: false,
            mode: "charge_on_plug",
            msg_list: [],
            bat_info: {},
            adaptor_info: {},
            charge_below: 20,
            charge_above: 80,
            enable_temp: false,
            temp_mode: 0,
            temp_unit: null,
            charge_temp_above: 35,
            charge_temp_below: 20,
            temp_above_min: 20,
            temp_above_max: 50,
            temp_below_min: 10,
            temp_below_max: 40,
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
            adv_thermal_avail: true,
            adv_limit_inflow: false,
            adv_limit_inflow_mode: "",
            adv_def_thermal_mode: "",
            thermal_simulate_mode: "",
            ppm_simulate_mode: "",
            sys_boot: 0,
            serv_boot: 0,
            use_smart: false,
            count_msg: "",
            timer: null,
            freqs: null,
            modes: null,
            actions: null,
            cuffmods: null,
            show_tips: {
                setting: true,
                floatwnd_auto: false,
                lang: false,
                mode: false,
                update: false,
                acc: false,
                charge: false,
                inflow: false,
                cuff: false,
                ppm: false,
            },
            show_sliders: {
                lc: false,
                hc: false,
                lt: false,
                ht: false,
            },
            marks_perc: range(0, 110, 10).reduce((m, o)=>{m[o] = o + "%"; return m;}, {}),
            marks_temp: null,
            conf: null,
            errc: 0,
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
                    that.errc += 1;
                    var max_hint = (that.update_freq <= 1) ? 10 : 1;
                    if (that.errc > max_hint) {
                        that.msg_list.push({ // 避免切窗口错误
                            "id": get_id(), 
                            "title": that.$t("conn_daemon_error"), 
                            "type": "error",
                            "time": 3000,
                        });
                        that.errc = 0;
                    }
                } else {
                    that.errc = 0;
                }
                that.daemon_alive = status;
            });
        },
        wait_state_chage: function(obj, key, tmout, cb) {
            var that = this;
            if (this.h_) {
                this.msg_list.push({
                    "id": get_id(), 
                    "title": this.$t("wait"), 
                    "type": "error",
                    "time": 3000,
                });
                return;
            }
            that.h_msg = {
                "id": get_id(), 
                "title": that.$t("wait_update").format(tmout),
                "type": "info",
                "time": tmout * 1000,
            };
            var old_status = obj[key];
            that.h_ = setInterval(()=>{
                if (that.update_freq > 1) {
                    that.get_conf();
                    that.get_bat_info();
                }
                tmout -= 1;
                that.h_msg.title = that.$t("wait_update").format(tmout);
                if (tmout <= 0 || old_status != obj[key]) {
                    clearInterval(that.h_);
                    that.h_ = null;
                    var index = that.msg_list.findIndex(e => e.id == that.h_msg.id);
                    if (index > -1) {
                        that.msg_list.splice(index, 1);
                    }
                    if (cb) {
                        cb();
                    }
                }
            }, 1000);
            this.msg_list.push(that.h_msg);
        },
        wait_daemon_alive: function() {
            var that = this;
            this.daemon_alive = false;
            this.wait_state_chage(this, "daemon_alive", 10, function() {
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
            if (this.get_health(this.bat_info) < 81) {
                this.$confirm(this.$t("health_warn"), this.$t("warn"), {
                    confirmButtonText: this.$t("ok"),
                    cancelButtonText: this.$t("cancel"),
                    type: "warning"
                }).then(() => {
                    this.ipc_send_wrapper({
                        api: "set_conf",
                        key: "enable",
                        val: v,
                    });
                    this.enable = v;
                }).catch(() => {       
                });
            } else {
                this.ipc_send_wrapper({
                    api: "set_conf",
                    key: "enable",
                    val: v,
                });
                this.enable = v;
            }
        },
        set_floatwnd: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "floatwnd",
                val: v,
            });
            this.floatwnd = v;
        },
        set_floatwnd_auto: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "floatwnd_auto",
                val: v,
            });
            this.floatwnd_auto = v;
            if (this.floatwnd) {
                this.set_floatwnd(false);
            }
        },
        set_inflow_status: function(v) {
            this.ipc_send_wrapper({
                api: "set_inflow_status",
                flag: v,
            });
            if (window.test) {
                this.bat_info.ExternalConnected = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_charge_status_cb: function(jdata) {
            var status = jdata.status;
            if (window.test) {
                return;
            }
            if (status == 0) {
                if (this.bat_info.PostChargeWaitSeconds) {
                    var tmout = this.bat_info.PostChargeWaitSeconds;
                    this.wait_state_chage(this.bat_info, "IsCharging", tmout);
                }
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
            this.ipc_send_wrapper({
                api: "set_charge_status",
                callback: "window.app.set_charge_status_cb",
                flag: v,
            });
            if (window.test) {
                this.bat_info.IsCharging = v;
            }
        },
        set_charge_below: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_below",
                val: v,
            });
            if (window.test) {
                this.charge_below = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_charge_above: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_above",
                val: v,
            });
            if (window.test) {
                this.charge_above = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        change_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "mode",
                val: v,
            });
            if (window.test) {
                this.mode = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        change_action: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "action",
                val: v,
            });
            if (window.test) {
                this.action = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_use_smart: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_prefer_smart",
                val: v,
            });
            if (window.test) {
                this.use_smart = v;
            } else {
                this.wait_daemon_alive();
            }
        },
        set_predictive_inhibit_charge: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_predictive_inhibit_charge",
                val: v,
            });
            this.adv_predictive_inhibit_charge = v;
        },
        set_disable_inflow: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_disable_inflow",
                val: v,
            });
            this.adv_disable_inflow = v;
        },
        change_def_thermal_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_def_thermal_mode",
                val: v,
            });
            if (window.test) {
                this.adv_def_thermal_mode = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_thermal_mode_lock: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_thermal_mode_lock",
                val: v,
            });
            this.adv_thermal_mode_lock = v;
        },
        change_ppm_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "ppm_simulate_mode",
                val: v,
            });
            if (window.test) {
                this.ppm_simulate_mode = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_limit_inflow: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_limit_inflow",
                val: v,
            });
            this.adv_limit_inflow = v;
        },
        change_limit_inflow_mode: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "adv_limit_inflow_mode",
                val: v,
            });
            if (window.test) {
                this.adv_limit_inflow_mode = v;
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        reset_conf: function() {
            this.ipc_send_wrapper({
                api: "reset_conf",
            });
            if (window.test) {
                this.get_conf();
            } else {
                this.wait_daemon_alive();
            }
        },
        get_health: function(item) {
            return (item["NominalChargeCapacity"] / item["DesignCapacity"] * 100).toFixed(2);
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
            this.timer = setInterval(() => {
                that.get_bat_info();
                that.get_conf();
            }, v * 1000);
        },
        get_temp_desc: function() {
            var centigrade = this.bat_info.Temperature / 100;
            if (this.temp_mode == 0) {
                return centigrade.toFixed(1) + "°C";
            } else if (this.temp_mode == 1) {
                return t_c_to_f(centigrade).toFixed(1) + "°F";
            }
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
                val: v,
            });
            if (window.test) {
            } else {
                setTimeout(this.get_conf, 1000);
            }
        },
        set_charge_temp_below: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "charge_temp_below",
                val: v,
            });
            if (window.test) {
            } else {
                setTimeout(this.get_conf, 1000);
            }
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
        set_acc_charge_wifi: function(v) {
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "acc_charge_wifi",
                val: v,
            });
            this.acc_charge_wifi = v;
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
        open_safari: function() {
            location.href = "safari://";
        },
        copy_to_pb: function() {
            var copy_bat_info = Object.assign({}, this.bat_info);
            delete copy_bat_info["Serial"];
            var data = JSON.stringify({
                "Battery": copy_bat_info,
                "System": {
                    sysver: this.sysver,
                    devmodel: this.devmodel,
                },
                "Config": this.conf,
            }, null, 2);
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
        update_temp_unit: function(update_val) {
            if (this.temp_mode == 0) { // 华氏转摄氏
                this.temp_unit = "°C";
                this.temp_above_max = 50;
                this.temp_below_min = 10;
                this.temp_above_min = 20;
                if (update_val) {
                    this.charge_temp_above = Math.min(Math.floor(t_f_to_c(this.charge_temp_above)), this.temp_above_max);
                    this.charge_temp_below = Math.max(Math.floor(t_f_to_c(this.charge_temp_below)), this.temp_below_min);
                }
                this.temp_below_max = this.charge_temp_above - 1; // 40
                this.marks_temp = range(0, 60, 5).reduce((m, o)=>{m[o] = o + "°C"; return m;}, {});
            } else if (this.temp_mode == 1) { // 摄氏转华氏
                this.temp_unit = "°F";
                this.temp_above_max = 120; // 50-122
                this.temp_below_min = 50; // 10-50
                this.temp_above_min = 70; // 20-68
                if (update_val) {
                    this.charge_temp_above = Math.min(Math.floor(t_c_to_f(this.charge_temp_above)), this.temp_above_max);
                    this.charge_temp_below = Math.max(Math.floor(t_c_to_f(this.charge_temp_below)), this.temp_below_min);
                }
                this.temp_below_max = this.charge_temp_above - 1; // 40-104
                this.marks_temp = range(30, 140, 5).reduce((m, o)=>{m[o] = o + "°F"; return m;}, {});
            }
        },
        switch_temp_unit: function() {
            this.temp_mode = (this.temp_mode + 1) % 2;
            set_local_val("conf", "temp_mode", this.temp_mode);
            this.update_temp_unit(true);
            this.ipc_send_wrapper({
                api: "set_conf",
                key: "temp_mode",
                val: this.temp_mode,
                vals: [this.charge_temp_below, this.charge_temp_above],
            });
        },
        get_conf_cb: function(jdata) {
            if (this.show_sliders['lc'] || this.show_sliders['hc'] || this.show_sliders['lt'] || this.show_sliders['ht']) {
                return; // 正在编辑
            }
            var that = this;
            for (var k in jdata.data) {
                this[k] = jdata.data[k];
            }
            this.conf = jdata.data;
            if (this.lang && this.lang != get_local_lang()) {
                i18n.locale = this.lang;
                set_local_val("conf", "lang", this.lang);
                this.reload_locale();
            }
            if (this.old_temp_mode == null) {
                this.update_temp_unit(false);
                this.old_temp_mode = this.temp_mode;
                set_local_val("conf", "temp_mode", this.temp_mode);
            }
            if (this.timer == null) {
                this.get_bat_info();
                if (window.test) {
                } else {
                    this.timer = setInterval(() => {
                        that.get_bat_info();
                        that.get_conf();
                    }, this.update_freq * 1000);
                }
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

