## 使用说明

MacOS系统上大名鼎鼎的AlDente，本人针对iOS重新开发，适用于长时间过冲情况下保护电池健康度。  

下载地址:(https://github.com/lich4/AlDente/releases)  
iOS<=14需要越狱+安装deb使用, 每次越狱时自动启动   
iOS>=15需要TrollStore+安装tipa使用    

通知:
&emsp;&emsp;现在iOS AlDente主要功能已经完成，假期过了以后本人比较忙，后面可能1-2月更新一次。
&emsp;&emsp;iOS AlDente原本是我计划花1天时间随意开发的项目，但是到现在为止各种功能也开发了一周了，作为一个完整App目前还没有图标及启动画面，所以启动过程是黑屏的。现向大家征集图标及启动画面素材，有兴趣的可以发起pull request或在issue中提交，注意不要提交侵权作品。一个月后我会从中选择一套点赞高的素材。

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
* 对于高型号(未知是X还是11开始)手动设置充电状态增加倒计时提醒
* 增加电池过热保护

注意:
* 由于是定时轮询因此更新频率影响精确度,1min的情况下差1-2%是正常的
* Mac上使用的温控接口可以进行更底层的温控和风扇速度控制,但iOS上并无此功能,因此本工具几乎是iOS上防过充唯一选择,其实这种工具十年前就应该出现了,只是一直没人研究
* 如果有兴趣参与本项目或者对本项目有建议的的欢迎参提交代码
* 测试过的环境 iPhone6/7+iOS12/13 Checkra1n越狱;iPhone7/X/11+iOS15/16 TrollStore

![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot.png)
![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot1.png)


## Instruction

This app is inspired by MacOS version AlDente, used to prevent iPhone/iPad long-time overcharge, which will cause damage to the battery, one can specify the max capacity to stop charging, and min capacity to start charging, and max temparature to stop charging. Once set, the daemon will monitor capacity in background.

Download URL: (https://github.com/lich4/AlDente/releases)      
iOS<=14 require Jailbreak and install the deb version    
iOS>=15 require TrollStore and install the tipa version    

Supported mode
* "Plug and charge", iDevice will start charging whenever adaptor plug in, and stop charging when capacity increase to max threshhold specified. Useful for individual.
* "Edge trigger", iDevice will stop charging when capacity increase to max threshhold specified, and start charging only when capacity drop to min threshhold specified. Useful for developer & studio.

Test on iPhone6/7+iOS12/13 with Checkra1n jailbreak, and iPhone7/X/11+iOS15/16 with TrollStore.   
If you have better ideas, please join the project and push your code


![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot_en.png)
![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot_en1.png)





