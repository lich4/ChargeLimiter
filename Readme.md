## 使用说明

MacOS系统上大名鼎鼎的AlDente，本人针对iOS重新开发，适用于长时间过冲情况下保护电池健康度。  

下载地址:(https://github.com/lich4/AlDente/releases)  
iOS<=14需要越狱+安装deb使用, 每次越狱时自动启动   
iOS>=15需要TrollStore+安装tipa使用    

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

![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot.png)
![](https://raw.githubusercontent.com/lich4/AlDente/main/snapshot1.png)
