* [For English](#Introduction)

## 介绍

&emsp;&emsp;ChargeLimiter(CL)是针对iOS开发的AlDente替代工具,适用于长时间过充情况下保护电池健康度.  
&emsp;&emsp;支持有根越狱(???-arm.deb)/无根越狱(???-arm64.deb )/TrollStore(???.tipa),目前支持iOS12-16.6.(注意: TrollStore环境下安装新版之前请先卸载旧版)   
&emsp;&emsp;测试过的环境: iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.  
&emsp;&emsp;CL是开放式项目,如果有兴趣参与或者对CL有建议的的欢迎参提交代码.CL纯属偶然兴趣而开发,最开始是作者自己玩的,后来觉得其他人会需要才开源分享.CL承诺永久免费且无广告,但因为使用CL导致系统或硬件方面的影响(或认为会有影响的)作者不负任何责任,用户使用CL即为默认同意本条款.     

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/banner.jpg)

## 已知BUG

* 由于缺少开发环境和设备, CL可能不兼容iOS<=11.x, v1.4.1起无法完全兼容iOS17+.
* 悬浮窗暂不支持iOS<=12.x.
* DEB版本CL可能会由于某些tweak导致启动卡屏,这并非CL本身的bug,这些tweak注入到com.apple.UIKit,可以在此目录寻找:/Library/MobileSubstrate/DynamicLibraries(有根),或/var/jb/Library/MobileSubstrate/DynamicLibraries(无根).

## 常见问题

什么情况下需要用CL?
* 手机需要长期连电源
* 手机需要整夜充电
* 充电时希望控制温度

CL更费电吗?
* 大多数用户感觉并不明显,CL的服务并不耗电,如果感觉确实耗电可以尝试关闭界面App和悬浮窗,或将更新频率调低到1分钟.

CL支持第三方电池吗?
* CL支持正版电池也支持大部分第三方品牌电池

使用CL后能增加健康度吗？
* 个人认为健康度递减是自然过程,软件更不可能直接修复硬件.不过有些用户使用CL一个月后确实健康度涨了.
* 大部分使用者会明显延缓电池健康度下降速度.
* 个别用户在使用CL后出现健康度下降更快的情况,请立即停用并卸载.
* 停充状态下一直连电源的情况下(非禁流),正常情况下电池电流为0,健康度永久不掉.

为什么手机用一会不充电了?(小白经常遇到的问题)
* CL并非傻瓜式工具,如果开启了温控请根据实际情况调整温度上下限,否则到达上限会停止充电,下限又无法达到自然无法充电.
* CL的设计思路就是减少充电次数,因此不会连着usb就充电,充电/停充都有触发条件,请仔细查看本页说明.

CL可以不依赖越狱或巨魔类工具吗?
* CL需要用到私有API所以无法上架.
* CL需要用到特殊签名因此无法以常规IPA方式来安装.

夏天怎样降低电池温度?
* 使用CL的Powercuff功能减少硬件用电量,充电状态下会同时降低充电功率
* 充电状态下,使用低功率充电头充电
* 购买手机散热器

## 测试电池兼容性

&emsp;&emsp;在使用CL前需要测试电池兼容性,如果不支持请放弃使用
* 1.测试电池是否支持停充.在“正在充电”按钮开启的状态下,手动关闭之,若120秒内按钮有反应则电池支持停充,但如果停充后有较大持续电池电流(>=5mA)则无法支持停充(有些电池返回电池电流值有误,此时以实际电量变化为准).
* 2.测试电池是否支持智能停充.开启"高级-智能停充",其余同1.
* 3.测试电池是否支持禁流.在“电源已连接”按钮开启的状态下,手动关闭之,若120秒内按钮有反应则电池支持禁流,但如果禁流后有较大持续电流(>=5mA)则无法支持禁流(有些电池返回电池电流值有误,此时以实际电量变化为准).
* 若电池既不支持停充也不支持禁流则永远不被CL支持.
* 如果使用CL过程中,健康度以不正常的方式下降,请自行调整高级菜单中的选项或卸载CL.

品牌反馈(欢迎汇报数据给我):
* 反馈不支持停充的电池: 马拉松1例.
* 反馈不支持SmartBattery的电池(开启SmartBattery会掉健康度): 品胜1例.

## 使用前必看

* iPhone8+存在120秒设定充电状态延迟. iPad可能也存在.
* 停充模式不会更新系统状态栏的充电标志,实际充电状态可以在看爱思助手或者CL查看.禁流模式会改变系统状态栏的充电标志(iPhone8+), 禁流模式在"高级-停充时启用禁流"中设定
* 对于TrollStore环境,因任何原因导致的服务被杀(比如重启系统/重启用户空间/...),将导致CL失效.
* CL的设计思路就是减少充电次数,因此不会连着usb就自发充电,也不会无故自动恢复充电,充电/停充都有触发条件,请仔细查看本页说明.
* 系统自带电池优化会导致CL失效,CL会自动关闭自带优化(但系统设置里不会显示).如果不使用CL需在系统设置中手动重置电池优化开关(先关后开).不推荐在过新的设备上使用,因为iPhone15起自带电池优化已经很完善.

## 使用说明

### 启用

&emsp;&emsp;设置全局启用,关闭后CL将恢复充电状态,并处于观察者模式,只读取电池信息,不进行任何操作.

### 悬浮窗

* 用于实时查看状态,同时查看服务是否正常运行
* 可拖动到任意位置
* 点击可切换CL全局启用状态
* 若设置为自动隐藏,前台有其他App时自动隐藏

### 模式

&emsp;&emsp;插电即充模式适合随用随充的普通用户使用:
* 重新接入电源且满足充电条件时开始充电
* 电量低于设定值时开始充电(为禁流设计)
* 电量高于设定值时停止充电
* 温度低于设定值时开始充电
* 温度高于设定值时停止充电

&emsp;&emsp;边缘触发模式适合手机常年连电源的工作室使用:
* 电量低于设定值时开始充电
* 电量高于设定值时停止充电
* 温度高于设定值时停止充电

&emsp;&emsp;触发优先级从高到低: 
* 充电(电量极低)
* 停充(电量>温度)
* 充电(电量>温度>插电)

### 更新频率

* 更新频率用于设定CL界面App和悬浮窗的数据更新频率.
* CL的服务并不耗电,界面App和悬浮窗会消耗少量的电,绝大多数用户并无感知.如果实测耗电,可以调低频率.

### 阈值设定

* 有研究表明电量在20%-80%之间,温度在10°C-35°C之间,对电池寿命影响最小.因此CL阈值默认设定为20/80/10/35,长期过充/零电量充电/高温对电池会产生不良影响.    
* 温度阈值的设定,可根据"历史统计-小时数据"的温度数据设置合适的阈值.   
* 设定阈值和实际触发值不一定完全相同,例如设定80%上限结果到81%停充,大部分手机差距在0-1%,极少数3-5%,差异值与120秒延迟有关,与充电速度有关,也与电池质量有关.停充后如果存在微弱电流可能造成差值.

### 行为

&emsp;&emsp;用于控制触发充电和停充时的行为,目前仅支持系统通知,每次重装CL需要重选以生效.

### 高级

* SmartBattery和智能停充,绝大多数用户使用默认配置即可,非正版电池如果使用默认配置导致健康度异常下降,可以自定义以最大程度减缓健康度下降速度.
* 自动禁流,用于兼容不支持停充的电池.开启禁流后等同于消耗电池电量,此时电池损耗和正常使用一致.
* 高温模拟,Powercuff,温度越高,硬件(充电器/CPU/背光/无线通信)耗电越少,手机越卡顿,充电电流电压也越低.
* 峰值性能,用于控制低温和电量不足时的峰值性能,不建议修改.
* 自动限流,用于自身流控不好的电池,电流过大会导致电池温度过高,健康度下降.选择合适的高温模拟等级: 可在电量小于30%时充电,电量越低时充电电流越高,手动设置"高级-高温模拟-设置"(等级从"正常"到"重度",等级越高电流越小),每次设置后几秒内可以观察到电流变化,达到合适的电流值时,将该等级设置到"高级-自动限流-高温模拟"中.自动限流在充电时自动设置为指定高温模拟等级(高级-自动限流-高温模拟),停充时自动恢复到默认等级(高级-高温模拟-设置).

### 电池信息

* 健康度与爱思助手保持一致,若健康度超过100%则说明新电池相比该代手机发行时的原始电池容量有升级.CL健康度是根据最大实际容量计算的.
* 硬件电量若超过100%(或超过显示电量)可能是未校准或质量问题导致.
* 电流以"瞬时电流"为准,电池电流为正说明从充电器流入电池,电池电流为负说明电池为设备供电.使用CL且停充状态下电池电流一般为0,此时电流流经电池为设备供电,电池起到闭合电路作用(可以理解为导线),此时对电池的损耗应小于仅使用电池为设备供电.禁流状态下电池电流一般为负.

### 历史统计

&emsp;&emsp;统计图用于查看一段时间内的电池状态,左右滑动可时移,点击上方标签可显示或隐藏特定指标

* 五分钟数据图,详细展示每次充放电时的电量/温度/电流及充电状态
* 小时数据图,概览充放电时的电量/温度/电流变化及充电状态
* 天数据图,详细展示每天健康度变化
* 月数据图,概览每月健康度变化

### 快捷指令
(适用于某些巨魔用户存在服务被杀导致软件失效的情况):  
+新建快捷指令 - 添加操作 - 类别 - "网页" - "Safari浏览器" - "打开URL"(以下是URL内容,标题自己设置)
* cl:///                        打开CL
* cl:///exit                    打开CL,退出CL(仅拉起服务)
* cl:///charge/exit      打开CL,启用充电,退出CL
* cl:///nocharge/exit    打开CL,停用充电,退出CL  

注意: 
* iPhone8+存在至多120秒延迟
* 可以在个人自动化中的电量事件使用上述指令实现指定电量开始/停止充电,也可以和其他模式结合实现开机自启(比如打开某App时触发)

集成快捷指令(iOS16+): <https://www.icloud.com/shortcuts/2ec3aed94f414378918f3e082b7bf6b0>

### HTTP接口(可配合快捷指令)

* POST http://localhost:1230 {"api":"get_conf","key":"enable"} => {"status":0,"data":true}
* * enable 全局开关 
* * charge_below 电量最小值 
* * charge_above 电量最大值 
* * enable_temp 温控开关
* * charge_temp_above 温度最大值
* * charge_temp_below 温度最小值
* * acc_charge 加速充电开关
* * acc_charge_airmode 飞行模式
* * acc_charge_blue 蓝牙
* * acc_charge_bright 亮度
* * acc_charge_lpm LPM
* POST http://localhost:1230 {"api":"set_conf","key":"enable","val":true} => {"status":0}
* POST http://localhost:1230 {"api":"get_bat_info"} => {"status":0,"data":{"IsCharging":false,...}}
* * InstantAmperage 电流
* * Voltage 电压
* * AppleRawCurrentCapacity 原始电量
* * CurrentCapacity 系统电量
* * CycleCount 循环次数
* * DesignCapacity 设计容量
* * NominalChargeCapacity 实际容量
* * ExternalChargeCapable 电源已连接
* * IsCharging 正在充电
* * Temperature 温度
* * UpdateTime 内核数据缓存时间
* POST http://localhost:1230 {"api":"set_charge_status","flag":true} => {"status":0}
* POST http://localhost:1230 {"api":"set_inflow_status","flag":true} => {"status":0}

下载地址:(https://github.com/lich4/ChargeLimiter/releases)    
交流QQ群:754802907    

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn1.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn2.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn3.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn_stat0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn_stat1.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn_night.png)

### 编译

&emsp;&emsp;使用XCode/Theos编译, 需要Theos+MonkeyDev
* 使用XCode调试App, https://github.com/lich4/debugserver_azj
* 调试WebUI, https://github.com/lich4/inspectorplus
* TrollStore快速安装, https://github.com/lich4/TrollStoreRemoteHelper

## Introduction

ChargeLimiter(CL) is inspired by MacOS version AlDente, used to prevent iDevice from getting overcharged, which will cause damage to the battery.     

Support Rootful Jailbreak(???-arm.deb)/Rootless Jailbreak(???-arm64.deb)/TrollStore(???.ipa). Currently support iOS12-16.6.(Notice: For TrollStore, Please uninstall older version CL before installing a newer one)       

Tested on iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.      

This project is opensourced, any better ideas, submit code directly; any suggestions, submit to issue region. This software will be opensourced, free, without ads forever. Author is not responsible for any impact on iOS system or hardware caused by this software.    

## Known issues

* Due to the lack of devices to test with, CL may not supported on iOS<=11, and v1.4.1+ may not fully supported on iOS17+.
* Floating window is not supported on iOS<=12.
* For deb version, some tweaks will cause CL to stuck at SplashScreen, it's not a bug of CL itself. these tweaks, injected into com.apple.UIKit, can be found in /Library/MobileSubstrate/DynamicLibraries(rootful), and /var/jb/Library/MobileSubstrate/DynamicLibraries(rootless).

## FAQ

Why should I use CL?
* iDevice always connected to a power source
* iDevice always charged overnight
* Want to control the temperature during charging

Does CL consume more power?
* Insensitive for most users. App UI and float window may consume a little power if frequancy is 1sec. if you feel the capacity dropping fast, try to set the update frequency to 1min.

Does CL support 3rd party battery?
* CL support battery of most brands. 

Will the battery health percentage increase after using CL for a period of time?
* I don't think it's possible, especially for a software, but there are indeed some users have their battery health increased after using CL for a month.
* CL will slow down dropping speed of battery health for most users.
* Health percentage may fluctuate in certain range. There are indeed little users keep dropping health after using CL, please stop using CL in this case.
* Keep connecting to a power source and enable ChargeInhibit(without DisableInflow) as long as possible, the normal amperage should be 0mA, and the health of battery will never drop.

Why does my iPhone won't charge any more after using for a while(Most questions from freshman)?
* CL is not a fully-automatic tool, please set the threshhold carefully according to the actual temperature if temperature control is enabled, or CL will surely stop charging and won't re-charge any more.
* CL is designed to minimize the charging count, so it won't start charging or recover charging for connecting to a power source in "Plug and charge" mode, but will start charging for re-connecting to a power source.

Is it possible to install CL without Jailbreak or TrollStore(-like) environment?
* Private api is used in CL, so it is impossible to be published to Appstore.
* Special entitlements is used in CL, so it is impossible to be installed as common ipa files.

How to cool down the battery in summer?
* Lower power usage of iDevice hardware with "Powercuff" capability in CL, it will reduce the charging wattage in the same time. 
* Use a charger of lower Watt to charge.
* Use a heat dissipation or sth.

## Compatibility

Please test battery compatibility before using CL, stop and uninstall CL if unsupported
* 1.Check compatibility of ChargeInhibit.Disable charging by toggling the "Charging" button, any change within 120 seconds means ChargeInhibit is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* 2.Check compatibility of PredictiveChargingInhibit. Enable it from "Advanced-Predictive charging inhibit", then follow steps in '1'.
* 3.Check compatibility of DisableInflow. Disable inflow by toggling the "External connected" button when it is enabled, any change within 120 seconds means DisableInflow is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* The battery will never be supported by CL if neither ChargeInhibit nor DisableInflow is supported.
* If the health of battery keep dropping abnormally while using CL, please adjust the configuration in Advanced menu, or just uninstall CL.

## Notice

* For iPhone8+(equal or higher than), there is 120-seconds delay after setting the charging status , maybe the same for iPad.
* In ChargeInhibit mode, The lightning icon of system status bar will not be updated, and the actual charging status can be found in 3utools(and similar) or CL, while it will be updated in DisableInflow mode(iPhone8+), this mode is enabled in "Advanced-Control inflow".
* For TrollStore, if the daemon(of CL) get killed in any condition(such as system-reboot/userspace-reboot/...), CL will become invalid for not being able to restart daemon itself automatically.
* CL is designed to minimize the charging count, so it won't start charging or recover charging for connecting to a power source in "Plug and charge" mode, it will only start/stop charging under certain conditions as show behind.
* CL is not compatible with "Optimized Battery Charging" of Settings.app. sCL will disable it automatically(won't shown in Settings.app). Please re-enable in Settings.app after disabling CL if necessary. It's not recommend to use CL on newest iDevice,  "Optimized Battery Charging" is already perfect from iPhone15.

## Instruction

### "Enable" button

Enable or disable CL globally. CL will become an readonly observer if disabled, and shows battery information only.

### Floating window

* View battery information and daemon status in realtime
* Drag to move anywhere.
* Tap to enable or disable CL globally. same as "Enable" button.
* Hide itself when other Apps in foreground if "Auto hide" enabled.

### Mode

"Plug and charge" mode is for individual, charge and discharge at any time, triggers as follows:
* Start charging on replug the USB cable if condition meets.
* Start charging if curren capacity lower than specified value.
* Stop charging if curren capacity higher than specified value.
* Start charging if temperature lower than specified value.
* Stop charging if temperature higher than specified value.

"Edge trigger" mode is for developer & studio, with iDevice always connecting to an power source, triggers as follows:
* Start charging if curren capacity lower than specified value.
* Stop charging if curren capacity higher than specified value.
* Stop charging if temperature higher than specified value.

triggers precedence from high to low: 
* Start charging(Extremely low capacity) 
* Stop charging(Capacity > Temperature)
* Start charging(Capacity > Temperature > Plug in)

### Update frequency

* Update frequency is data updating speed of UI, both App UI and floating window.
* Lower frequency, more power maybe saved. Insensitive to most users with 1sec, it's up to you.

### The threshhold 

* Some studies shown that capacity between 20%-80%, and temperature is between 10°C-35°C, is better for battery. Therefore, the default threshold is set to 20/80/10/35. Long-time-overcharged/Out of power/High temperature will do harm to the battery.
* Please set temperature threshhold according to "History-Hourly Data".
* The real value stop on trigger is not necessarily equal to the target value, the differ is 0-1% in most situations, a little users got 3-5% , the differ has sth. to do with the "120 seconds delay", charging speed, and battery hardware itself. If weak amperage occurs after stopping charging, the differ maybe higher than 3%.

### Action

Action on trigger start/stop charging. Please reset it after reinstalling/updating CL.

### Advanced

* For "SmartBattery" and "Predictive charging inhibit", default configuration is for most users. Recombination them to find the best configuration for yourself.
* Auto inhibit inflow, DisableInflow mode is for batteries doesn't support ChargeInhibit mode, iDevice will start to consume power of battery after stopping charging if enabled.
* Thermal simulation, same as Powercuff, the higher temperature, the less power consumption of hardware(Charger/CPU/Backlight/Radio),  poorer performance, lower charging amperage and lower charging voltage.
* Peak Power, control peak power performance under low temperature or low capacity, Do not change it unless you know what you are doing.
* Auto limit inflow, apply thermal simulation against high temperature and health dropping of the batteries losing control of Amperage. You can find the fitful level in this way: Start charging when current capacity below 30%(the lower capacity, the higher amperage), try to select "Advanced-Thermal simulate" level(from "Norminal" to "Heavy", the higher level, the lower amperage), the amperage will change in a few seconds. When you catch the acceptable amperage value, set the level to "Advanced-Auto limit inflow-Thermal simulation". In this case, the thermal simulate level will be set to level specified in "Advanced-Auto limit inflow-Thermal simulation" automatically when CL start charging, and will be set to default level specified in "Advanced-Thermal simulate" when CL stop charging.

### Battery Information

* Health, calculated with NominalChargeCapacity, with value higher than 100% indicates the battery must have been replaced before, and with more capacity than battery shipped with this model first released.
* Hardware capacity with value higher than 100%, maybe indicate the battery is not calibrated or has been changed.
* InstantAmperage with positive value means the current flow into battery from the power source, negative means the current flow into iDevice from battery without any power source. InstantAmperage should be 0mA normally in ChargeInhibit mode, in this case the current will flow through battery and feed iDevice, it will cause less damage to battery than use battery to supply power directly. (*In fact, keep connecting to any power source and stop charging, the health may never drop*). InstantAmperage should be negative in DisableInflow mode.

### History

&emsp;&emsp;Show battery status for a period of time, slide horizontally to shift time, and click the legend to hide or show specific source.

* Five minute data, show battery status in detail for each charge or discharge cycle, including CurrentCapacity/Temperature/Amperage.
* Hourly data, show battery status for all charge or discharge cycles, including CurrentCapacity/Temperature/Amperage.
* Daily data, show battery health in detail for each day.
* Monthly data, show battery health for each month.

### For Shortcuts.app
New Shortcut - Add Action - Web - Safari - Open URLs    
* cl:///                         (open CL)
* cl:///exit                   (open CL, exit CL, launch daemon only)
* cl:///charge              (open CL, start charging)
* cl:///charge/exit       (open CL, start charging, exit CL)
* cl:///nocharge         (open CL, stop charging)
* cl:///nocharge/exit  (open CL, stop charging, exit CL)

Integrated shortcut(iOS16+): <https://www.icloud.com/shortcuts/2ec3aed94f414378918f3e082b7bf6b0>

### HTTP Interface
* POST http://localhost:1230 {"api":"get_conf","key":"enable"} => {"status":0,"data":true}
* POST http://localhost:1230 {"api":"set_conf","key":"enable","val":true} => {"status":0}
* POST http://localhost:1230 {"api":"get_bat_info"} => {"status":0,"data":{"IsCharging":false,...}}
* POST http://localhost:1230 {"api":"set_charge_status","flag":true} => {"status":0}
* POST http://localhost:1230 {"api":"set_inflow_status","flag":true} => {"status":0}

If you have better ideas, please join the project and push your code   
Download URL:(https://github.com/lich4/ChargeLimiter/releases)    
Telegram group:  ![](https://img.shields.io/static/v1?label=&message=https://t.me/chargelimiter&color=red)    
https://t.me/chargelimiter   

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en1.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en2.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en3.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en_stat0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en_stat1.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en_night.png)


### Compile

&emsp;&emsp;XCode+MonkeyDev or Theos
* Debug App with XCode, see https://github.com/lich4/debugserver_azj
* Debug WebUI, see https://github.com/lich4/inspectorplus
* Install on TrollStore, see https://github.com/lich4/TrollStoreRemoteHelper

## Special Thanks

* icon by elfulanopr
* zh_TW by olivertzeng
* dark mode by InnovatorPrime 

