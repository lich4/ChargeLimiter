* [For English](#Instruction)

## 使用说明

&emsp;&emsp;ChargeLimiter(CL)是针对iOS开发的AlDente替代工具，适用于长时间过充情况下保护电池健康度。  
&emsp;&emsp;支持有根越狱(???-arm.deb)/无根越狱(???-arm64.deb )/TrollStore(???.tipa)，目前支持iOS12-17。(注意: TrollStore环境下安装新版之前请先卸载旧版)   
&emsp;&emsp;测试过的环境: iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore。  

下载地址:(https://github.com/lich4/ChargeLimiter/releases)    
交流QQ群:669869453 

todo:
* 改变充电速度(待测试可行性)
* iOS12悬浮窗
* 电池历史数据统计
* 支持快捷方式

1.4.1版本更新日志:
* 优化WebUI界面
* IPAD悬浮窗跟随朝向
* 增加黑夜模式

1.4版本更新日志:
* 增加快速充电模式(飞行模式+降低屏幕亮度+低电量模式)
* 将启动服务改为启用,方便实时查看电池状态,不必真正关闭后台
* 增加悬浮窗便捷控制(可拖动改变位置,单击切换启用状态)
* 增加触发逻辑实现高于指定温度开始充电,仅限插电即充模式

1.3版本更新日志:
* 解决开启"优化电池充电"导致本工具无效的问题
* 增加无根越狱支持

1.2版本更新日志:
* 增加语言-繁体中文
* 增加插电即充模式,方便普通用户使用;边缘触发模式适合开发者和工作室使用
* 底层定时轮询机制改为内核设备事件通知,灵敏度得到提升
* 增加华氏温度

1.1版本更新日志:
* 本工具为边缘触发模式,即电量低于阈值充电,高于阈值停止,处于阈值中间则保持原状态,此时可手动设置充电开关.
* 由于系统原因,将最低更新频率设置到20s.更新频率影响控温精准度
* 修复某些显示问题,包括调整充电提醒频率,高型号页眉显示串位,增加显示电源信息.
* 对于8及以上的型号手动设置充电状态存在120秒延迟,增加倒计时提醒
* 增加电池过热保护

注意:
* 有研究表明电量在20%-80%之间,温度在10°C-35°C之间,对电池寿命影响最小.因此App上下阈值默认设定为20/80.过充/零电量充电/高温对电池会产生不良影响.
* *如果使用CL过程中，健康度以不正常的方式下降，请停止使用并卸载*
* 系统状态栏的充电标志不一定代表在充电，实际充电状态可以在看爱思助手或者本app查看
* 如果手动控制充电开关不生效则说明你的电池硬件无法被本app支持，请放弃使用(不支持的型号包括但不限于:马拉松,...)。如果用本app停充成功但仍然有电流(或微弱电流)则说明电池已经老化无法控电，非App可以控制
* 悬浮窗打不开的，请先卸载旧版再从官方渠道安装(iOS12及以下目前不支持悬浮窗)。退出app重进出现按钮不生效的同理。
* 对于TrollStore环境，因任何原因导致的后台被杀(比如重启系统/重启用户空间/...)，由于后台无法自动启动所以App会失效。整夜充电发现充满请注意
* App不会连着线就自发充电，充电/停充都有触发条件，请仔细查看本页说明
* 设定阈值和实际触发值不一定完全相同，例如设定80%上限结果到81%停充，大部分手机差距在0-1%，极少数3-5%，产生5%差异值具体原因未知，与8系及以上存在设定延迟有关，也可能与充电速度有关。
* App健康度与爱思助手保持一致，若健康度超过100%则说明新电池相比该代手机发行时的原始电池容量有升级。
* 硬件电量若超过100%(或超过显示电量)可能是未校准或质量问题导致。
* 电流为正说明从充电器流入电池，电流为负说明电池为设备供电。使用本软件且停充状态下一般电流为0，此时电流流经电池为设备供电，电池起到闭合电路作用(可以理解为导线)，此时对电池的损耗应小于仅使用电池为设备供电。(*其实长期连电并停充，健康度可能永远不会掉*)。
* 系统自带电池优化会导致本app失效，1.3版本起会自动关闭自带优化(但系统设置里不会显示)。如果不使用本app需在系统设置中手动重置电池优化开关(先关后开)。不推荐在过新的设备上使用，因为iPhone15起自带电池优化已经很完善。
* 本项目是开放式项目，如果有兴趣参与或者对本项目有建议的的欢迎参提交代码  
* 本软件纯属偶然兴趣而开发，最开始是作者自己玩的，后来觉得其他人会需要才开源分享。本软件承诺永久免费且无广告，但因为使用本软件导致系统或硬件方面的影响(或认为会有影响的)作者不负任何责任，用户使用本App即为默认同意本条款。     

目前触发充电的条件：
* 电量低于设定的最小值
* 插电即充模式下在未插入电源情况下插入电源
* 插电即充模式下温度低于设定的最小值(版本1.4起支持)

目前触发停充的条件：
* 电量高于设定的最大值
* 温度高于设定的最大值

快捷指令(适用于某些巨魔用户存在后台被杀导致软件失效的情况):
+新建快捷指令 - 添加操作 - 类别 - "网页" - "Safari浏览器" - "打开URL"(以下是URL内容,标题自己设置)
* cl:///                 打开CL
* cl:///exit             打开CL,退出CL(仅拉起后台)
* cl:///charge           打开CL,启用充电
* cl:///charge/exit      打开CL,启用充电,退出CL
* cl:///nocharge         打开CL,停用充电
* cl:///nocharge/exit    打开CL,停用充电,退出CL  

注意: 
* iPhone8及以上存在至多120秒延迟
* 可以在个人自动化中的电量事件使用上述指令实现指定电量开始/停止充电，也可以和其他模式结合实现开机自启(比如打开某App时触发)

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn1.png)

### 编译

&emsp;&emsp;使用XCode/Theos编译, 需要Theos+MonkeyDev
* 使用XCode调试App, https://github.com/lich4/debugserver_azj
* 调试WebUI, https://github.com/lich4/inspectorplus
* TrollStore快速安装, https://github.com/lich4/TrollStoreRemoteHelper

## Instruction

ChargeLimiter(CL) is inspired by MacOS version AlDente, used to prevent iPhone/iPad long-time overcharged, which will cause damage to the battery.     
    
Support Rootful Jailbreak(???-arm.deb)/Rootless Jailbreak(???-arm64.deb)/TrollStore(???.ipa). Currently support iOS12-17.(Notice: For TrollStore, Please uninstall older version ChargeLimiter before installing a newer one)       
      
Tested on iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.     

If you have better ideas, please join the project and push your code   
Download URL:(https://github.com/lich4/ChargeLimiter/releases)    
Telegram group:  ![](https://img.shields.io/static/v1?label=&message=https://t.me/+p0pwZCBDcH0zOGZl&color=red)    
https://t.me/+p0pwZCBDcH0zOGZl   

todo:
* Change charging speed(to be validated)
* Floating window on iOS12
* Battery history data statistics
* Support shortcuts

1.4.1 ChangeLog:
* Optimize the WebUI
* Floating window on iPad follow orientation
* Dark mode

1.4 ChangeLog:
* Speed up charging
* Floating window(draggable;tap to enable/disable)
* Start charging when temparature above specified value  

Notice:
* Some Studies shown that capacity between 20%-80%, and temperature is between 10°C-35°C, is better for battery. Therefore, the default threshold is set to 20/80.
* The lightning icon of system status bar not necessarily means charging. The actual charging status can be found in 3utools(and similar) or CL.
* *If the health of battery keep dropping abnormally while using CL, please stop and uninstall CL*
* You can check the compatibility of battery with CL by manually toggling the "Charging" button, if charging status does not change within 120 seconds, then your iDevice is not supported by CL; normally it does. The "InstantAmperage" is 0mA normally after setting the status to false, a sign of ageing of battery if not zero(but very small value); if the mA is high enough, then CL could not help you either(lose control of current).
* For TrollStore, if the daemon(of CL) get killed in any condition(such as system-reboot/userspace-reboot/...), CL will become invalid for it cannot restart daemon itself automatically.
* CL only start/stop charging under certain condition as show behind.
* The real value stop on trigger is not necessarily equal to the target value, the difference may have sth. to do with the "120 seconds delay" after iPhone8, and charging speed.
* Health with value higher than 100% indicates the battery must have been replaced before, and with more capacity than battery shipped with this model first released.
* Hardware capacity with value higher than 100%, maybe indicate the battery is not calibrated or has been changed.
* InstantAmperage with positive value means current flow into battery from adaptor, negative means current flow into iDevice from battery without any adaptor. If CL is enabled and charging status set to disable, then InstantAmperage should be 0mA normally, in this case current will flow through battery and feed iDevice, it will cause less damage to battery than use battery to supply power directly. (*In fact, keep connecting to adaptor and stop charging, the heath may never drop*).
* CL is not compatible with "Optimized Battery Charging" of Settings.app. After v1.4 CL will disable it automatically(won't shown in Settings.app). Please re-enable in Settings.app after disabling CL if necessary. It's not recommend to use CL on newest iDevice,  "Optimized Battery Charging" is already perfect from iPhone15。
* This project is opensourced, any better ideas, submit code directly; any suggestions, submit to issue region. This software will be opensourced, free, without ads forever. Author is not responsible for any impact on iOS system or hardware caused by this software.

Supported mode
* "Plug and charge", iDevice will start charging whenever adaptor plug in, and stop charging when capacity increase to max threshhold specified. Useful for individual.
* "Edge trigger", iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified. Useful for developer & studio.

Conditions may trigger starting charging:
* Capacity lower than specified value
* Plug in adaptor once!!! in "Plug and charge" mode.
* Temparature lower than specified value

Conditions may trigger stoping charging:
* Capacity higher than specified value
* Temparature higher than specified value

For Shortcuts.app:   
New Shortcut - Add Action - Web - Safari - Open URLs   
* cl:///                         (open CL)
* cl:///exit                   (open CL, exit CL, launch daemon only)
* cl:///charge              (open CL, start charging)
* cl:///charge/exit       (open CL, start charging, exit CL)
* cl:///nocharge         (open CL, stop charging)
* cl:///nocharge/exit  (open CL, stop charging, exit CL)

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en1.png)


### Compile

&emsp;&emsp;XCode+MonkeyDev or Theos
* Debug App with XCode, see https://github.com/lich4/debugserver_azj
* Debug WebUI, see https://github.com/lich4/inspectorplus
* Install on TrollStore, see https://github.com/lich4/TrollStoreRemoteHelper

## Special Thanks

* icon by elfulanopr



