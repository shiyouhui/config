#!/bin/sh
if [ $# != 1 ];then
	echo "fatal: usage( ./configurate MD7062HC2W1 )"
	exit 1
fi
PROJECT=`expr substr $1 1 5 |tr '[A-Z]' '[a-z]'`
DENSITY=`expr substr $1 7 1`

CONFIGDIR=$PWD
cd ../alps
SRCDIR=$PWD
cd ->>null
BOOTANIMATIONDIR=$CONFIGDIR/custom/开机动画
SHUTANIMATIONDIR=$CONFIGDIR/custom/关机动画
UBOOTLOGODIR=$CONFIGDIR/custom/第一屏
KERNELLOGODIR=$CONFIGDIR/custom/第二屏
PATCHDIR="$CONFIGDIR/patch"
PROFILE=$SRCDIR/mediatek/config/$PROJECT/elink/$1
CUSTOMCONF=$SRCDIR/mediatek/config/common/custom.conf
DEFAULTXML=$SRCDIR/frameworks/base/packages/SettingsProvider/res/values/defaults.xml
CONFILE="$CONFIGDIR/config.ini"
BLUETOOTHNAME=`awk -F"=" '{if(/^蓝牙名称/)print $2}' $CONFILE`
WLANSSID=`awk -F"=" '{if(/^共享SSID名称/)print $2}' $CONFILE`
MODELNAME=`awk -F"=" '{if(/^机型名称/)print $2}' $CONFILE`
BUILDVERSION=`awk -F"=" '{if(/^编译版本/)print $2}' $CONFILE`
CUSTOMBUILDVERSION=`awk -F"=" '{if(/^自定义编译版本/)print $2}' $CONFILE`
TIMEZONE=`awk -F"=" 'gsub(/\//,"\\\/"){if(/^时区/)print $2}' $CONFILE`
BRIGHTNESS=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认亮度/)print $2}' $CONFILE`
SCREENTIMEOUT=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^屏幕延时/)print $2}' $CONFILE`
UNKNOWSRC=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^未知来源/)print $2}' $CONFILE`
INPUTMETHOD=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认输入法/)print $2}' $CONFILE`
DISKLABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^可移动磁盘/)print $2}' $CONFILE`
ONLINELABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^联机ID/)print $2}' $CONFILE`
HOMEPAGE=`awk -F"=" 'gsub(/\//,"\\\/")sub(/^[[:blank:]]*/,"",$2){if(/^浏览器主页/)print $2}' $CONFILE`
ACTIVEPROFILE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^情景模式/)print $2}' $CONFILE`
SUBCAMERA=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^前摄像头插值/)print $2}' $CONFILE`
MAINCAMERA=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^后摄像头插值/)print $2}' $CONFILE`
BOOTANIMATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^开机动画/)print $2}' $CONFILE`
BOOTFPS=`echo $BOOTANIMATION | awk '{print $1}'`
BOOTTIMES=`echo $BOOTANIMATION | awk '{print $2}'`
SHUTANIMATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^关机动画/)print $2}' $CONFILE`
SHUTFPS=`echo $SHUTANIMATION | awk '{print $1}'`
SHUTTIMES=`echo $SHUTANIMATION | awk '{print $2}'`
UBOOTLOGO=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^第一屏/)print $2}' $CONFILE`
KERNELLOGO=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^第二屏/)print $2}' $CONFILE`



#修改蓝牙名称
if [ ! -z "$BLUETOOTHNAME" ];then
	echo ">>>>>Configurate Bluetooth Name = $BLUETOOTHNAME "
	sed -i "/^bluetooth/s/=.*/=$BLUETOOTHNAME/" $CUSTOMCONF
fi

#修改Wifi共享热点SSID
if [ ! -z "$WLANSSID" ];then
	echo ">>>>>Configurate WLAN_SSID Display Label = $WLANSSID"
	sed -i "/^wlan.SSID/s/=.*/=$WLANSSID/" $CUSTOMCONF
fi

#修改机型名
if [ ! -z "$MODELNAME" ];then
	echo ">>>>>Configurate Model Name = $MODELNAME"
	sed -i "/^PRODUCT_MODEL/s/=.*/=$MODELNAME/" $PROFILE/elink_ID.mk
fi

#修改编译版本
if [ ! -z "$BUILDVERSION" ];then
	echo ">>>>>Configurate Build version = $BUILDVERSION"
	sed -i "/^ELINK_VERSION/s/=.*/=$BUILDVERSION/" $PROFILE/elink_ID.mk
fi

#修改自定义编译版本
if [ ! -z "$CUSTOMBUILDVERSION" ];then
	echo ">>>>>Configurate Customer build version = $CUSTOMBUILDVERSION"
	sed -i "/^CUSTOM_BUILD_VERNO/s/=.*/=$CUSTOMBUILDVERSION/" $SRCDIR/mediatek/config/common/ProjectConfig.mk
fi

#修改时区
if [ ! -z "$TIMEZONE" ];then
	echo ">>>>>Configurate Timezone = $TIMEZONE"
	sed -i "/^persist.sys.timezone/s/=.*/=$TIMEZONE/" $PROFILE/system.prop
fi

#修改默认亮度
if [ ! -z "$BRIGHTNESS" ];then
	echo ">>>>>Configurate Screen brightness = $BRIGHTNESS"
	sed -i "/\"def_screen_brightness\"/s/>.*</>$BRIGHTNESS</" $DEFAULTXML
fi

#修改屏幕延时
if [ ! -z "$SCREENTIMEOUT" ];then
	echo ">>>>>Configurate screen timeout = $SCREENTIMEOUT"
	sed -i "/\"def_screen_off_timeout\"/s/>.*</>$SCREENTIMEOUT</" $DEFAULTXML
fi

#修改未知来源默认
if [ ! -z "$UNKNOWSRC" ];then
	echo ">>>>>Unkownsource selected = $UNKNOWSRC"
	sed -i "/\"def_install_non_market_apps\"/s/>.*</>$UNKNOWSRC</" $DEFAULTXML
fi

#修改默认输入法
if [ ! -z "$INPUTMETHOD" ];then
	echo ">>>>>Modify default input_method = $INPUTMETHOD"
	sed -i "/^DEFAULT_INPUT_METHOD/s/=.*/=$INPUTMETHOD/" $PROFILE/ProjectConfig.mk
fi

#修改可移动磁盘名
if [ ! -z "$DISKLABEL" ];then
	echo ">>>>>Modify disk = $DISKLABEL"
	cd $SRCDIR/system/core
	git apply --ignore-whitespace $PATCHDIR/lowcase.patch  
	cd ../vold
	git  apply --ignore-whitespace $PATCHDIR/parttion_label.patch 
	sed -i "s/MID-700/$DISKLABEL/" ./Fat.cpp 
	cd $CONFIGDIR
fi

#修改联机ID
if [ ! -z "$ONLINELABEL" ];then
	echo ">>>>>Modify line_label = $ONLINELABEL"
	sed -i "s/File-Stor Gadget/$ONLINELABEL/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
	sed -i "s/File-CD Gadget/$ONLINELABEL/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
fi

#修改浏览器主页
if [ ! -z "$HOMEPAGE" ];then
	echo ">>>>>Modify default Browse Homepage = `expr substr $HOMEPAGE 10 20`"
	sed -i "s/getFactoryResetHomeUrl(mContext)/\"$HOMEPAGE\"/" $SRCDIR/packages/apps/Browser/src/com/android/browser/BrowserSettings.java
fi

#修改前摄像头插值
if  [ ! -z "$SUBCAMERA" ];then
	if [ "$SUBCAMERA" = "30" ];then
		SUBSIZE=CAPTURE_SIZE_640_480
	elif [ "$SUBCAMERA" = "200" ];then
		SUBSIZE=CAPTURE_SIZE_1600_1200
	elif [ "$SUBCAMERA" = "500" ];then
		SUBSIZE=CAPTURE_SIZE_2560_1920
	else
		echo "摄像头像素 30 200 500 万"
	fi
	echo ">>>>>Modify subcamera = $SUBSIZE"
	cd $SRCDIR/mediatek/custom/mt6577/
	git apply $PATCHDIR/subcamera.patch
	sed -i "/BY_DEFAULT(CAPTURE_SIZE/s/CAPTURE_SIZE_.*/CAPTURE_SIZE_`expr substr $SUBSIZE 14 10`),/" $SRCDIR/mediatek/custom/mt6577/hal/camera/camera/cfg_ftbl_custom_yuv_sub.h
	sed -i "/$SUBSIZE,/s/$SUBSIZE,.*/$SUBSIZE/" $SRCDIR/mediatek/custom/mt6577/hal/camera/camera/cfg_ftbl_custom_yuv_sub.h
fi

#修改后摄像头插值
if  [ ! -z "$MAINCAMERA" ];then
	if [ "$MAINCAMERA" = "30" ];then
		MAINSIZE=CAPTURE_SIZE_640_480
	elif [ "$MAINCAMERA" = "200" ];then
		MAINSIZE=CAPTURE_SIZE_1600_1200
	elif [ "$MAINCAMERA" = "500" ];then
		MAINSIZE=CAPTURE_SIZE_2560_1920
	else
		echo "摄像头像素 30 200 500 万"
	fi
	echo ">>>>>Modify subcamera = $MAINSIZE"
	cd $SRCDIR/mediatek/custom/mt6577/
	git apply $PATCHDIR/maincamera_1.patch
	sed -i "/BY_DEFAULT(CAPTURE_SIZE/s/CAPTURE_SIZE_.*/CAPTURE_SIZE_`expr substr $MAINSIZE 14 10`),/" $SRCDIR/mediatek/custom/mt6577/hal/camera/camera/cfg_ftbl_custom_yuv_main.h
	sed -i "/$MAINSIZE,/s/$MAINSIZE,.*/$MAINSIZE/" $SRCDIR/mediatek/custom/mt6577/hal/camera/camera/cfg_ftbl_custom_yuv_main.h

	cd $SRCDIR/mediatek/custom/$PROJECT/
	git apply $PATCHDIR/maincamera_2.patch
	sed -i "/BY_DEFAULT(CAPTURE_SIZE/s/CAPTURE_SIZE_.*/CAPTURE_SIZE_`expr substr $MAINSIZE 14 10`),/" $SRCDIR/mediatek/custom/$PROJECT/hal/camera/camera/cfg_ftbl_custom_raw_main.h
	sed -i "/$MAINSIZE,/s/$MAINSIZE,.*/$MAINSIZE/" $SRCDIR/mediatek/custom/$PROJECT/hal/camera/camera/cfg_ftbl_custom_raw_main.h
fi

#修改默认情景模式
if [ ! -z "$ACTIVEPROFILE" ];then
	if [ "$ACTIVEPROFILE" = "标准" ];then
		RESULT=mtk_audioprofile_general
	elif [ "$ACTIVEPROFILE" = "静音" ];then
		RESULT=mtk_audioprofile_silent
	elif [ "$ACTIVEPROFILE" = "会议" ];then
		RESULT=mtk_audioprofile_meeting
	elif [ "$ACTIVEPROFILE" = "户外" ];then
		RESULT=mtk_audioprofile_outdoor
	else
		echo "情景模式输入错误，请按可供选择输入(标准，静音，会议，户外)"
	fi
	echo ">>>>>Modify line_label = $ACTIVEPROFILE"
	sed -i "/\"def_active_profile\"/s/>.*</>$RESULT</" $SRCDIR/frameworks/base/packages/SettingsProvider/res/values/mtk_defaults.xml
fi

#制作动画
makeanimation()
{
	if [ $1 = "boot" ];then
		echo ">>>>>begin to make bootanimation"
		cd $BOOTANIMATIONDIR
		RESULT=bootanimation
	elif [ $1 = "shut" ];then
		echo ">>>>>begin to make shutanimation"
		cd $SHUTANIMATIONDIR
		RESULT=shutanimation
	fi
	FILES=`ls | sort -n | grep -v ".sh" | grep -v ".db" | grep -v ".txt" | grep -v "bootanimation" `
	if [ -z "$FILES" ];then
		echo "no animation source picture!!!"
		exit 1
	fi
	
	mkdir -p $RESULT/part0
	mkdir -p $RESULT/part1
	FILEINFO=`file ${FILES}`
	LASTONE=`echo $FILES| awk '{print $NF}'`
	NF=`echo $FILES| awk '{print NF}'`
	INDEX=0
	EXTENSION=${LASTONE##*.}
	WIDTH=`identify $LASTONE | awk '{print $3}' | awk -F"x" '{print $1}'`
	HEIGHT=`identify $LASTONE | awk '{print $3}' | awk -F"x" '{print $2}'`
	cp $LASTONE $RESULT/part1/`printf "%04d\n" $NF`.$EXTENSION
	
	for i in ${FILES}
	do 
		INDEX=`expr $INDEX + 1` 
		NAME=`printf "%04d\n" ${INDEX}`
		mv $i $RESULT/part0/${NAME}.$EXTENSION
	done
	
	cd $RESULT

	if [ $1 = "boot" ];then
		echo "$WIDTH $HEIGHT $BOOTFPS" > desc.txt
		echo "p $BOOTTIMES 0 part0" >> desc.txt
		echo "p 0 0 part1" >> desc.txt
	elif [ $1 = "shut" ];then
		echo "$WIDTH $HEIGHT $SHUTFPS" > desc.txt
		echo "p $SHUTTIMES 0 part0" >> desc.txt
		echo "p 0 0 part1" >> desc.txt
	fi
	zip ./$RESULT ./* ./desc.txt -r -0
	cp $RESULT.zip $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/media/
	rm ../* -r
	echo "make $RESULT successfully ===========> OK"
	cd $CONFIGDIR
}

#开机动画
if [ ! -z "$BOOTANIMATION" ];then
	makeanimation boot;
fi

#关机动画
if [ ! -z "$SHUTANIMATION" ];then
	makeanimation shut;
fi

#开机logo
makelogo()
{
	if [ $1 = "uboot" ];then
		echo ">>>>>begin to make uboot logo"
		cd $UBOOTLOGODIR
	elif [ $1 = "kernel" ];then
		echo ">>>>>begin to make kernel logo"
		cd $KERNELLOGODIR
	fi

	if [ $PROJECT = "md706" ];then
		if [ $DENSITY = "L" ];then
			convert * cu_wvga_$1.bmp
			cp -p *.bmp $SRCDIR/mediatek/custom/common/lk/logo/cu_wvga/
			rm *
		elif [ $DENSITY = "H" ];then  
			convert * wsvga_$1.bmp
			cp -p *.bmp $SRCDIR/mediatek/custom/common/lk/logo/wsvga/
			rm *
		fi
	elif [ $PROJECT = "md790" ];then
		echo "MD790"
	fi
	echo "make $1 logo  successfully ===========> OK"
	cd $CONFIGDIR


}



#开机第一屏logo
if [ ! -z "$UBOOTLOGO" ];then
	makelogo uboot
fi

#开机第二屏logo
if [ ! -z "$KERNELLOGO" ];then
	makelogo kernel
fi

