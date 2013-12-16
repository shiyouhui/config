#!/bin/sh
if [ $# != 1 ];then
	echo "fatal: usage( ./do MD7062HC2W1 )"
	exit 1
fi
PROJECT=`expr substr $1 1 5 |tr '[A-Z]' '[a-z]'`
DENSITY=`expr substr $1 7 1`

CONFIGDIR=$PWD
cd ../alps
SRCDIR=$PWD
cd ->>/dev/null
PATCHDIR="$CONFIGDIR/patch"
PROFILE=$SRCDIR/mediatek/config/$PROJECT/elink/$1
COMMONPROFILE=$SRCDIR/mediatek/config/common
CUSTOMCONF=$SRCDIR/mediatek/config/common/custom.conf
DEFAULTXML=$SRCDIR/frameworks/base/packages/SettingsProvider/res/values/defaults.xml
BULIDFILE=$SRCDIR/build/target/product/core.mk
SOUNDSDIR=$SRCDIR/frameworks/base/data/sounds
CONFILE="$CONFIGDIR/config.ini"



#生成修改记录
LASTTIME=`ls -l $SRCDIR | grep "修改记录" | awk '{printf("%s %s", $6, $7);}'` 
SECOND_OLD=`date --date="$LASTTIME" +%s`
SECOND_NEW=$(date +%s)
HOUR=`echo "($SECOND_NEW - $SECOND_OLD)/3600" | bc`
if [  $HOUR -gt 4 ];then
	ISNEW=true
	if [ -e $SRCDIR/修改记录.txt ];then
		rm $SRCDIR/修改记录.txt
	fi
	touch $SRCDIR/修改记录.txt
	DATE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/需求日期/)print $2}' $CONFILE`
	if [ "$DATE" = "请输入" ]; then
		echo "修改记录:\n\n需求日期:$(date +%Y%m%d)" > $SRCDIR/修改记录.txt	
	else
		echo "修改记录:\n\n需求日期:$DATE" > $SRCDIR/修改记录.txt	
	fi
else
	ISNEW=false
fi

#修改机型名
MODELNAME=`awk -F"=" '{if(/^机型名称/)print $2}' $CONFILE`
if [ ! -z "$MODELNAME" ];then
	echo ">>>>>Configurate Model Name = $MODELNAME"
	sed -i "/^PRODUCT_MODEL/s/=.*/=$MODELNAME/" $PROFILE/elink_ID.mk
	echo "客户机型:$MODELNAME\n" >> $SRCDIR/修改记录.txt
else
	echo "客户机型:$1\n" >> $SRCDIR/修改记录.txt
fi

#修改蓝牙名称
BLUETOOTHNAME=`awk -F"=" '{if(/^蓝牙名称/)print $2}' $CONFILE`
if [ ! -z "$BLUETOOTHNAME" ];then
	echo ">>>>>Configurate Bluetooth Name = $BLUETOOTHNAME "
	sed -i "/^bluetooth/s/=.*/=$BLUETOOTHNAME/" $CUSTOMCONF
	echo "修改蓝牙名称:$BLUETOOTHNAME" >> $SRCDIR/修改记录.txt
fi

#修改Wifi共享热点SSID
WLANSSID=`awk -F"=" '{if(/^共享SSID名称/)print $2}' $CONFILE`
if [ ! -z "$WLANSSID" ];then
	echo ">>>>>Configurate WLAN_SSID Display Label = $WLANSSID"
	sed -i "/^wlan.SSID/s/=.*/=$WLANSSID/" $CUSTOMCONF
	echo "修改Wifi共享热点SSID:$WLANSSID" >> $SRCDIR/修改记录.txt
fi

#修改编译版本
BUILDVERSION=`awk -F"=" '{if(/^编译版本/)print $2}' $CONFILE`
if [ ! -z "$BUILDVERSION" ];then
	echo ">>>>>Configurate Build version = $BUILDVERSION"
	sed -i "/^ELINK_VERSION/s/=.*/=$BUILDVERSION/" $PROFILE/elink_ID.mk
	echo "修改编译版本:$BUILDVERSION" >> $SRCDIR/修改记录.txt
fi

#修改自定义编译版本
CUSTOMBUILDVERSION=`awk -F"=" '{if(/^自定义编译版本/)print $2}' $CONFILE`
if [ ! -z "$CUSTOMBUILDVERSION" ];then
	echo ">>>>>Configurate Customer build version = $CUSTOMBUILDVERSION"
	sed -i "/^CUSTOM_BUILD_VERNO/s/=.*/=$CUSTOMBUILDVERSION/" $SRCDIR/mediatek/config/common/ProjectConfig.mk
	echo "修改自定义编译版本:$CUSTOMBUILDVERSION" >> $SRCDIR/修改记录.txt
fi

#修改时区
TIMEZONE=`awk -F"=" 'gsub(/\//,"\\\/"){if(/^时区/)print $2}' $CONFILE`
if [ ! -z "$TIMEZONE" ];then
	echo ">>>>>Configurate Timezone = $TIMEZONE"
	sed -i "/^persist.sys.timezone/s/=.*/=$TIMEZONE/" $PROFILE/system.prop
	echo "修改时区:$TIMEZONE" >> $SRCDIR/修改记录.txt
fi

#修改默认亮度
BRIGHTNESS=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认亮度/)print $2}' $CONFILE`
if [ ! -z "$BRIGHTNESS" ];then
	echo ">>>>>Configurate Screen brightness = $BRIGHTNESS"
	sed -i "/\"def_screen_brightness\"/s/>.*</>$BRIGHTNESS</" $DEFAULTXML
	echo "修改默认亮度:$BRIGHTNESS" >> $SRCDIR/修改记录.txt
fi

#修改屏幕延时
SCREENTIMEOUT=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^屏幕延时/)print $2}' $CONFILE`
if [ ! -z "$SCREENTIMEOUT" ];then
	echo ">>>>>Configurate screen timeout = $SCREENTIMEOUT"
	sed -i "/\"def_screen_off_timeout\"/s/>.*</>$SCREENTIMEOUT</" $DEFAULTXML
	echo "修改屏幕延时:$(`expr $SCREENTIMEOUT \/ 1000`)秒" >> $SRCDIR/修改记录.txt
fi

#修改未知来源默认
UNKNOWSRC=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^未知来源/)print $2}' $CONFILE`
if [ ! -z "$UNKNOWSRC" ];then
	echo ">>>>>Unkownsource selected = $UNKNOWSRC"
	sed -i "/\"def_install_non_market_apps\"/s/>.*</>$UNKNOWSRC</" $DEFAULTXML
	echo "默认打开未知来源选项" >> $SRCDIR/修改记录.txt
fi

#修改默认输入法
INPUTMETHOD=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认输入法/)print $2}' $CONFILE`
if [ ! -z "$INPUTMETHOD" ];then
	echo ">>>>>Modify default input_method = $INPUTMETHOD"
	sed -i "/^DEFAULT_INPUT_METHOD/s/=.*/=$INPUTMETHOD/" $PROFILE/ProjectConfig.mk
	echo "修改默认输入法:$INPUTMETHOD" >> $SRCDIR/修改记录.txt
fi

#修改可移动磁盘名
DISKLABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^可移动磁盘/)print $2}' $CONFILE`
if [ ! -z "$DISKLABEL" ];then
	echo ">>>>>Modify disk = $DISKLABEL"
	cd $SRCDIR/system/core
	git apply --ignore-whitespace $PATCHDIR/lowcase.patch  
	cd ../vold

	PRO=`expr substr $PROJECT 1 2`
	if [ $PRO = "md" ];then
		git  apply --ignore-whitespace $PATCHDIR/parttion_label.patch 
	elif [ $PRO = "mr" ]; then
		git  apply --ignore-whitespace $PATCHDIR/mr_parttion_label.patch 
	fi

	sed -i "/display label/s/\".*\"/\"$DISKLABEL\"/" ./Fat.cpp 
	cd $CONFIGDIR
	echo "修改可移动磁盘名:$DISKLABEL" >> $SRCDIR/修改记录.txt
fi

#修改联机ID
ONLINELABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^联机ID/)print $2}' $CONFILE`
if [ ! -z "$ONLINELABEL" ];then
	echo ">>>>>Modify line_label = $ONLINELABEL"
	cd $SRCDIR/kernel/drivers
	git apply --ignore-whitespace $PATCHDIR/usbid_label.patch
	sed -i "/id display label1/s/\".*\"/\"$ONLINELABEL\"/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
	sed -i "/id display label2/s/\".*\"/\"$ONLINELABEL\"/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
	echo "修改联机ID:$ONLINELABEL" >> $SRCDIR/修改记录.txt
fi

#修改浏览器主页
HOMEPAGE=`awk -F"=" 'gsub(/\//,"\\\/")sub(/^[[:blank:]]*/,"",$2){if(/^浏览器主页/)print $2}' $CONFILE`
if [ ! -z "$HOMEPAGE" ];then
	echo ">>>>>Modify default Browse Homepage = `expr substr $HOMEPAGE 10 20`"
	cd $SRCDIR/packages/apps/Browser
	git apply --ignore-whitespace $PATCHDIR/homepage.patch
	sed -i "/default homepage/s/,.*);/,\"$HOMEPAGE\");/" $SRCDIR/packages/apps/Browser/src/com/android/browser/BrowserSettings.java
	echo "修改浏览器主页:$HOMEPAGE" >> $SRCDIR/修改记录.txt
fi

#修改前摄像头插值
SUBCAMERA=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^前摄像头插值/)print $2}' $CONFILE`
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
	echo "修改前摄像头插值:$SUBCAMERA" >> $SRCDIR/修改记录.txt
fi

#修改后摄像头插值
MAINCAMERA=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^后摄像头插值/)print $2}' $CONFILE`
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
	echo "修改后摄像头插值:$MAINCAMERA" >> $SRCDIR/修改记录.txt
fi

#修改默认情景模式
ACTIVEPROFILE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^情景模式/)print $2}' $CONFILE`
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
	echo "修改默认情景模式:$ACTIVEPROFILE" >> $SRCDIR/修改记录.txt
fi

#制作动画
BOOTANIMATIONDIR=$CONFIGDIR/custom/开机动画
SHUTANIMATIONDIR=$CONFIGDIR/custom/关机动画
BOOTANIMATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^开机动画/)print $2}' $CONFILE`
BOOTFPS=`echo $BOOTANIMATION | awk '{print $1}'`
BOOTTIMES=`echo $BOOTANIMATION | awk '{print $2}'`
SHUTANIMATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^关机动画/)print $2}' $CONFILE`
SHUTFPS=`echo $SHUTANIMATION | awk '{print $1}'`
SHUTTIMES=`echo $SHUTANIMATION | awk '{print $2}'`
makeanimation()
{
	if [ $1 = "boot" ];then
		echo ">>>>>begin to make bootanimation"
		cd $BOOTANIMATIONDIR
		RESULT=bootanimation
		TIMES=$BOOTTIMES
	elif [ $1 = "shut" ];then
		echo ">>>>>begin to make shutanimation"
		cd $SHUTANIMATIONDIR
		RESULT=shutanimation
		TIMES=$SHUTTIMES
	fi

	FILES=`ls | sort -n`
	NF=`ls -l | grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no animation source picture!!!"
		return
	fi

	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
			fi
		done
	fi

	FILES=`ls | sort -n`
	LASTONE=`echo $FILES| awk '{print $NF}'`
	INDEX=0
	EXTENSION=${LASTONE##*.}
	WIDTH=`identify $LASTONE | awk '{print $3}' | awk -F"x" '{print $1}'`
	HEIGHT=`identify $LASTONE | awk '{print $3}' | awk -F"x" '{print $2}'`

	if [ $TIMES = "0" ];then
		mkdir -p $RESULT/part0
		for i in ${FILES}
		do 
			INDEX=`expr $INDEX + 1` 
			NAME=`printf "%04d\n" ${INDEX}`
			echo "mv $i $RESULT/part0/${NAME}.$EXTENSION"
			mv $i $RESULT/part0/${NAME}.$EXTENSION
			if [ "$EXTENSION" != "png" -a "$EXTENSION" != "PNG" ];then
				convert $RESULT/part0/${NAME}.$EXTENSION $RESULT/part$k/${NAME}.png
				rm $RESULT/part0/${NAME}.$EXTENSION
			fi
		done
		mkdir -p $RESULT/part1
		cp $RESULT/part0/${NAME}.* $RESULT/part1/
	else
		for i in ${FILES}
		do 
			INDEX=`expr $INDEX + 1` 
			j=`echo "( $INDEX - 1 )%20" |bc`
			k=`echo "( $INDEX - 1 )/20" |bc`
			
			if [ $j -eq 0 ];then
				mkdir -p $RESULT/part$k
			fi
			NAME=`printf "%04d\n" ${INDEX}`
			echo "mv $i $RESULT/part$k/${NAME}.$EXTENSION"
			mv $i $RESULT/part$k/${NAME}.$EXTENSION
	
			if [ "$EXTENSION" != "png" -a "$EXTENSION" != "PNG" ];then
				convert $RESULT/part$k/${NAME}.$EXTENSION $RESULT/part$k/${NAME}.png
				rm $RESULT/part$k/${NAME}.$EXTENSION
			fi
		done
	fi

	if [ $k = "0" ];then
		mkdir -p $RESULT/part1
	fi

	cd $RESULT

	if [ $1 = "boot" ];then
		echo "$WIDTH $HEIGHT $BOOTFPS" > desc.txt
		for i in `ls -l | grep "^d" | awk '{print $8}'`
		do
			echo "p $BOOTTIMES 0 $i" >> desc.txt
		done
	elif [ $1 = "shut" ];then
		echo "$WIDTH $HEIGHT $SHUTFPS" > desc.txt
		for i in `ls -l | grep "^d" | awk '{print $8}'`
		do
			echo "p $SHUTTIMES 0 $i" >> desc.txt
		done
	fi

	zip ./$RESULT ./* ./desc.txt -r -0
	if [ ! -e $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/media/ ];then
		mkdir -p $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/media/
	fi
	cp $RESULT.zip $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/media/
	rm ../* -r
	echo "make $RESULT successfully ===========> OK"
	cd $CONFIGDIR
}

#开机动画
if [ ! -z "$BOOTANIMATION" ];then
	makeanimation boot;
	echo "制作开机动画" >> $SRCDIR/修改记录.txt
fi

#关机动画
if [ ! -z "$SHUTANIMATION" ];then
	makeanimation shut;
	echo "制作关机动画" >> $SRCDIR/修改记录.txt
fi

#制作开机logo
UBOOTLOGODIR=$CONFIGDIR/custom/第一屏
KERNELLOGODIR=$CONFIGDIR/custom/第二屏
UBOOTLOGO=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^第一屏/)print $2}' $CONFILE`
KERNELLOGO=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^第二屏/)print $2}' $CONFILE`
makelogo()
{
	if [ $1 = "uboot" ];then
		echo ">>>>>begin to make uboot logo"
		cd $UBOOTLOGODIR
	elif [ $1 = "kernel" ];then
		echo ">>>>>begin to make kernel logo"
		cd $KERNELLOGODIR
	fi

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no logo source picture!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv 	"$f" "$TARGET"
			fi
		done
	fi

	if [ $PROJECT = "md706" -o $PROJECT = "md708" -o $PROJECT = "mr706" ];then
		if [ $DENSITY = "L" ];then
			convert * cu_wvga_$1.bmp
			cp -p cu_wvga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/cu_wvga/
			rm *
		elif [ $DENSITY = "H" ];then  
			convert * wsvga_$1.bmp
			cp -p wsvga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wsvga/
			rm *
		fi
	elif [ $PROJECT = "md790" -o $PROJECT = "mr790" ];then 
			convert * xga_$1.bmp
			cp -p xga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/xga/
			rm *
	elif [ $PROJECT = "md601" -o $PROJECT = "md680" ];then
			convert * cu_qhd_$1.bmp
			cp -p cu_qhd_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/cu_qhd/
			rm *
	elif [ $PROJECT = "md900" -o $PROJECT = "md100" ];then
		if [ $DENSITY = "L" ];then
			convert * wvgalnl_$1.bmp
			cp -p wvgalnl_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wvgalnl/
			rm *
		elif [ $DENSITY = "H" ];then  
			convert * wsvganl_$1.bmp
			cp -p wsvganl_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wsvganl/
			rm *
		fi
	fi
	echo "make $1 logo  successfully ===========> OK"
	cd $CONFIGDIR
}

#开机第一屏logo
if [ ! -z "$UBOOTLOGO" ];then
	makelogo uboot
	echo "修改logo1" >> $SRCDIR/修改记录.txt
fi

#开机第二屏logo
if [ ! -z "$KERNELLOGO" ];then
	makelogo kernel
	echo "修改logo2" >> $SRCDIR/修改记录.txt
fi

#修改默认壁纸
WALLPAPER=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认桌面壁纸/)print $2}' $CONFILE`
WALLPAPERDIR=$CONFIGDIR/custom/默认桌面壁纸
if [ ! -z "$WALLPAPER" ];then
	echo ">>>>>Change default wallpaper!!"
	cd $WALLPAPERDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no default wallpaper source picture!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
					mv "$f" "$TARGET"
					echo mv "$f" "$TARGET"
			fi
		done
	fi
	convert * default_wallpaper.jpg 
	PRO=`expr substr $PROJECT 1 2`
	if [ $PRO = "md" ];then
		cp -p  default_wallpaper.jpg $SRCDIR/frameworks/base/core/res/res/drawable-nodpi/
	elif [ $PRO = "mr" ]; then
		cp -p  default_wallpaper.jpg $SRCDIR/frameworks/base/core/res/res/drawable-xhdpi/
	fi
	
	rm * -r
	echo "Change default  wallpaper  successfully ===========> OK"
	cd $SRCDIR
	echo "修改默认壁纸" >> $SRCDIR/修改记录.txt
fi

#预置APK
APKHANDLE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^预置APK/)print $2}' $CONFILE`
APKDIR=$CONFIGDIR/custom/预置APK
DATAAPPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app
SYSTEMAPPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/app
BACKUPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/appbackup
if [ ! -z "$APKHANDLE" ];then
	echo ">>>>>begin copy customer apk to android soruce!!"
	cd $APKDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "NO apk file!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
			fi
		done
	fi

	if [ ! -d $DATAAPPDIR ];then
		mkdir -p $DATAAPPDIR
	fi
	if [ ! -d $SYSTEMAPPDIR ];then
		mkdir -p $SYSTEMAPPDIR
	fi
	if [ ! -d $BACKUPDIR ];then
		mkdir -p $BACKUPDIR
	fi



	if [ "$APKHANDLE" -eq "1" ];then
		for i in `ls`
		do
			echo "copy $i to app"
			cp -p $i $DATAAPPDIR
			echo "copy $i to appbackup"
			cp -p $i $BACKUPDIR
			echo "/data/app/$i" >> $DATAAPPDIR/.keep_list
			echo "/system/appbackup/$i" >> $SYSTEMAPPDIR/.restore_list
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(可卸载可恢复)" >> $SRCDIR/修改记录.txt

	elif [ "$APKHANDLE" -eq "2" ];then
		for i in `ls`
		do
			echo "copy $i to system_app"
			APKNAME=${i%\.*}
			mkdir -p  $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME
			cp -p $i $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/
			cp -p $PATCHDIR/Android.mk $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/
			sed -i "/LOCAL_MODULE :=/s/:=.*/:= $APKNAME/" $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/Android.mk
			sed -i '/ElinkEng.*/s/^/    '$APKNAME' \\\n/' $SRCDIR/vendor/common/SYSTEM_APP/products/APPS.mk
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(不可卸载)" >> $SRCDIR/修改记录.txt
	elif [ "$APKHANDLE" -eq "3" ];then
		echo "copy $i to app"
		for i in `ls`
		do
			echo "copy $i to app"
			cp -p $i $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app/
			echo "/data/app/$i" >> $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app/.keep_list
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(可卸载不可恢复)" >> $SRCDIR/修改记录.txt
	else
		echo "ERROE:error apk handle!!!!"
		return
	fi

fi

#添加壁纸
EXTRAWALLPAPER=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^备选壁纸/)print $2}' $CONFILE`
EXTRAWALLPAPERDIR=$CONFIGDIR/custom/备选壁纸
if [ ! -z "$EXTRAWALLPAPER" ];then
	echo ">>>>>begin copy extra wallpaper!!"
	cd $EXTRAWALLPAPERDIR
	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no extra wallpaper picture!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
			fi
		done
	fi

	INDEX=1
	LASTONE=`echo $FILES| awk '{print $NF}'`
	EXTENSION=${LASTONE##*.}
	for f in `ls ./ | tr " " "\?"`
	do
		mv "$f" wallpaper_extra_$INDEX.$EXTENSION
		echo mv "$f" wallpaper_extra_$INDEX.$EXTENSION
		convert -resize 213x189 wallpaper_extra_"$INDEX"."$EXTENSION" wallpaper_extra_"$INDEX"_small.$EXTENSION
		cp  wallpaper_extra_"$INDEX"."$EXTENSION" $SRCDIR/packages/apps/Launcher2/res/drawable-nodpi/
		cp  wallpaper_extra_"$INDEX"_small.$EXTENSION $SRCDIR/packages/apps/Launcher2/res/drawable-nodpi/
		PRO=`expr substr $PROJECT 1 2`
		if [ $PRO = "md" ];then
			sed -i "/wallpapers/s/$/\n        <item>wallpaper_extra_$INDEX<\/item>/" $SRCDIR/packages/apps/Launcher2/res/values/wallpapers.xml
		elif [ $PRO = "mr" ]; then
			sed -i "/wallpapers/s/$/\n        <item>wallpaper_extra_$INDEX<\/item>/" $SRCDIR/packages/apps/Launcher2/res/values-sw600dp/wallpapers.xml
		fi
		
		INDEX=`expr $INDEX + 1` 
	done
	rm * -r
	cd $CONFIGDIR
	echo "预置壁纸:$NF张" >> $SRCDIR/修改记录.txt
fi

#默认语言
LANGUAGE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认语言/)print $2}' $CONFILE`
if [ ! -z "$LANGUAGE" ];then
	echo ">>>>>default Language = $LANGUAGE"
	sed -i "/DEFAULT_LATIN_IME_LANGUAGES/s/=.*/=$LANGUAGE/" $PROFILE/ProjectConfig.mk
	sed -i "/MTK_PRODUCT_LOCALES/s/$LANGUAGE//" $PROFILE/ProjectConfig.mk
	sed -i "/MTK_PRODUCT_LOCALES/s/=/=$LANGUAGE /" $PROFILE/ProjectConfig.mk
	echo "修改默认语言:$LANGUAGE" >> $SRCDIR/修改记录.txt
fi

#开启ROOT权限
OPENROOT=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^开启ROOT权限/)print $2}' $CONFILE`
if [ ! -z "$OPENROOT" ]; then
	echo ">>>>>Open root permission"
	sed -i "/^EK_ROOT_SUPPORT/s/=.*/=$OPENROOT/" $COMMONPROFILE/ProjectConfig.mk
	echo "开启ROOT权限" >> $SRCDIR/修改记录.txt
fi

#默认来电铃声
DEFAULTRINGTONE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认来电铃声/)print $2}' $CONFILE`
DEFAULTRINGTONEDIR=$CONFIGDIR/custom/默认来电铃声
if [ ! -z "$DEFAULTRINGTONE" ]; then
	echo ">>>>>Change default ringtone!!"
	cd $DEFAULTRINGTONEDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no default ringtone source file!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
			fi
		done
	fi
	if [ $NF = "1" ]; then
		RINGFILE=`ls`
		cp $DEFAULTRINGTONEDIR/$RINGFILE $SOUNDSDIR/ringtones
		sed -i "/ro.config.ringtone/s/=.*/=$RINGFILE /" $BULIDFILE
		sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/ringtones/'$RINGFILE':system/media/audio/ringtones/'$RINGFILE' \\' $SOUNDSDIR/AudioPackage2.mk
		rm $DEFAULTRINGTONEDIR/$RINGFILE
	else
		echo "ERROR More than one audio file."
	fi
fi

#备选来电铃声
EXTRARINGTONE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^备选来电铃声/)print $2}' $CONFILE`
EXTRARINGTONEDIR=$CONFIGDIR/custom/备选来电铃声
if [ ! -z "$EXTRARINGTONE" ]; then
	echo ">>>>>Add extra ringtone!!"
	cd $EXTRARINGTONEDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no extra ringtone source file!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
				cp $EXTRARINGTONEDIR/$f $SOUNDSDIR/ringtones
				sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/ringtones/'$f':system/media/audio/ringtones/'$f' \\' $SOUNDSDIR/AudioPackage2.mk
			fi
		done
	else
		for f in `ls ./`
		do
			cp $EXTRARINGTONEDIR/$f $SOUNDSDIR/ringtones
			sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/ringtones/'$f':system/media/audio/ringtones/'$f' \\' $SOUNDSDIR/AudioPackage2.mk
		done
	fi
	rm $EXTRARINGTONEDIR/*
fi

#默认通知铃声
DEFAULNOTIFICATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认通知铃声/)print $2}' $CONFILE`
DEFAULNOTIFICATIONDIR=$CONFIGDIR/custom/默认通知铃声
if [ ! -z "$DEFAULNOTIFICATION" ]; then
	echo ">>>>>Change default notifications!!"
	cd $DEFAULNOTIFICATIONDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no default notification source file!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
			fi
		done
	fi
	if [ $NF = "1" ]; then
		NOTIFICATIONFILE=`ls`
		cp $DEFAULNOTIFICATIONDIR/$NOTIFICATIONFILE $SOUNDSDIR/notifications
		sed -i '/ro.config.notification_sound/s/=.*/='$NOTIFICATIONFILE' \\/' $BULIDFILE
		sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/notifications/'$NOTIFICATIONFILE':system/media/audio/notifications/'$NOTIFICATIONFILE' \\' $SOUNDSDIR/AudioPackage2.mk
		rm $DEFAULNOTIFICATIONDIR/$NOTIFICATIONFILE
	else
		echo "ERROR More than one audio file."
	fi
fi

#备选通知铃声
EXTRANOTIFICATION=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^备选通知铃声/)print $2}' $CONFILE`
EXTRANOTIFICATIONDIR=$CONFIGDIR/custom/备选通知铃声
if [ ! -z "$EXTRANOTIFICATION" ]; then
	echo ">>>>>Add extra notifications!!"
	cd $EXTRANOTIFICATIONDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		echo "no extra notification source file!!!"
		return
	fi
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				echo mv "$f" "$TARGET"
				cp $EXTRANOTIFICATIONDIR/$f $SOUNDSDIR/notifications
				sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/notifications/'$f':system/media/audio/notifications/'$f' \\' $SOUNDSDIR/AudioPackage2.mk
			fi
		done
	else
		for f in `ls ./`
		do
			cp $EXTRANOTIFICATIONDIR/$f $SOUNDSDIR/notifications
			sed -i '/^PRODUCT_COPY_FILES/a\	\$(LOCAL_PATH)/notifications/'$f':system/media/audio/notifications/'$f' \\' $SOUNDSDIR/AudioPackage2.mk
		done
	fi
	rm $EXTRANOTIFICATIONDIR/*
fi

echo "Begin to build your project?(y/n)"
read CMD
if [ $CMD = "y" ];then
	cd $SRCDIR
	echo "Build finish $(date +%Y-%m-%d %H:%M:%S)" >> $SRCDIR/修改记录.txt
	sed -i '/^[#,\/,[:blank:]]/!s/^/#/' $CONFILE
	./make_user_project.sh $PROJECT $1 new	
else
	git checkout -- ${CONFILE##*/}
	exit 1
fi

