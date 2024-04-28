## ChargeLimiter

ChargeLimiter(CL) is inspired by MacOS version AlDente, used to prevent iDevice from getting overcharged, which will cause damage to the battery.     

Support Rootful Jailbreak(???-arm.deb)/Rootless Jailbreak(???-arm64.deb)/TrollStore(???.tipa). Currently support iOS12-16.6.(Notice: For TrollStore, Please uninstall older version CL before installing a newer one)       

Tested on iPhone6/7+iOS12/13 Checkra1n/Unc0ver/Odyssey; iPhone7/X/11+iOS15/16 Palera1n/Dopamine/TrollStore.      

This project is opensourced, any better ideas, submit code directly; any suggestions, submit to issue region. This software will be opensourced, free, without ads forever. Author is not responsible for any impact on iOS system or hardware caused by this software.    

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
* There are a few cases of battery with low health cause this problem. In this case, CL can contorl charge/discharge normally after a system reboot, but will fail to control after tens of minutes. CL is unavailable for this kind of battery.

Is it possible to install CL without Jailbreak or TrollStore(-like) environment?
* Private api is used in CL, so it is impossible to be published to Appstore.
* Special entitlements is used in CL, so it is impossible to be installed as common ipa files.

How to cool down the battery in summer?
* Lower power usage of iDevice hardware with "Powercuff" capability in CL, it will reduce the charging wattage in the same time. 
* Use a charger of lower Watt to charge.
* Use a heat dissipation or sth.

## Compatibility

Please test battery compatibility before using CL, stop and uninstall CL if unsupported
* 1.Check compatibility of ChargeInhibit. Disable CL by toggling the "Enable" button first, and disable all options in "Advanced", then disable charging by toggling the "Charging" button, any change within 120 seconds means ChargeInhibit is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* 2.Check compatibility of PredictiveChargingInhibit. Enable it from "Advanced-Predictive charging inhibit", then follow steps in '1'.
* 3.Check compatibility of DisableInflow. Disable CL by toggling the "Enable" button first, then disable inflow by toggling the "External connected" button when it is enabled, any change within 120 seconds means DisableInflow is supported, unless the InstantAmperage keep above 5mA after being disabled.(InstantAmperage may be invalid for a few kinds of batteries, in this case take a look at capacity increasement)
* There are a few cases of battery with low health prevent CL from working well. In this case, CL can contorl charge/discharge normally after a system reboot, but will fail to control after tens of minutes. CL is unavailable for this kind of battery.
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
* The real value stop on trigger is not necessarily equal to the target value, the differ is 0-1% in most situations, a little users got 3-5% , the differ has sth. to do with the "120 seconds delay", charging speed, and battery hardware itself. If weak amperage occurs after stopping charging, the differ maybe higher than 3%. besides, A suddenly change of the battery health will cause this situation too.

### Action

Action on trigger start/stop charging. Please reset it after reinstalling/updating CL.

### Advanced

* For "SmartBattery" and "Predictive charging inhibit", default configuration is for most users. Recombination them to find the best configuration for yourself.
* Auto inhibit inflow, DisableInflow mode is for batteries doesn't support ChargeInhibit mode, iDevice will start to consume power of battery after stopping charging if enabled.
* Thermal simulation, same as Powercuff, the higher temperature, the less power consumption of hardware(Charger/CPU/GPU//Backlight/WiFi/Radio/Speaker/Arc/...),  poorer performance, lower charging amperage and lower charging voltage. iOS system itself will update the staus according to actual situation, if you want to force specified value(not recommended), please enable "Lock". CL will be invalid if confict with other tweak with similar functionality under Jailbreak environment.
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

