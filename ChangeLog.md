未来计划:
* 开机自动启动后台
* 支持设置省电效率(Powercuff)
* iOS12悬浮窗

todos:
* Start daemon on system reboot
* Change power efficiency(Powercuff)
* Floating window on iOS12

1.5版本更新日志:
* 支持禁流模式以兼容少数不支持停充的电池
* 对iPhone8及以上型号重新优化,支持智能停充,支持Smart模式
* 悬浮窗自动隐藏
* 增加电池历史数据统计
* 增加scheme和http接口,可和快捷方式搭配使用

1.5 ChangeLog:
* DisableInflow mode added
* Optimization for iPhone8+, SmartBattery, PredictiveInhibitCharge
* Floating window auto hide
* Battery history statistics
* Scheme and HTTP API added to support Shortcuts

1.4.1版本更新日志:
* 优化WebUI界面
* IPAD悬浮窗跟随朝向
* 增加黑夜模式

1.4.1 ChangeLog:
* Optimize the WebUI
* Floating window on iPad follow orientation
* Dark mode

1.4版本更新日志:
* 增加快速充电模式(飞行模式+降低屏幕亮度+低电量模式)
* 将启动服务改为启用,方便实时查看电池状态,不必真正关闭后台
* 增加悬浮窗便捷控制(可拖动改变位置,单击切换启用状态)
* 增加触发逻辑实现高于指定温度开始充电,仅限插电即充模式

1.4 ChangeLog:
* Speed up charging
* Floating window(draggable;tap to enable/disable)
* Start charging when temparature above specified value  

1.3版本更新日志:
* 解决开启"优化电池充电"导致本工具无效的问题
* 增加无根越狱支持
* 由于知识产权原因本项目名称从AlDente修改为ChargeLimiter
* 增加图标和启动画面

1.3 ChangeLog:
* Fix the invalid cause by "Optimized Battery Charging"
* Support rootless jailbreak 
* Project name changed from AlDente to ChargeLimiter due to intellectual property
* Icon and splash screen updated

1.2版本更新日志:
* 增加语言-繁体中文
* 增加插电即充模式,方便普通用户使用;边缘触发模式适合开发者和工作室使用
* 底层定时轮询机制改为内核设备事件通知,灵敏度得到提升
* 增加华氏温度

1.2 ChangeLog:
* Traditional chinese added
* "Plug and charge" mode added, this mode is for personal usage, and "Edge trigger" mode is suitable for studio
* Data update mechanism changed from timer driven to kernel-event driven
* Fahrenheit temperature supported

1.1版本更新日志:
* 本工具为边缘触发模式,即电量低于阈值充电,高于阈值停止,处于阈值中间则保持原状态,此时可手动设置充电开关.
* 由于系统原因,将最低更新频率设置到20s.更新频率影响控温精准度
* 修复某些显示问题,包括调整充电提醒频率,高型号页眉显示串位,增加显示电源信息.
* 对于8及以上的型号手动设置充电状态存在120秒延迟,增加倒计时提醒
* 增加电池过热保护

1.1 ChangeLog:
* The lowest(and default) update frequency is set to 20s, according to the kernel
* Fix several bugs, both UI and functions
* Countdown of 120s is added on model >= iPhone8
* Simple temperature control added

1.0版本更新日志:
* 由于几个iPhone6长期过充导致电池鼓包,本人开发这个项目,在2024/02/03一天内开发完成并上传github

1.0 ChangeLog:
* Some batteries of my iPhones were bulging due to long time overcharge, so I established this project, done coding in one day in 2024/02/03, and published to github

