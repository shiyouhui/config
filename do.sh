#!/bin/sh
if [ $# != 1 ];then
	echo "fatal: usage( ./configurate MD7062HC2W1 )"
	exit 1
fi
PROJECT=`expr substr $1 1 5 |tr '[A-Z]' '[a-z]'`
DENSITY=`expr substr $1 7 1`


#echo $PROJECT $DENSITY
PROFILE=../alps/mediatek/config/$PROJECT/elink/$1
CUSTOMCONF=../alps/mediatek/config/common/custom.conf
DEFAULTXML=../alps/frameworks/base/packages/SettingsProvider/res/values/defaults.xml
CONFILE="./config.ini"
BLUETOOTHNAME=`awk -F= '{if(/^蓝牙名称/)print $2}' $CONFILE`
WLANSSID=`awk -F= '{if(/^共享SSID名称/)print $2}' $CONFILE`
MODELNAME=`awk -F= '{if(/^机型名称/)print $2}' $CONFILE`
TIMEZONE=`awk -F= 'gsub(/\//,"\\\/"){if(/^时区/)print $2}' $CONFILE`
BRIGHTNESS=`awk -F= 'sub(/^[[:blank:]]*/,"",$2){if(/^默认亮度/)print $2}' $CONFILE`
SCREENTIMEOUT=`awk -F= 'sub(/^[[:blank:]]*/,"",$2){if(/^屏幕延时/)print $2}' $CONFILE`
UNKNOWSRC=`awk -F= 'sub(/^[[:blank:]]*/,"",$2){if(/^未知来源/)print $2}' $CONFILE`
INPUTMETHOD=`awk -F= 'sub(/^[[:blank:]]*/,"",$2){if(/^默认输入法/)print $2}' $CONFILE`

if [ ! -z $BLUETOOTHNAME ];then
	echo ">>>>>Configurate Bluetooth Name = $BLUETOOTHNAME "
	sed -i "/^bluetooth/s/=.*/=$BLUETOOTHNAME/" $CUSTOMCONF
fi
if [ ! -z $WLANSSID ];then
	echo ">>>>>Configurate WLAN_SSID Display Label = $WLANSSID"
	sed -i "/^wlan.SSID/s/=.*/=$WLANSSID/" $CUSTOMCONF
fi
if [ ! -z $MODELNAME ];then
	echo ">>>>>Configurate Model Name = $MODELNAME"
	sed -i "/^PRODUCT_MODEL/s/=.*/=$MODELNAME/" $PROFILE/elink_ID.mk
fi
if [ ! -z $TIMEZONE ];then
	echo ">>>>>Configurate Timezone = $TIMEZONE"
	sed -i "/^persist.sys.timezone/s/=.*/=$TIMEZONE/" $PROFILE/system.prop
fi
if [ ! -z $BRIGHTNESS ];then
	echo ">>>>>Configurate Screen brightness = $BRIGHTNESS"
	sed -i "/\"def_screen_brightness\"/s/>.*</>$BRIGHTNESS</" $DEFAULTXML
fi
if [ ! -z $SCREENTIMEOUT ];then
	echo ">>>>>Configurate screen timeout = $SCREENTIMEOUT"
	sed -i "/\"def_screen_off_timeout\"/s/>.*</>$SCREENTIMEOUT</" $DEFAULTXML
fi
if [ ! -z $UNKNOWSRC ];then
	echo ">>>>>Unkownsource selected = $UNKNOWSRC"
	sed -i "/\"def_install_non_market_apps\"/s/>.*</>$UNKNOWSRC</" $DEFAULTXML
fi
if [ ! -z $INPUTMETHOD ];then
	echo ">>>>>Modify default input_method = $INPUTMETHOD"
	sed -i "/^DEFAULT_INPUT_METHOD/s/=.*/=$INPUTMETHOD/" $PROFILE/ProjectConfig.mk
fi





