## 使用说明

MacOS系统上大名鼎鼎的AlDente，本人针对iOS重新开发，适用于长时间过充情况下保护电池健康度。  

支持有根越狱(???-arm.deb)/无根越狱(???-arm64.deb )/TrollStore(???.tipa)      
(注意: TrollStore环境下安装新版之前请先卸载旧版)    
下载地址:(https://github.com/lich4/ChargeLimiter/releases)    
交流QQ群:669869453 

todo:
* 实现慢速充电(待测试可行性)
* iOS12悬浮窗
* 电池历史数据统计

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
* Mac上使用的电源管理接口可以进行更底层的温控和风扇速度控制,但iOS上并无此功能,因此本工具几乎是iOS上防过充唯一选择,其实这种工具十年前就应该出现了,只是一直没人研究
* 有研究表明电量在20%-80%之间,温度在10°C-35°C之间,对电池寿命影响最小.因此App上下阈值默认设定为20/80.如果自行调整还是建议在20-80之间.
* 系统状态栏的充电标志不一定代表在充电，实际充电状态可以在看爱思助手或者本app查看
* 系统自带电池优化会导致本app失效，v1.4版会自动关闭自带优化(但系统设置里不会显示)。如果不使用本app需在系统设置中手动重置电池优化开关(先关后开)
* 悬浮窗打不开的，请先卸载旧版再从官方渠道安装(iOS12及以下目前不支持悬浮窗)。退出app重进出现按钮不生效的同理。
* 如果手动控制充电开关不生效则说明你的电池硬件无法被本app支持，请放弃使用
* app不会连着线就自发充电，充电/停充都有触发条件，请仔细查看本页说明
* 本项目是开放式项目，如果有兴趣参与或者对本项目有建议的的欢迎参提交代码   

目前触发充电的条件：
* 电量低于设定的最小值
* 插电即充模式下在未插入电源情况下插入电源
* 插电即充模式下温度低于设定的最小值(版本1.4起支持)

目前触发停充的条件：
* 电量高于设定的最大值
* 温度高于设定的最大值


&emsp;&emsp;测试过的环境: iPhone6/7+iOS12/13 Checkra1n越狱;iPhone7/X/11+iOS15/16 TrollStore  

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_cn1.png)


## Instruction

This app is inspired by MacOS version AlDente, used to prevent iPhone/iPad long-time overcharge, which will cause damage to the battery, one can specify the max capacity to stop charging, and min capacity to start charging, and max temparature to stop charging. Once set, the daemon will monitor capacity in background.

Download URL: (https://github.com/lich4/ChargeLimiter/releases)      
iOS<=14 require Jailbreak and install the deb version    
iOS>=15 require TrollStore and install the tipa version(or use arm64.deb for Rootless Jailbreak)    

Supported mode
* "Plug and charge", iDevice will start charging whenever adaptor plug in, and stop charging when capacity increase to max threshhold specified. Useful for individual.
* "Edge trigger", iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified. Useful for developer & studio.

Test on iPhone6/7+iOS12/13 with Checkra1n jailbreak, and iPhone7/X/11+iOS15/16 with TrollStore.   
If you have better ideas, please join the project and push your code   

Telegram group:  ![](https://img.shields.io/static/v1?label=&message=https://t.me/+p0pwZCBDcH0zOGZl&color=red)    
https://t.me/+p0pwZCBDcH0zOGZl   



![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en0.png)
![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/screenshots/screenshots_en1.png)

## Special Thanks

* icon by elfulanopr



