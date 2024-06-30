* [For English](#Introduction)

## 介绍

&emsp;&emsp;ChargeLimiter(CL)是针对iOS开发的AlDente替代工具,适用于长时间过充情况下保护电池健康度.  
&emsp;&emsp;支持有根越狱(???-arm.deb)/无根越狱(???-arm64.deb )/巨魔(???.tipa),目前支持iOS12-17.0(注意: 巨魔环境下安装新版之前请先卸载旧版)
&emsp;&emsp;测试过的环境: iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.  
&emsp;&emsp;v1.4.1功能可以满足大多数用户需求，v1.5兼容不支持停充的电池，v1.6兼容充电电流过大的电池    
&emsp;&emsp;CL是开放式项目,如果有兴趣参与或者对CL有建议的的欢迎参提交代码.CL纯属偶然兴趣而开发,最开始是作者自己玩的,后来觉得其他人会需要才开源分享.CL承诺永久免费且无广告,但因为使用CL导致系统或硬件方面的影响(或认为会有影响的)作者不负任何责任,用户使用CL即为默认同意本条款.     

![](https://raw.githubusercontent.com/lich4/ChargeLimiter/main/banner.jpg)

## 已知BUG

* 由于缺少开发环境和设备, CL可能不兼容iOS<=11.x.
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

为什么手机无法停充或恢复充电?(小白经常遇到的问题)
* CL并非傻瓜式工具,如果开启了温控请根据实际情况调整温度上下限,否则到达上限会停止充电,下限又无法达到自然无法充电.
* CL的设计思路就是减少充电次数,因此不会连着usb就充电,充电/停充都有触发条件,请仔细查看本页说明.
* 电池由于健康度低,刚启动系统时可以使用CL,一段时间后CL再也无法控制充电/停充.此种情况无法使用CL. 请注意大部分低健康度的电池仍然可以正常使用CL. 
* 电池由于过热导致硬件停充功能失效,导致CL无法生效. 而电池冷却后硬件停充功能会恢复. 请注意大部分处于高温的的电池仍然可以正常使用CL. 
* 新电池未激活则有几率导致硬件停充失效.常见品牌激活方法见本页
* 如果是iPad,如果确定充电状态正常但电量不增加,且电源显示为pd charger,可以尝试重新插拔或更换质量较好的充电线和充电头,直到电源处显示usb brick

我的电池&小板硬件是否支持CL停充?
* 唯一测试方式就是在关闭全局开关的情况下手动控制(开或关)"正在充电"按钮,若120秒内不变(关或开),就是电池或小板存在问题而非软件BUG,以下将硬件无法支持简称"失控"
* 从近几个月反馈来看少数电池/小板可能因为包括但不限于以下几种原因导致失控: 温度升高(温度高时失控,温度恢复时又可控)/健康度低(一直失控,或系统开机后一段时间内可控,之后失控)/电池未激活(新买电池未做激活导致有概率失控)
* 以上失控问题由于是硬件层面有问题, 如果是因为不明原因或健康度低导致的失控, 不推荐使用CL及类似工具, 可以尝试更换电池/小板解决; 电池未激活的,确定电池品牌(非软件中显示)并从官方客服获取正确激活方法激活即可;如果因为温度失控的想办法控温即可.

CL(及类似功能的软件)可以不依赖越狱或巨魔类工具吗?
* CL需要用到私有API所以无法上架.
* CL需要用到特殊签名因此无法以常规IPA方式来安装, 也无法用自签方式使用.

夏天怎样降低电池温度?
* 使用CL的Powercuff功能减少硬件用电量,充电状态下会同时降低充电功率
* 充电状态下,使用低功率充电头充电
* 购买手机散热器

遇到问题时如何自行诊断?
* 可以参照5分钟图和日志(/var/root/aldente.log)。例如：发现5分钟图存在1小时以上的数据缺失，就可能是掉后台了。

如何找到耗电应用?
* 可以借助观察5分钟图或者Helium的实时电流数据，来检测开启某项系统功能或运行某App会增加多少电流。

## 测试电池兼容性

&emsp;&emsp;在使用CL前需要测试电池兼容性,如果不支持请放弃使用
* 1.测试电池是否支持停充.关闭CL全局开关,关闭"高级"中所有选项,在“正在充电”按钮开启的状态下,手动关闭之,若120秒内按钮有反应则电池支持停充,但如果停充后有较大持续电池电流(>=5mA)则无法支持停充(有些电池返回电池电流值有误,此时以实际电量变化为准).
* 2.测试电池是否支持智能停充.开启"高级-智能停充",其余同1.
* 3.测试电池是否支持禁流.关闭CL全局开关,在“电源已连接”按钮开启的状态下,手动关闭之,若120秒内按钮有反应则电池支持禁流,但如果禁流后有较大持续电流(>=5mA)则无法支持禁流(有些电池返回电池电流值有误,此时以实际电量变化为准).
* 注意: 有的电池因为老化而健康度过低,会出现刚重启系统时可以使用上述方式停充但过一段时间就再也无法停充,这种电池也无法被CL所兼容;有的电池在温度过高时因为硬件原因无法停充,温度正常后又能正常停充. 
* 若电池既不支持停充也不支持禁流则永远不被CL支持.
* 如果使用CL过程中,健康度以不正常的方式下降,请自行调整高级菜单中的选项或卸载CL.

## 品牌新电池激活

&emsp;&emsp;电池保养官方文档: <https://www.apple.com.cn/batteries/maximizing-performance/>。电池激活是指电池刚出厂后需要采取正确方式，排除虚电并激发电池中全部的锂离子活性。建议咨询电池卖家或电池厂商获取正确激活方式，否则可能导致CL无法正常工作，常见品牌已整理在此

* 诺希: 不管开始有多少电量 ，使用到手机关机，然后进行充电，充满之后再充半小时！循环5~8天（如已充电没关系，下次再重复以上步骤即可）建议使用小电流充电器（即5V1A充电器）进行激活，因为慢充可以确保把电池容量充满，所以效果更佳。快充中间损耗的容量会较大，对激活效果有一定影响
* Dseven: 用到10%左右再开始充电，不要用到关机，充到100再多充1-2小时，如此循环充电使用5-7次之后，就会完全激发电池里面的电量
* 德赛: 新电池先把电量耗完再去充满电，第二次用到10%左右再去充满电，循环5-10个周期
* 欣旺达: 前5次20%左右开始充，充满多冲半小时到一小时，以后随意
* ART: 新电池用到20%充电，然后充满
* ZASZ: 勿将电池用到自动关机，前5次充电电量低于15%时开始充电，充满后再充1小时。5次循环后电池待机时间达到正常状态
* 品胜: 新电池都带一些虚电，用到10%开始充电，不要用到关机，一次性充到100%，再多充1小时拔掉充电器，循环充电使用3-5次后会完全激发电池里面的电量，平时用最好充满，不要边充边玩
* 长和胜: 新电池大部分是虚电，循环6-10次才会耐用。电量10%以上就要充电，不要低于10%或自动关机才充电，这样可以防止虚电电量过低导致的无法开机
* 飞毛腿: 建议把原始电量用到10%以下之后再充满100%，然后用到10%以下后又充满100%，如此循环5~10次（大约一周），这样电池才被彻底激活哦(=^_^=)另外，新电池的原始电量不是真实电量的，新电芯还有一大片区域没开始存电呢，原始电量50%只是一小部分区域的50%，不是整个电芯的50%哦，所以新电池的原始电量用得快是正常的
* 中正: 前3-5次充电称为调整期，应充8小时以上，保证充分激活锂离子的活性。锂离子电池没有记忆效应，但有很强的惰性，应给予充分激活；充电前建议慢充充电，减少快充方式，无论慢充还是快充都不要超过12小时，否则电池很可能会因为长时间的供电产生巨大的电子流而烧坏电芯；有很多用户在充电时还把手机开着，在充电过程中，电池一面因为手机的使用而向外放电，又因电池的充电而向内供电，很可能使电压紊乱导致手机电路板发热，如果有来电时会产生回流电流，对手机内部的零件造成损坏；电池的寿命取决于反复充放电次数，锂电池大约可以充放电500次左右，之后电池的性能会大大减弱，应尽量避免把电池内余电全部放完再充电，否则随着充电次数的增加电池性能会慢慢减弱
* 曲赛德(超容): 新电池里面是虚电，因为静置的时间久锂电子不活跃，首次使用电池用到10%左右就要充电，充电时间满6小时，连续循环一周，就可以充分激活锂电子的活性，不建议边充边玩，不建议用到没电。

## 充电宝兼容性

&emsp;&emsp;CL可以和充电宝配合使用，停充模式下充电宝优先为手机供电，充电宝电量耗尽后再由手机电池供电，对长途旅行的用户更为有意义，充电宝的容量性价比也远高于手机电池。注意：
* 无线充电时，如果充电功率不够有可能消耗电池电量，所以如果手机自身耗电较大就不适合这种充电方式
* 大部分有线充电宝支持"休眠模式"，在电流低于某个阈值一段时间后，会自动关闭自身电源。这种模式下使用CL，充电宝可能在手机锁屏后由于电流过小导致充电宝自动关闭电源, 造成无CL无法正常工作
* 大部分有线充电宝支持"小电流模式"，双击或长按电源键后进入小电流模式，这种模式在低电流时不会自动关闭电源，这种模式下CL在手机锁屏后也可以正常工作。注意有的充电宝几小时后会自动退出小电流模式

## 使用前必看

* iPhone8+存在120秒设定充电状态延迟. iPad可能也存在.
* 停充模式不会更新系统状态栏的充电标志,实际充电状态可以在看爱思助手或者CL查看.禁流模式会改变系统状态栏的充电标志(iPhone8+), 禁流模式在"高级-停充时启用禁流"中设定。
* 对于巨魔环境,因任何原因导致的服务被杀(比如重启系统/重启用户空间/...),将导致CL失效.
* CL的设计思路就是减少充电次数,因此不会连着usb就自发充电,也不会无故自动恢复充电,充电/停充都有触发条件,请仔细查看本页说明.
* 系统自带电池优化会导致CL失效,CL会自动关闭自带优化(但系统设置里不会显示).如果不使用CL需在系统设置中手动重置电池优化开关(先关后开).
* 停充过久会导致小板统计有误和其他奇奇怪怪的问题, 建议一个月至少满充满放一次

## 使用说明

### 名词解释

* 停充: 禁止电流流入电池, 此时电池不充电也不放电, 电源直接为设备硬件供电. 用户应优先使用此模式
* 禁流: 禁止电流流入设备, 此时电池处于放电状态, 电池为设备硬件供电. 电池若不支持停充, 则应使用此模式
* 限流: 通过模拟高温的方式限制充电电流. 电池在充电时如果电流过大导致异常发热, 则应选择此模式

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

* 有研究表明电量在20%-80%之间,温度在10°C-35°C之间,对电池寿命影响最小.因此CL阈值默认设定为20/80/10/35,长期过充/电量耗尽/高温对电池会产生不良影响.    
* 温度阈值的设定,可根据"历史统计-小时数据"的温度数据设置合适的阈值.   
* 设定阈值和实际触发值不一定完全相同,例如设定80%上限结果到81%停充,大部分手机差距在0-1%,极少数3-5%,差异值与120秒延迟有关,与充电速度有关,也与电池质量有关.停充后如果存在微弱电流可能造成差值;另外健康度的突然变化也会影响电量;新电池未激活直接使用CL也会导致停充后有较大电流.
* 电量上限阈值的设定,如果是短期停充,此上限可以根据自己需要设置;如果是iPad长年连电停充,则此上限可以设置为最佳停充电量,最佳停充电确定方法如下:将电量充满,关闭所有耗电App和功能然后静置,让电量自然降低,等待一天后此电量就是最佳停充电量.

### 行为

&emsp;&emsp;用于控制触发充电和停充时的行为,目前仅支持系统通知,每次重装CL需要重选以生效.

### 高级

* SmartBattery和智能停充,绝大多数用户使用默认配置即可,非正版电池如果使用默认配置导致健康度异常下降,可以自定义以最大程度减缓健康度下降速度.
* 自动禁流,用于兼容不支持停充的电池.开启禁流后等同于消耗电池电量,此时电池损耗和正常使用一致.
* 高温模拟,Powercuff,温度越高,硬件(充电器/CPU/GPU/背光/WiFi/无线/扬声器等)耗电越少,手机越卡顿,充电电流电压也越低.注意系统本身会根据实际情况调节该项,如果要强制指定模式(不建议)请打开锁定开关.越狱环境下如果存在功能冲突的tweak则CL不生效.
* 峰值性能,用于控制低温和电量不足时的峰值性能,不建议修改.
* 自动限流,用于自身流控不好的电池,电流过大会导致电池温度过高,健康度下降.选择合适的高温模拟等级: 可在电量小于30%时充电,电量越低时充电电流越高,手动设置"高级-高温模拟-设置"(等级从"正常"到"重度",等级越高电流越小),每次设置后几秒内可以观察到电流变化,达到合适的电流值时,将该等级设置到"高级-自动限流-高温模拟"中.自动限流在充电时自动设置为指定高温模拟等级(高级-自动限流-高温模拟),停充时自动恢复到默认等级(高级-高温模拟-设置).

注意: 
* 有些电池可能无法使用高温模拟,以实测为准.
* 由于系统机制,高温模拟无法在锁屏状态下生效

### 电池信息

* 健康度,与爱思助手保持一致,CL健康度是根据最大实际容量计算的.通常新电池健康度都会超过100%,而系统设置显示的健康度不会超过100%,但设置里只显示100%,所以健康度100%到99%的过程较长.注意健康度在长期停充的状态下可能有突然大幅度下降和统计不准确的情况,此时禁用CL并正常充电几次即可恢复.
* 硬件电量,一般情况下和系统电量接近,如果差值过大则可能是未校准或质量问题导致.硬件电量比系统电量更准确,硬件电量可能会大于100%也可能为负值,硬件电量大于100%时为过充此时系统电量为100%,为负时为电池亏电,此时系统电量为0%.
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

* 例子:

```bash
curl http://localhost:1230 -d '{"api":"get_conf","key":"enable"}' -H "content-type:application/json"
=> {"status":0,"data":true}
```

* 全局参数

|键                                            |类型         |描述                                                                                        |
|----------------------------------|-----------|---------------------------------------------------------------------|
|enable                                     |布尔         |关闭后CL将处于观察者模式,只读取电池信息,不进行任何操作|
|floatwnd                                  |布尔         |开启悬浮窗                                                                              |
|floatwnd_auto                         |布尔         |悬浮窗自动隐藏                                                                       |
|mode                                       |字符串     |模式,charge_on_plug为插电即充,edge_trigger为边缘触发     |
|charge_below                         |整型         |电量最小值                                                                              |
|charge_above                         |整型         |电量最大值                                                                              |
|enable_temp                           |布尔         |温控开关                                                                                 |
|charge_temp_above               |整型         |温度最小值                                                                              |
|charge_temp_below               |整型         |温度最大值                                                                              |
|acc_charge                             |布尔         |加速充电开关                                                                          |
|acc_charge_airmode              |布尔         |飞行模式                                                                                 |
|acc_charge_wifi                      |布尔         |WiFi                                                                                        |
|acc_charge_blue                    |布尔         |蓝牙                                                                                        |
|acc_charge_bright                  |布尔         |亮度                                                                                       |
|acc_charge_lpm                     |布尔         |低电量模式                                                                             |
|action                                     |字符串      |触发行为,noti为系统通知                                                       |
|adv_prefer_smart                   |布尔         |开启SmartBattery                                                                  |
|adv_predictive_inhibit_charge|布尔         |开启智能停充                                                                        |
|adv_disable_inflow                 |布尔         |开启禁流                                                                               |
|adv_limit_inflow                     |布尔         |开启限流                                                                                |
|adv_limit_inflow_mode          |字符串      |限流模拟高温等级,off/nominal/light/moderate/heavy           |
|adv_def_thermal_mode         |字符串      |默认模拟高温等级,off/nominal/light/moderate/heavy           |
|adv_thermal_mode_lock        |布尔         |模拟高温等级锁定                                                                  |
|thermal_simulate_mode         |字符串     |实际温度模拟等级(只读)                                                         |
|ppm_simulate_mode             |字符串      |(实际)峰值性能等级                                                               |
|use_smart                              |布尔         |是否支持SmartBattery(只读)                                                 |

* 获取配置get_conf

|请求         |类型         |描述                                     |
|------------|-----------|--------------------------------|
|api            |字符串    |get_conf                               |
|key            |字符串    |全局参数,若不指定则返回所有配置|
|响应         |                |                                            |
|status       |整型        |0:成功                                  |
|data         |                |数据                                     |

* 更改配置set_conf

|请求         |类型         |描述                                     |
|------------|-----------|--------------------------------|
|api            |字符串    |set_conf                               |
|key            |字符串    |全局参数                              |
|val            |               |值                                         |
|响应         |                |                                            |
|status       |整型        |0:成功                                  |
|data         |                |数据                                     |

* 获取电池数据get_bat_info

|请求         |类型         |描述                                     |
|------------|-----------|--------------------------------|
|api            |字符串    |get_bat_info                         |
|响应         |                |                                            |
|status       |整型        |0:成功                                  |
|data         |                |数据                                     |

|键                                        |类型        |描述                                     |
|-------------------------------|-----------|--------------------------------|
|Amperage                           |整型        |电流(mA)                              |
|AppleRawCurrentCapacity |整型        |原始电量(mAh)                     |
|BatteryInstalled                   |布尔        |电池已安装(mV)                   |
|BootVoltage                        |整型        |启动电压(mV)                       |
|CurrentCapacity                 |整型        |电量(%)                                |
|CycleCount                        |整型        |循环数                                  |
|DesignCapacity                  |整型        |设计容量(mAh)                     |
|ExternalChargeCapable     |布尔        |电源可充电                           |
|ExternalConnected            |布尔        |电源已连接                           |
|InstantAmperage                |整型        |瞬时电流(mA)                       |
|IsCharging                          |布尔        |正在充电                              |
|NominalChargeCapacity    |整型        |实际容量(mAh)                     |
|Serial                                  |字符串     |序列号                                 |
|Temperature                       |整型        |温度(℃/100)                        |
|UpdateTime                       |整型        |更新时间                              |
|AdapterDetails.Voltage      |整型        |电压(mV)                              |
|AdapterDetails.Current      |整型        |电源电流(mA)                      |
|AdapterDetails.Description|整型        |电源描述                             |
|AdapterDetails.IsWireless  |整型        |是否无线(需结合电源描述)  |
|AdapterDetails.Manufacturer|整型     |电源厂商                             |
|AdapterDetails.Name         |整型        |电源名称                             |
|AdapterDetails.Voltage      |整型        |电源电压(mV)                      |
|AdapterDetails.Watts         |整型        |电源功率(W)                        |

* 设置停充set_charge_status

|请求         |类型         |描述                                    |
|------------|-----------|-------------------------------|
|api            |字符串    |set_charge_status               |
|flag          |布尔         |启用                                     |
|响应         |                |                                            |
|status       |整型        |0:成功                                  |

* 设置禁流set_inflow_status

|请求         |类型         |描述                                    |
|------------|-----------|-------------------------------|
|api            |字符串    |set_inflow_status                |
|flag          |布尔         |启用                                     |
|响应         |                |                                            |
|status       |整型        |0:成功                                  |


下载地址:(https://github.com/lich4/ChargeLimiter/releases)    
交流QQ群:669869453    

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

&emsp;&emsp;增加新语言: 修改`www/lang.json` `www/help_en.md`并提交到github或我这.

## 感谢

* Elfulanopr提供的图标
* Olivertzeng提供的繁体中文
* Nawaf提供的阿拉伯语
* InnovatorPrime提供的夜间模式
* Cast提供的快捷指令

## Introduction

ChargeLimiter(CL) is inspired by MacOS version AlDente, used to prevent iDevice from getting overcharged, which will cause damage to the battery.     

Support Rootful Jailbreak(???-arm.deb)/Rootless Jailbreak(???-arm64.deb)/TrollStore(???.tipa). Currently support iOS12-17.0(Notice: For TrollStore, Please uninstall older version CL before installing a newer one)       

Tested on iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.   

v1.4.1 is for most users; v1.5 is for batteries not support ChargeInhibit; v1.6 is for batteries with too large amperage during charging.    

This project is opensourced, any better ideas, submit code directly; any suggestions, submit to issue region. This software will be opensourced, free, without ads forever. Author is not responsible for any impact on iOS system or hardware caused by this software.    

## Known issues

* Due to the lack of devices to test with, CL may not supported on iOS<=11.
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
* Health percentage may fluctuate in certain range. There are indeed few users keep dropping health after using CL, please stop using CL in this case.
* Keep connecting to a power source and enable ChargeInhibit(without DisableInflow) as long as possible, the normal amperage should be 0mA, and the health of battery will never drop.

Why does my iDevice unable to charge or discharge(Most questions from freshman)?
* CL is not a fully-automatic tool, please set the threshhold carefully according to the actual temperature if temperature control is enabled, or CL will surely stop charging and won't re-charge any more.
* CL is designed to minimize the charging count, so it won't start charging or recover charging for connecting to a power source in "Plug and charge" mode, but will start charging for re-connecting to a power source.
* A battery with low health may cause the failure of ChargeInhibit/DisableInflow. In this case, ChargeInhibit/DisableInflow works fine after a system reboot, but would fail after tens of minutes. CL is unavailable for this kind of battery. Please notice there are only a few cases about the failure among all the batteries with low health.
* An overheated battery may cause the failure of ChargeInhibit. In this case, it will resume as normal as the battery get colder. Please notice there are only a few cases about the failure among all the batteries overheated.
* A new battery without activation may cause the amperage far higher than 5mA, which will break a perfect ChargeInhibit.
* For iPad, if the battery is charging normally without increasing capacity, and with the description of power source shown as "pd charger", then try to replug the cable or change the cable and charger with better ones, until it shown as "usb brick"

Is it possible to install CL without Jailbreak or TrollStore(-like) environment?
* Private api is used in CL, so it is impossible to be published to Appstore.
* Special entitlements is used in CL, so it is impossible to be installed as common ipa files.

How to cool down the battery in summer?
* Lower power usage of iDevice hardware with "Powercuff" capability in CL, it will reduce the charging wattage in the same time. 
* Use a charger of lower Watt to charge.
* Use a heat dissipation or sth.

How can I debug CL myself when sth. goes wrong?
* View the data in 5min chart and the log(/var/root/aldente.log) to verify the history data of charge/discharge.

How to find out power killer App with CL?
*  Open the App or enable some system feature, wait some time, and view the data in 5min chart or Amperage in Helium App to find out the killer.

## Compatibility

Please test battery compatibility before using CL, stop and uninstall CL if unsupported
* 1.Check compatibility of ChargeInhibit. Disable CL by toggling the "Enable" button first, and disable all options in "Advanced", then disable charging by toggling the "Charging" button, any change within 120 seconds means ChargeInhibit is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* 2.Check compatibility of PredictiveChargingInhibit. Enable it from "Advanced-Predictive charging inhibit", then follow steps in '1'.
* 3.Check compatibility of DisableInflow. Disable CL by toggling the "Enable" button first, then disable inflow by toggling the "External connected" button when it is enabled, any change within 120 seconds means DisableInflow is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* There are a few cases of battery with low health prevent CL from working well. In this case, CL can control charge/discharge normally after a system reboot, but will fail to control after tens of minutes. CL is unavailable for this kind of battery.
* The battery will never be supported by CL if neither ChargeInhibit nor DisableInflow is supported.
* If the health of battery keep dropping abnormally while using CL, please adjust the configuration in Advanced menu, or just uninstall CL.

## Battery activation

Official document: <https://www.apple.com.cn/batteries/maximizing-performance/>

## Compatibility with battery banks

CL can be used with a power bank. iDevice will be powered by the power bank in the first place in ChargeInhibit mode, and the battery of iDevice will supply power after the power bank run out of power. This is meaningful for users who plans to make a long journey, and power bank have more capacity and lower price than battery. Notice:
* If the wattage is insufficient in wireless charging, then battery may supply power simultaneously.  If the phone itself consumes a lot of power than the charger can supply, then it is not suitable to use a wireless charger.
* Most wired power banks support "sleep mode", in which the power bank will automatically turns off power after the current falls below a certain threshold for a period of time. When using CL in this mode, the power bank may turn off the power due to low amperage after the phone is locked, and CL will not able to re-charge any more due to power source disconnection in this case.
* Most wired power banks support "small current mode" by Double-click or long press the power button, in which the powwr bank will not automatically turn off the power when the current is low. CL will work perfect in this mode after the screen locked. Please notice that some power banks will automatically exit the "small current mode" after a few hours.

## Notice

* For iPhone8+(equal or higher than), there is 120-seconds delay after setting the charging status , maybe the same for iPad.
* In ChargeInhibit mode, The lightning icon of system status bar will not be updated, and the actual charging status can be found in 3utools(and similar) or CL, while it will be updated in DisableInflow mode(iPhone8+), this mode is enabled in "Advanced-Control inflow".
* For TrollStore, if the daemon(of CL) get killed in any condition(such as system-reboot/userspace-reboot/...), CL will become invalid for not being able to restart daemon itself automatically.
* CL is designed to minimize the charging count, so it won't start charging or recover charging for connecting to a power source in "Plug and charge" mode, it will only start/stop charging under certain conditions as show behind.
* CL is not compatible with "Optimized Battery Charging" of Settings.app. sCL will disable it automatically(won't shown in Settings.app). Please re-enable in Settings.app after disabling CL if necessary. It's not recommend to use CL on newest iDevice,  "Optimized Battery Charging" is already perfect from iPhone15.
* If the iDevice stay in ChargeInhibit mode for too long time, the hardware statistics may be incorrect. It's recommend to charge/discharge the battery once a month at least.

## Instruction

### Terms

* ChargeInhibit: Prohibit the current from flowing into battery. In this mode the battery will neither charge nor discharge, and the power source will power the hardware of iDevice directly. This mode should be should be preferred.
* DisableInflow: Prohibit the current from flowing into iDevice. In this mode the battery will discharge, and power the hardware of iDevice. This mode should be used only when ChargeInhibit is unsupported by the battery.
* LimitInflow: Limit the current and prevent iDevice from getting overheat. This mode should be used only when the battery clouldn't take control of the current.

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
* The real value stop on trigger is not necessarily equal to the target value, the differ is 0-1% in most situations, a few users got 3-5% , the differ has sth. to do with the "120 seconds delay", charging speed, and battery hardware itself. If weak amperage occurs after stopping charging, the differ maybe higher than 3%. besides, A suddenly change of the battery health may cause this situation; A new battery without activation may cause this situation.

### Action

Action on trigger start/stop charging. Please reset it after reinstalling/updating CL.

### Advanced

* For "SmartBattery" and "Predictive charging inhibit", default configuration is for most users. Recombination them to find the best configuration for yourself.
* Auto inhibit inflow, DisableInflow mode is for batteries doesn't support ChargeInhibit mode, iDevice will start to consume power of battery after stopping charging if enabled.
* Thermal simulation, same as Powercuff, the higher temperature, the less power consumption of hardware(Charger/CPU/GPU//Backlight/WiFi/Radio/Speaker/Arc/...),  poorer performance, lower charging amperage and lower charging voltage. iOS system itself will update the staus according to actual situation, if you want to force specified value(not recommended), please enable "Lock". CL will be invalid if confict with other tweak with similar functionality under Jailbreak environment.
* Peak Power, control peak power performance under low temperature or low capacity, Do not change it unless you know what you are doing.
* Auto limit inflow, apply thermal simulation against high temperature and health dropping of the batteries losing control of Amperage. You can find the fitful level in this way: Start charging when current capacity below 30%(the lower capacity, the higher amperage), try to select "Advanced-Thermal simulate" level(from "Norminal" to "Heavy", the higher level, the lower amperage), the amperage will change in a few seconds. When you catch the acceptable amperage value, set the level to "Advanced-Auto limit inflow-Thermal simulation". In this case, the thermal simulate level will be set to level specified in "Advanced-Auto limit inflow-Thermal simulation" automatically when CL start charging, and will be set to default level specified in "Advanced-Thermal simulate" when CL stop charging.

### Battery Information

* Health of battery is calculated with NominalChargeCapacity. In general the health of a new battery is higher than 100%, even though it shows always 100% in system status bar. Please be aware of that the health maybe drop largely suddenly due to long term ChargeInhibit, in this case use should disable CL temporarily and have the battery fully charged several times to recover the health.
* Hardware capacity is close to the system capacity and is more accurate in most cases, too much difference may indicate the battery is not calibrated or of poor quality. Hardware capacity chould be higher than 100%(100% in system status bar) if overcharged, and could be negative(0 in system status bar) if undercharged, 
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

* Example

```bash
curl http://localhost:1230 -d '{"api":"get_conf","key":"enable"}' -H "content-type:application/json"
=> {"status":0,"data":true}
```

* Global configuration fields

|key                                         |type         |description                                                                               |
|----------------------------------|-----------|---------------------------------------------------------------------|
|enable                                     |boolean         |CL will become an readonly observer if disabled, and shows battery information only|
|floatwnd                                  |boolean         |Floating window                                                                      |
|floatwnd_auto                         |boolean         |Floating window auto hide                                                      |
|mode                                       |string     |Mode,"charge_on_plug" or "edge_trigger"                             |
|charge_below                         |integer         |Capacity threshhold                                                                |
|charge_above                         |integer         |Capacity threshhold                                                               |
|enable_temp                           |boolean         |Temperature control                                                               |
|charge_temp_above               |integer         |Temperature threshhold                                                         |
|charge_temp_below               |integer         |Temperature threshhold                                                         |
|acc_charge                             |boolean         |Speedup charging                                                                 |
|acc_charge_airmode              |boolean         |Airplane mode                                                                       |
|acc_charge_wifi                      |boolean         |WiFi                                                                                       |
|acc_charge_blue                    |boolean         |Bluetooth                                                                               |
|acc_charge_bright                  |boolean         |Brightness                                                                             |
|acc_charge_lpm                     |boolean         |LPM                                                                                       |
|action                                     |string      |Action on trigger, "noti" to use system notification              |
|adv_prefer_smart                   |boolean         |Use SmartBattery                                                                  |
|adv_predictive_inhibit_charge|boolean         |Use predictive inhibit charge                                                |
|adv_disable_inflow                 |boolean         |Auto inhibit inflow                                                                 |
|adv_limit_inflow                     |boolean         |Auto limit inflow                                                                     |
|adv_limit_inflow_mode          |string      |Auto limit inflow with thermal simulation level,off/nominal/light/moderate/heavy|
|adv_def_thermal_mode         |string      |Default thermal simulation level,off/nominal/light/moderate/heavy|
|adv_thermal_mode_lock        |boolean         |Lock thermal simulation level                                               |
|thermal_simulate_mode         |string     |Actual  thermal simulation level(readonly)                            |
|ppm_simulate_mode             |string      |Actual Peak power performance level                                 |
|use_smart                              |boolean         |SmartBattery available(readonly)                                          |

* get_conf

|request     |type        |description                           |
|------------|-----------|--------------------------------|
|api            |string      |get_conf                               |
|key            |string     |return all conf if unspecified|
|response  |                |                                            |
|status       |integer    |0:success                            |
|data         |                |data                                     |

* set_conf

|request     |type        |description                           |
|------------|-----------|--------------------------------|
|api            |string    |set_conf                               |
|key            |string    |Global configuration fields  |
|val            |               |data                                     |
|response         |                |                                            |
|status       |integer        |0:success                        |
|data         |                |data                                   |

* get_bat_info

|request     |type        |description                           |
|------------|-----------|--------------------------------|
|api            |string    |get_bat_info                         |
|response         |                |                                            |
|status       |integer        |0:成功                                  |
|data         |                |数据                                     |

|key                                     |type         |description                           |
|-------------------------------|-----------|--------------------------------|
|Amperage                           |integer        |(mA)                                 |
|AppleRawCurrentCapacity |integer        |(mAh)                               |
|BatteryInstalled                   |boolean        |(mV)                               |
|BootVoltage                        |integer        |(mV)                                 |
|CurrentCapacity                 |integer        |(%)                                   |
|CycleCount                        |integer        |                                         |
|DesignCapacity                  |integer        |(mAh)                               |
|ExternalChargeCapable     |boolean        |                                      |
|ExternalConnected            |boolean        |                                      |
|InstantAmperage                |integer        |(mA)                                |
|IsCharging                          |boolean        |                                      |
|NominalChargeCapacity    |integer        |(mAh)                              |
|Serial                                  |string          |                                        |
|Temperature                       |integer        |(℃/100)                          |
|UpdateTime                       |integer        |                                        |
|AdapterDetails.Voltage      |integer        |(mV)                                |
|AdapterDetails.Current      |integer        |(mA)                               |
|AdapterDetails.Description|integer        |                                      |
|AdapterDetails.IsWireless  |integer        |                                      |
|AdapterDetails.Manufacturer|integer     |                                     |
|AdapterDetails.Name         |integer        |                                     |
|AdapterDetails.Voltage      |integer        |(mV)                               |
|AdapterDetails.Watts         |integer        |(W)                                 |

* set_charge_status

|request         |type         |description                                    |
|------------|-----------|-------------------------------|
|api            |string    |set_charge_status               |
|flag          |boolean         |enable                                     |
|response         |                |                                            |
|status       |integer        |0:success                                  |

* set_inflow_status

|request         |type         |description                                    |
|------------|-----------|-------------------------------|
|api            |string    |set_inflow_status                |
|flag          |boolean         |enable                                     |
|response         |                |                                            |
|status       |integer        |0:success                                  |

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

XCode+MonkeyDev or Theos
* Debug App with XCode, see https://github.com/lich4/debugserver_azj
* Debug WebUI, see https://github.com/lich4/inspectorplus
* Install on TrollStore, see https://github.com/lich4/TrollStoreRemoteHelper

Add new language: modify `www/lang.json` `www/help_en.md` and submit to github or to me.

## Special Thanks

* Icon from Elfulanopr
* Traditional Chinese language from Olivertzeng
* Arab language from Nawaf
* Dark mode from InnovatorPrime 
* Shortcut from Cast

