## ChargeLimiter

ChargeLimiter(CL) is inspired by MacOS version AlDente, used to prevent iDevice from getting overcharged, which will cause damage to the battery.     

Support Rootful Jailbreak(???-arm.deb)/Rootless Jailbreak(???-arm64.deb)/TrollStore(???.tipa). Currently support iOS12-17.0(Notice: For TrollStore, Please uninstall older version CL before installing a newer one)       

Tested on iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.   

v1.4.1 is for most users; v1.5 is for batteries not support ChargeInhibit; v1.6 is for batteries with too large amperage during charging.    

This project is opensourced, any better ideas, submit code directly; any suggestions, submit to issue region. This software will be opensourced, free, without ads forever. Author is not responsible for any impact on iOS system or hardware caused by this software.    

## Known issues

* Due to the lack of devices to test with, CL may not supported on iOS<=11.
* Floating window is not supported on iOS<=12.
* For deb version, some tweaks will cause CL to stuck at SplashScreen, it's not a bug of CL itself. these tweaks, injected into com.apple.UIKit, can be found in /Library/MobileSubstrate/DynamicLibraries(rootful), and /var/jb/Library/MobileSubstrate/DynamicLibraries(rootless).
* Due to the limitation of system, thermal simulation will be unavailable when the screen locked.

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
* CL is not a fully-automatic tool, please set the threshold carefully according to the actual temperature if temperature control is enabled, or CL will surely stop charging and won't re-charge any more.
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

What is the best way to keep the battery healthy?
* Refer to <https://www.apple.com.cn/batteries/maximizing-performance/>
* Avoid use in extremely high or low temperature
* Avoid long time overcharged
* Avoid out of power

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

CL can be used together with a power bank. iDevice will be powered by the power bank in the first place in ChargeInhibit mode, and the battery of iDevice will supply power after the power bank running out of power. This is meaningful for users who plans to make a long journey, and power bank have more capacity and lower price than battery. Notice:
* If the wattage is insufficient in wireless charging, then battery may supply power simultaneously.  If the phone itself consumes a lot of power than the charger can supply, then it is not suitable to use a wireless charger.
* Most wired power banks support "sleep mode", in which the power bank will automatically turns off power after the current falls below a certain threshold for a period of time. When using CL in this mode, the power bank may turn off the power due to low amperage after the phone is locked, and CL will not able to re-charge any more due to power source disconnection in this case.
* Most wired power banks support "small current mode" by Double-click or long press the power button, in which the power bank will not automatically turn off the power when the current is low. CL will work perfect in this mode after the screen locked. Please notice that some power banks will automatically exit the "small current mode" after a few hours.

## Notice

* For iPhone8+(equal or higher than), there is 120-seconds delay after setting the charging status , maybe the same for iPad.
* In ChargeInhibit mode, The lightning icon of system status bar will not be updated, and the actual charging status can be found in 3utools(and similar) or CL, while it will be updated in DisableInflow mode(iPhone8+), this mode is enabled in "Advanced-Control inflow".
* For TrollStore, if the daemon(of CL) get killed in any condition(such as system-reboot/userspace-reboot/...), CL will become invalid for not being able to restart daemon itself automatically.
* CL is designed to minimize the charging count, so it won't start charging or recover charging for connecting to a power source in "Plug and charge" mode, it will only start/stop charging under certain conditions as show behind.
* CL is not compatible with "Optimized Battery Charging" of Settings.app. you'd better disable it. Please re-enable in Settings.app after disabling CL if necessary. It's not recommend to use CL on newest iDevice,  "Optimized Battery Charging" is already perfect from iPhone15.
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

### The thresholds

* The default threshold is set to 20/80/10/35, you need to adjust them yourself to get CL work as expected.
* Please set temperature threshold according to "History-Hourly Data".
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

