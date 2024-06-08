function get_y_range(data, field, ratio, positive) {
    const lr = ratio[0];
    const hr = ratio[1];
    var minv = data[0][field];
    var maxv = data[0][field];
    if (positive == null) {
        positive = true;
    }
    data.forEach(x => {
        if (x[field] < minv) {
            minv = x[field];
        }
        if (x[field] > maxv) {
            maxv = x[field];
        }
    });
    var rg = maxv - minv;
    if (rg == 0) {
        rg = Math.floor(maxv * 0.1);
    }
    var min_ = minv - lr * rg;
    if (positive && min_ < 0) {
        min_ = 0;
    }
    var max_ = maxv + hr * rg;
    return [min_, max_];
}

function get_x_range(data, indx, movrg, rg) {
    var l = data.length;
    var r1 = l - indx * movrg;
    if (r1 <= 0) {
        return [];
    }
    var r0 = r1 - rg;
    if (r0 < 0) {
        r0 = 0;
    }
    return data.slice(r0, r1);
}

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
            DATA_SPAN: 0,
            DATA_MOVE_SPAN: 3,
            dark: get_local_val("conf", "dark", false),
            temp_mode: get_local_val("conf", "temp_mode", false),
            min5: [],
            min5_indx: 0,
            chart_min5: null,
            hour: [],
            hour_indx: 0,
            chart_hour: null,
            day: [],
            day_indx: 0,
            chart_day: null,
            month: [],
            month_indx: 0,
            chart_month: null,
        }
    },
    methods: {
        ret_main: function () {
            location.href = "index.html";
        },
        get_statistics_init_cb: function (jdata) {
            for (var k in jdata.data) {
                this[k] = jdata.data[k];
            }
            this.update_chart_min5();
            this.update_chart_hour();
            this.update_chart_day();
            this.update_chart_month();
        },
        get_all_statistics: function () {
            ipc_send({
                api: "get_statistics",
                conf: {
                    min5: {
                        n: 10000,
                        last_id: 0,
                    },
                    hour: {
                        n: 1000,
                        last_id: 0,
                    },
                    day: {
                        n: 1000,
                        last_id: 0,
                    },
                    month: {
                        n: 1000,
                        last_id: 0,
                    },
                },
                callback: "window.app.get_statistics_init_cb",
            });
        },
        get_last_id: function(data, unit) {
            if (!data || data.length == 0) {
                return 0;
            }
            var UpdateTime = data[data.length - 1].UpdateTime;
            return Math.floor(UpdateTime / unit);
        },
        get_statistics_inc_cb: function (jdata) {
            for (var k in jdata.data) {
                this[k] = this[k].concat(jdata.data[k]);
            }
            if (jdata.data.min5) {
                this.update_chart_min5();
            }
            if (jdata.data.hour) {
                this.update_chart_hour();
            }
            if (jdata.data.day) {
                this.update_chart_day();
            }
            if (jdata.data.month) {
                this.update_chart_month();
            }
        },
        get_min5_statistics: function () {
            ipc_send({
                api: "get_statistics",
                conf: {
                    min5: {
                        n: 100,
                        last_id: this.get_last_id(this.min5, 300),
                    }
                },
                callback: "window.app.get_statistics_inc_cb",
            });
        },
        get_hour_statistics: function () {
            ipc_send({
                api: "get_statistics",
                conf: {
                    hour: {
                        n: 100,
                        last_id: this.get_last_id(this.min5, 3600),
                    }
                },
                callback: "window.app.get_statistics_inc_cb",
            });
        },
        update_chart_min5: function (opt) {
            var that = this;
            var min5 = get_x_range(this.min5, this.min5_indx, this.DATA_MOVE_SPAN, this.DATA_SPAN);
            this.min5_icon_data = min5.map(row => [row.IsCharging, row.ExternalConnected]);
            if (!this.chart_min5) {
                this.chart_min5 = new Chart(document.getElementById("min5_chart").getContext('2d'), {
                    type: "bar",
                    data: {
                        datasets: [{
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#34c759",
                            label: this.$t("capacity"),
                        }, {
                            yAxisID: "Temperature",
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#f8801b",
                            label: this.$t("temperature"),
                        }, {
                            yAxisID: "InstantAmperage",
                            type: "line",
                            borderWidth: 2,
                            pointRadius: 1,
                            pointHitRadius: 20,
                            borderColor: "#4d7ffc",
                            backgroundColor: "#4d7ffc",
                            label: this.$t("amperage"),
                            hidden: true,
                        }, {
                            yAxisID: "Voltage",
                            type: "line",
                            borderWidth: 2,
                            pointRadius: 1,
                            pointHitRadius: 20,
                            borderColor: "#4d7f8c",
                            backgroundColor: "#4d7f8c",
                            label: this.$t("voltage"),
                            hidden: true,
                        }]
                    },
                    options: {
                        responsive: true,
                        events: ["click"],
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (context) {
                                        var label = context.formattedValue;
                                        if (context.datasetIndex == 0) {
                                            label = label + '%';
                                        } else if (context.datasetIndex == 1) {
                                            label = label + that.temp_unit;
                                        } else if (context.datasetIndex == 2) {
                                            label = label + 'mA';
                                        }
                                        return label;
                                    }
                                }
                            }
                        },
                        scales: {
                            y: {
                                position: "right",
                                type: "linear",
                                min: 0,
                                max: 100,
                                ticks: {
                                    callback: function (value) {
                                        return value + '%';
                                    }
                                }
                            },
                            Temperature: {
                                position: "left",
                                type: "linear",
                                min: that.temp_mode?30:0, // 0-32
                                max: that.temp_mode?140:60, // 60-140
                                ticks: {
                                    callback: function (value) {
                                        return value + that.temp_unit;
                                    }
                                }
                            },
                            InstantAmperage: {
                                position: "left",
                                type: "linear",
                                ticks: {
                                    callback: function (value) {
                                        return value + "mA";
                                    }
                                },
                                display: false,
                            },
                            Voltage: {
                                position: "left",
                                type: "linear",
                                ticks: {
                                    callback: function (value) {
                                        return value + "mV";
                                    }
                                },
                                display: false,
                            }
                        }
                    },
                    plugins: [{
                        afterDatasetDraw: function(chart) {
                            var ctx = chart.ctx;
                            ctx.save();
                            ctx.fillStyle = "darkgreen";
                            const meta = chart.getDatasetMeta(0);
                            meta.data.forEach((item, index) => {
                                var d = that.min5_icon_data[index];
                                if (d[0]) {
                                    ctx.font = '10px "FontAwesome"';
                                    ctx.fillText("\uF0E7", item.x - 3, item.base - 5);
                                }
                                if (d[1]) {
                                    ctx.font = '9px "FontAwesome"';
                                    ctx.fillText("\uF1E6", item.x - 3, item.base - 20);
                                }
                            });
                            ctx.restore();
                        },
                    }]
                });
                var x0;
                $("#min5_chart").on("touchstart", function (e) {
                    x0 = e.originalEvent.touches[0].clientX;
                });
                var last_id = 0;
                $("#min5_chart").on("touchmove", function (e) {
                    var ts = Date.now();
                    if (ts - last_id < 100) {
                        return;
                    }
                    last_id = ts;
                    var x1 = e.originalEvent.changedTouches[0].clientX;
                    if (x1 - x0 > 5) { // move left => show right
                        if (that.min5_indx < (that.min5.length - that.DATA_SPAN) / that.DATA_MOVE_SPAN) {
                            that.min5_indx++;
                            that.update_chart_min5("none");
                        }
                        x0 = x1;
                    } else if (x1 - x0 < -5) { // move right => show left
                        if (that.min5_indx > 0) {
                            that.min5_indx--;
                            that.update_chart_min5("none");
                        }
                        x0 = x1;
                    }
                });
            }
            this.chart_min5.data.datasets[0].data = min5.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.CurrentCapacity,
                }
            });
            this.chart_min5.data.datasets[1].data = min5.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": that.temp_mode?t_c_to_f(row.Temperature/100):row.Temperature/100,
                }
            });
            this.chart_min5.data.datasets[2].data = min5.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.InstantAmperage,
                }
            });
            this.chart_min5.data.datasets[3].data = min5.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.Voltage,
                }
            });
            this.chart_min5.update(opt);
        },
        update_chart_hour: function (opt) {
            var that = this;
            var hour = get_x_range(this.hour, this.hour_indx, this.DATA_MOVE_SPAN, this.DATA_SPAN);
            this.hour_icon_data = hour.map(row => [row.IsCharging, row.ExternalConnected]);
            if (!this.chart_hour) {
                this.chart_hour = new Chart(document.getElementById("hour_chart").getContext('2d'), {
                    type: "bar",
                    data: {
                        datasets: [{
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#34c759",
                            label: this.$t("capacity"),
                        }, {
                            yAxisID: "Temperature",
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#f8801b",
                            label: this.$t("temperature"),
                        }, {
                            yAxisID: "InstantAmperage",
                            type: "line",
                            borderWidth: 2,
                            pointRadius: 1,
                            pointHitRadius: 20,
                            borderColor: "#4d7ffc",
                            backgroundColor: "#4d7ffc",
                            label: this.$t("amperage"),
                            hidden: true,
                        }, {
                            yAxisID: "Voltage",
                            type: "line",
                            borderWidth: 2,
                            pointRadius: 1,
                            pointHitRadius: 20,
                            borderColor: "#4d7f8c",
                            backgroundColor: "#4d7f8c",
                            label: this.$t("voltage"),
                            hidden: true,
                        }]
                    },
                    options: {
                        responsive: true,
                        events: ["click"],
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (context) {
                                        var label = context.formattedValue;
                                        if (context.datasetIndex == 0) {
                                            label = label + '%';
                                        } else if (context.datasetIndex == 1) {
                                            label = label + that.temp_unit;
                                        } else if (context.datasetIndex == 2) {
                                            label = label + 'mA';
                                        }
                                        return label;
                                    }
                                }
                            }
                        },
                        scales: {
                            y: {
                                position: "right",
                                type: "linear",
                                min: 0,
                                max: 100,
                                ticks: {
                                    callback: function (value) {
                                        return value + '%';
                                    }
                                }
                            },
                            Temperature: {
                                position: "left",
                                type: "linear",
                                min: that.temp_mode?30:0, // 0-32
                                max: that.temp_mode?140:60, // 60-140
                                ticks: {
                                    callback: function (value) {
                                        return value + that.temp_unit;
                                    }
                                }
                            },
                            InstantAmperage: {
                                position: "left",
                                type: "linear",
                                ticks: {
                                    callback: function (value) {
                                        return value + "mA";
                                    }
                                },
                                display: false,
                            },
                            Voltage: {
                                position: "left",
                                type: "linear",
                                ticks: {
                                    callback: function (value) {
                                        return value + "mV";
                                    }
                                },
                                display: false,
                            }
                        }
                    },
                    plugins: [{
                        afterDatasetDraw: function(chart) {
                            var ctx = chart.ctx;
                            ctx.save();
                            ctx.fillStyle = "darkgreen";
                            const meta = chart.getDatasetMeta(0);
                            meta.data.forEach((item, index) => {
                                var d = that.hour_icon_data[index];
                                if (d[0]) {
                                    ctx.font = '10px "FontAwesome"';
                                    ctx.fillText("\uF0E7", item.x - 3, item.base - 5);
                                }
                                if (d[1]) {
                                    ctx.font = '9px "FontAwesome"';
                                    ctx.fillText("\uF1E6", item.x - 3, item.base - 20);
                                }
                            });
                            ctx.restore();
                        },
                    }]
                });
                var x0;
                $("#hour_chart").on("touchstart", function (e) {
                    x0 = e.originalEvent.touches[0].clientX;
                });
                var last_id = 0;
                $("#hour_chart").on("touchmove", function (e) {
                    var ts = Date.now();
                    if (ts - last_id < 100) {
                        return;
                    }
                    last_id = ts;
                    var x1 = e.originalEvent.changedTouches[0].clientX;
                    if (x1 - x0 > 5) { // move left => show right
                        if (that.hour_indx < (that.hour.length - that.DATA_SPAN) / that.DATA_MOVE_SPAN) {
                            that.hour_indx++;
                            that.update_chart_hour("none");
                        }
                        x0 = x1;
                    } else if (x1 - x0 < -5) { // move right => show left
                        if (that.hour_indx > 0) {
                            that.hour_indx--;
                            that.update_chart_hour("none");
                        }
                        x0 = x1;
                    }
                });
            }
            this.chart_hour.data.datasets[0].data = hour.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.CurrentCapacity,
                }
            });
            this.chart_hour.data.datasets[1].data = hour.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": that.temp_mode?t_c_to_f(row.Temperature/100):row.Temperature/100,
                }
            });
            this.chart_hour.data.datasets[2].data = hour.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.InstantAmperage,
                }
            });
            this.chart_hour.data.datasets[3].data = hour.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "Dhm"),
                    "y": row.Voltage,
                }
            });
            this.chart_hour.update(opt);
        },
        update_chart_day: function (opt) {
            var that = this;
            var day = get_x_range(this.day, this.day_indx, this.DATA_MOVE_SPAN, this.DATA_SPAN);
            var capacity_range = get_y_range(this.day, "NominalChargeCapacity", [1, 1]);
            var cycle_range = get_y_range(this.day, "CycleCount", [1, 1]);
            if (!this.chart_day) {
                this.chart_day = new Chart(document.getElementById("day_chart").getContext('2d'), {
                    type: "bar",
                    data: {
                        datasets: [{
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#34c759",
                            label: this.$t("nominalCapacity"),
                        }, {
                            yAxisID: "CycleCount",
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#cacaca",
                            label: this.$t("cycleCount"),
                        }]
                    },
                    options: {
                        responsive: true,
                        events: ["click"],
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (context) {
                                        var label = context.formattedValue;
                                        if (context.datasetIndex == 0) {
                                            label = label + 'mAh';
                                        } else if (context.datasetIndex == 1) {
                                        }
                                        return label;
                                    }
                                }
                            }
                        },
                        scales: {
                            y: {
                                position: "right",
                                type: "linear",
                                min: capacity_range[0],
                                max: capacity_range[1],
                                ticks: {
                                    callback: function (value) {
                                        return value.toFixed(0) + "mAh";
                                    }
                                }
                            },
                            CycleCount: {
                                position: "left",
                                min: cycle_range[0],
                                max: cycle_range[1],
                                type: "linear",
                            }
                        }
                    }
                });
                var x0;
                $("#day_chart").on("touchstart", function (e) {
                    x0 = e.originalEvent.touches[0].clientX;
                });
                var last_id = 0;
                $("#day_chart").on("touchmove", function (e) {
                    var ts = Date.now();
                    if (ts - last_id < 100) {
                        return;
                    }
                    last_id = ts;
                    var x1 = e.originalEvent.changedTouches[0].clientX;
                    if (x1 - x0 > 5) { // move left => show right
                        if (that.day_indx < (that.day.length - that.DATA_SPAN) / that.DATA_MOVE_SPAN) {
                            that.day_indx++;
                            that.update_chart_day("none");
                        }
                        x0 = x1;
                    } else if (x1 - x0 < -5) { // move right => show left
                        if (that.day_indx > 0) {
                            that.day_indx--;
                            that.update_chart_day("none");
                        }
                        x0 = x1;
                    }
                });
            }
            this.chart_day.data.datasets[0].data = day.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "YMD"),
                    "y": row.NominalChargeCapacity,
                }
            });
            this.chart_day.data.datasets[1].data = day.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "YMD"),
                    "y": row.CycleCount,
                }
            });
            this.chart_day.options.scales.y.min = capacity_range[0];
            this.chart_day.options.scales.y.max = capacity_range[1];
            this.chart_day.options.scales.CycleCount.min = cycle_range[0];
            this.chart_day.options.scales.CycleCount.max = cycle_range[1];
            this.chart_day.update(opt);
        },
        update_chart_month: function (opt) {
            var that = this;
            var month = get_x_range(this.month, this.month_indx, this.DATA_MOVE_SPAN, this.DATA_SPAN);
            var capacity_range = get_y_range(this.month, "NominalChargeCapacity", [1, 1]);
            var cycle_range = get_y_range(this.month, "CycleCount", [1, 1]);
            if (!this.chart_month) {
                this.chart_month = new Chart(document.getElementById("month_chart").getContext('2d'), {
                    type: "bar",
                    data: {
                        datasets: [{
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#34c759",
                            label: this.$t("nominalCapacity"),
                        }, {
                            yAxisID: "CycleCount",
                            barPercentage: 1,
                            categoryPercentage: 0.9,
                            backgroundColor: "#cacaca",
                            label: this.$t("cycleCount"),
                        }]
                    },
                    options: {
                        responsive: true,
                        events: ["click"],
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (context) {
                                        var label = context.formattedValue;
                                        if (context.datasetIndex == 0) {
                                            label = label + 'mAh';
                                        } else if (context.datasetIndex == 1) {
                                        }
                                        return label;
                                    }
                                }
                            }
                        },
                        scales: {
                            y: {
                                position: "right",
                                type: "linear",
                                min: capacity_range[0],
                                max: capacity_range[1],
                                ticks: {
                                    callback: function (value) {
                                        return value.toFixed(0) + "mAh";
                                    }
                                }
                            },
                            CycleCount: {
                                position: "left",
                                min: cycle_range[0],
                                max: cycle_range[1],
                                type: "linear",
                            }
                        }
                    }
                });
                var x0;
                $("#month_chart").on("touchstart", function (e) {
                    x0 = e.originalEvent.touches[0].clientX;
                });
                var last_id = 0;
                $("#month_chart").on("touchmove", function (e) {
                    var ts = Date.now();
                    if (ts - last_id < 100) {
                        return;
                    }
                    last_id = ts;
                    var x1 = e.originalEvent.changedTouches[0].clientX;
                    if (x1 - x0 > 5) { // move left => show right
                        if (that.month_indx < (that.month.length - that.DATA_SPAN) / that.DATA_MOVE_SPAN) {
                            that.month_indx++;
                            that.update_chart_hour("none");
                        }
                        x0 = x1;
                    } else if (x1 - x0 < -5) { // move right => show left
                        if (that.month_indx > 0) {
                            that.month_indx--;
                            that.update_chart_hour("none");
                        }
                        x0 = x1;
                    }
                });
            }
            this.chart_month.data.datasets[0].data = month.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "YMD"),
                    "y": row.NominalChargeCapacity,
                }
            });
            this.chart_month.data.datasets[1].data = month.map(row => {
                return {
                    "x": ts_to_date(row.UpdateTime, "YMD"),
                    "y": row.CycleCount,
                }
            });
            this.chart_month.options.scales.y.min = capacity_range[0];
            this.chart_month.options.scales.y.max = capacity_range[1];
            this.chart_month.options.scales.CycleCount.min = cycle_range[0];
            this.chart_month.options.scales.CycleCount.max = cycle_range[1];
            this.chart_month.update(opt);
        },
        switch_dark: function (flag) {
            if (flag) {
                $("body").attr("class", "night");
            } else {
                $("body").removeAttr("class", "night");
            }
        },
    },
    mounted: function () {
        var that = this;
        this.DATA_SPAN = Math.floor(window.innerWidth / 20);
        if (this.dark) {
            this.switch_dark(true);
        }
        if (this.temp_mode) {
            this.temp_unit = "°F";
        } else {
            this.temp_unit = "°C";
        }
        this.get_all_statistics();
        setInterval(this.get_min5_statistics, 300000); // min5
        setInterval(this.get_hour_statistics, 3600000); // hour
        window.addEventListener("orientationchange", function() {
            that.DATA_SPAN = Math.floor(window.innerWidth / 20);
            that.update_chart_min5();
            that.update_chart_hour();
            that.update_chart_day();
            that.update_chart_month();
        });
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
});

