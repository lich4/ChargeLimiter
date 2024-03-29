function get_field_range(data, field, ratio, positive) {
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
        rg = (maxv * 0.1).toFixed(0);
    }
    var min_ = minv - lr * rg;
    if (positive && min_ < 0) {
        min_ = 0;
    }
    var max_ = maxv + hr * rg;
    return [min_, max_];
}

const i18n = new VueI18n({
    locale: get_local_lang(),
    messages: {
        en: { // html
            Capacity: "Capacity(%)",
            NominalCapacity: "NominalCapacity(mAh)",
            Amperage: "Amperage(mA)",
            Temperature: "Temperature(°C)",
            CycleCount: "CycleCount",
            stat_hour: "Hourly Data",
            stat_day: "Daily Data",
            stat_month: "Monthly Data",
        },
        zh_CN: { // html
            Capacity: "电量(%)",
            NominalCapacity: "容量(mAh)",
            Amperage: "电流(mA)",
            Temperature: "温度(°C)",
            CycleCount: "充电次数",
            stat_hour: "小时数据",
            stat_day: "天数据",
            stat_month: "月数据",
        },
        zh_TW: { // html
            Capacity: "電量(%)",
            NominalCapacity: "容量(mAh)",
            Amperage: "電流(mA)",
            Temperature: "溫度(°C)",
            CycleCount: "充電次數",
            stat_hour: "小時數據",
            stat_day: "天數據",
            stat_month: "月數據",
        }
    },
})

const App = {
    el: "#app",
    i18n,
    data: function () {
        return {
            dark: get_local_val("conf", "dark", false),
            stat_hour: [],
            stat_day: [],
            stat_month: [],
        }
    },
    methods: {
        ret_main: function() {
            location.href = "index.html";
        },
        get_conf_cb: function(jdata) {
            this.stat_hour = jdata.data.stat_hour;
            this.stat_day = jdata.data.stat_day;
            this.stat_month = jdata.data.stat_month;
            this.init_chart();
        },
        get_conf: function() {
            ipc_send({
                api: "get_conf",
                callback: "window.app.get_conf_cb",
            });
        },
        init_chart: function() {
            var amperage_range = get_field_range(this.stat_hour, "InstantAmperage", [5,1], false);
            var stat_hour = this.stat_hour.slice(Math.max(this.stat_hour.length - 48, 0));
            new Chart(document.getElementById("hour_chart").getContext('2d'), {
                type: "bar",
                data: {
                    datasets: [{
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#34c759",
                        label: this.$t("Capacity"),
                        data: stat_hour.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "Dhm"),
                                "y": row.CurrentCapacity,
                            }
                        }),
                    }, {
                        yAxisID: "Temperature",
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#f8801b",
                        label: this.$t("Temperature"),
                        data: stat_hour.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "Dhm"),
                                "y": row.Temperature/100,
                            }
                        })
                    }, {
                        yAxisID: "InstantAmperage",
                        type: "line",
                        borderWidth: 2,
                        pointRadius: 1,
                        pointHitRadius: 4,
                        borderColor: "#4d7ffc",
                        backgroundColor: "#4d7ffc",
                        label: this.$t("Amperage"),
                        data: stat_hour.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "Dhm"),
                                "y": row.InstantAmperage,
                            }
                        })
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    var label = context.formattedValue;
                                    if (context.datasetIndex == 0) {
                                        label = label + '%';
                                    } else if (context.datasetIndex == 1) {
                                        label = label + '°C';
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
                            max: 120,
                            ticks: {
                                callback: function(value) {
                                    return value>100?"":value + '%';
                                }
                            }
                        },
                        Temperature: {
                            position: "left",
                            type: "linear",
                            min: 0,
                            max: 120,
                            ticks: {
                                callback: function(value) {
                                    return value>50?"":value + '°C';
                                }
                            }
                        },
                        InstantAmperage: {
                            display: false,
                            position: "left",
                            type: "linear",
                            min: amperage_range[0],
                            max: amperage_range[1],
                            ticks: {
                                callback: function(value) {
                                    return value+"mA";
                                }
                            }
                        }
                    }
                }
            });

            var capacity_range = get_field_range(this.stat_day, "NominalChargeCapacity", [1,1]);
            var cycle_range = get_field_range(this.stat_day, "CycleCount", [1,1]);
            stat_day = this.stat_day.slice(Math.max(this.stat_day.length - 60, 0));
            new Chart(document.getElementById("day_chart").getContext('2d'), {
                type: "bar",
                data: {
                    datasets: [{
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#34c759",
                        label: this.$t("NominalCapacity"),
                        data: stat_day.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "YMD"),
                                "y": row.NominalChargeCapacity,
                            }
                        }),
                    }, {
                        yAxisID: "CycleCount",
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#cacaca",
                        label: this.$t("CycleCount"),
                        data: stat_day.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "YMD"),
                                "y": row.CycleCount,
                            }
                        })
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        tooltip: {
                            callbacks: {
                                label: function(context) {
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
                                callback: function(value) {
                                    return value.toFixed(0)+"mAh";
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
            
            var capacity_range = get_field_range(this.stat_month, "NominalChargeCapacity", [1,1]);
            var cycle_range = get_field_range(this.stat_month, "CycleCount", [1,1]);
            stat_month = this.stat_month.slice(Math.max(this.stat_month.length - 60, 0));
            new Chart(document.getElementById("month_chart").getContext('2d'), {
                type: "bar",
                data: {
                    datasets: [{
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#34c759",
                        label: this.$t("NominalCapacity"),
                        data: stat_month.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "YM"),
                                "y": row.NominalChargeCapacity,
                            }
                        }),
                    }, {
                        yAxisID: "CycleCount",
                        barPercentage: 1,
                        categoryPercentage: 0.9,
                        backgroundColor: "#cacaca",
                        label: this.$t("CycleCount"),
                        data: stat_month.map(row => {
                            return {
                                "x": ts_to_date(row.UpdateTime, "YM"),
                                "y": row.CycleCount,
                            }
                        })
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        tooltip: {
                            callbacks: {
                                label: function(context) {
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
                                callback: function(value) {
                                    return value.toFixed(0)+"mAh";
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
        },
        switch_dark: function(flag) {
            if (flag) {
                $("body").attr("class", "night");
            } else {
                $("body").removeAttr("class", "night");
            }
        },
    },
    mounted: function () {  
        if (this.dark) {
            this.switch_dark(true);
        }
        this.get_conf();
    }
};

window.addEventListener("load", function () {
    window.app = new Vue(App);
})

