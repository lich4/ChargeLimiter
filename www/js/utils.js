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

function get_local_val(path, key, defval) {
    var data = localStorage.getItem(path);
    if (!data) {
        return defval;
    }
    var val = JSON.parse(data)[key];
    return val?val:defval;
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

function ts_to_date(timestamp, unit) {
    if (!unit) {
        unit = "YMDhms";
    }
    var date = new Date(timestamp * 1000);
    var Y = date.getFullYear();
    var M = (date.getMonth() + 1 < 10 ? '0' + (date.getMonth() + 1) : date.getMonth() + 1);
    var D = (date.getDate() < 10)?'0' + date.getDate() : date.getDate();
    var h = (date.getHours() < 10)?'0' + date.getHours() : date.getHours();
    var m = (date.getMinutes() < 10)?'0' + date.getMinutes() : date.getMinutes();
    var s = (date.getSeconds() < 10)?'0' + date.getSeconds() : date.getSeconds();
    var result = "";
    if (unit.indexOf("Y") != -1) {
        result += Y;
    }
    if (unit.indexOf("M") != -1) {
        if (result.length != 0) {
            result += "-";
        }
        result += M;
    }
    if (unit.indexOf("D") != -1) {
        if (result.length != 0) {
            result += "-";
        }
        result += D;
    }
    if (unit.indexOf("h") != -1) {
        if (result.length != 0) {
            result += " ";
        }
        result += h;
    }
    if (unit.indexOf("m") != -1) {
        if (result.length != 0) {
            result += ":";
        }
        result += m;
    }
    if (unit.indexOf("s") != -1) {
        if (result.length != 0) {
            result += ":";
        }
        result += s;
    }
    return result;
}

function get_id() {
    return Date.now();
}

function t_c_to_f(v) {
    return 32 + 1.8 * v;
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

$.ajaxSetup({
    timeout: 1000,
    contentType: "application/json",
});

if (location.port >= 5500 && location.port <= 5510) {
    window.test = true;
}

