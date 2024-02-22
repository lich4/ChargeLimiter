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

function t_c_to_f(v) {
    return 32 + 1.8 * v;
}

const App = {
    el: "#app",
    data: function () {
        return {
            daemon_alive: false,
            enable: false,
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
            this.timer = setInterval(this.get_bat_info, 1000);
        },
        get_conf: function() {
            ipc_send({
                api: "get_conf",
                callback: "window.app.get_conf_cb",
            });
        },
    },
    mounted: function () {  
        this.get_conf();
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
})

if (location.port >= 5500 && location.port <= 5510) {
    window.test = true;
    window.innerWidth = 100;
    window.innerHeight = 50;
}

window.onload = () => {
    $("html").css("width", window.innerWidth);
    $("html").css("height", window.innerHeight);
}

