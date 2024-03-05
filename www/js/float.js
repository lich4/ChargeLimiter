const App = {
    el: "#app",
    data: function () {
        return {
            daemon_alive: false,
            enable: false,
            ver: "?",
            update_freq: 1,
            dark: false,
            timer: null,
            bat_info: null,
        }
    },
    methods: {
        get_temp_desc: function() {
            var centigrade = this.bat_info.Temperature / 100;
            var fahrenheit = t_c_to_f(centigrade);
            return centigrade.toFixed(0) + "°C/" + fahrenheit.toFixed(0) + "°F";
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
            this.update_freq = jdata.data.update_freq;
            this.get_bat_info();
            this.timer = setInterval(this.get_bat_info, this.update_freq * 1000);
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
        this.get_conf();
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
})

window.onload = () => {
    $("html").css("width", 80);
    $("html").css("height", 60);
}

