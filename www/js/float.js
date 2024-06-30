const App = {
    el: "#app",
    data: function () {
        return {
            daemon_alive: false,
            enable: false,
            temp_mode: false,
            ver: "?",
            update_freq: 1,
            dark: false,
            timer: null,
            bat_info: null,
            phase: 0,
            phase_num: 2,
        }
    },
    methods: {
        get_temp_desc: function() {
            var centigrade = this.bat_info.Temperature / 100;
            if (this.temp_mode) {
                return t_c_to_f(centigrade).toFixed(1) + "°F";
            } else {
                return centigrade.toFixed(1) + "°C";
            }
        },
        invset_enable: function() {
            var v = !this.enable;
            this.enable = v;
            ipc_send({
                api: "set_conf",
                key: "enable",
                val: v,
            });
        },
        get_bat_info_cb: function(jdata) {
            if (jdata.status == 0) {
                this.bat_info = jdata.data;
            }
        },
        get_bat_info: function() {
            var that = this;
            ipc_send({
                api: "get_bat_info",
                callback: "window.app.get_bat_info_cb",
            }, status => {
                that.daemon_alive = status;
            });
        },
        get_conf_cb: function(jdata) {
            this.enable = jdata.data.enable;
            this.ver = jdata.data.ver;
            this.temp_mode = jdata.data.temp_mode;
            this.update_freq = jdata.data.update_freq;
            this.get_bat_info();
            this.timer = setInterval(this.get_bat_info, this.update_freq * 1000);
        },
        get_health: function(item) {
            console.log(item)
            return (item["NominalChargeCapacity"] / item["DesignCapacity"] * 100).toFixed(2);
        },
        get_conf: function() {
            ipc_send({
                api: "get_conf",
                callback: "window.app.get_conf_cb",
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
    },
    mounted: function () {  
        var that = this;
        this.get_conf();
        setInterval(() => {
            that.phase = (that.phase + 1) % that.phase_num;
        }, 10000);
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
})

window.onload = () => {
    $("html").css("width", 60);
    $("html").css("height", 45);
}

