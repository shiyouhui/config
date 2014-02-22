#!/bin/bash
###################################################################################################################################################################################################
if [ $# != 1 ];then
	echo "fatal: usage( ./do MR7063HC8W1 )"
	exit 1
fi

if [ ! -e alps ];then
	echo "Please return outside of alps floder exec!!!"
	exit 1
fi
###################################################################################################################################################################################################
#全局变量设定
PROJECT=`expr substr $1 1 5 |tr '[A-Z]' '[a-z]'`
DENSITY=`expr substr $1 7 1`
CONFIGDIR=~/config
SRCDIR=$PWD/alps
CONFILE=$CONFIGDIR/config.ini
PATCHDIR=$CONFIGDIR/patch
OK='\e[0;32m'
ERROR='\e[1;31m'
END='\e[0m'

cd $SRCDIR/system/vold/
BRANCH=`git branch | awk '{if(match($1,"*")){print $2}}'`
cd - >/dev/null
if [ ! -e PATCH/$BRANCH ];then
	mkdir -p PATCH/$BRANCH
fi

RECORDFILE=$PWD/PATCH/$BRANCH/record.txt
PROFILE=$SRCDIR/mediatek/config/$PROJECT/elink/$1
COMMONPROFILE=$SRCDIR/mediatek/config/common
CUSTOMCONF=$SRCDIR/mediatek/config/common/custom.conf
DEFAULTXML=$SRCDIR/frameworks/base/packages/SettingsProvider/res/values/defaults.xml
BULIDFILE=$SRCDIR/build/target/product/core.mk
SOUNDSDIR=$SRCDIR/frameworks/base/data/sounds

ERROR()
{
	echo -e  "${ERROR} $1 ${END}"
}

OK()
{
	echo -e  "${OK} $1 ${END}"
}

###################################################################################################################################################################################################
#生成修改记录
if [ -e RECORDFILE ];then
	LASTTIME=`ls -l $RECORDFILE | awk '{printf("%s %s", $6, $7);}'` 
	SECOND_OLD=`date --date="$LASTTIME" +%s`
	SECOND_NEW=$(date +%s)
	HOUR=`echo "($SECOND_NEW - $SECOND_OLD)/3600" | bc`
else
	HOUR=0
fi

if [  $HOUR -gt 4 ];then
	ISNEW=true
	if [ -e $RECORDFILE ];then
		rm $RECORDFILE
	fi
	touch $RECORDFILE
	DATE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/需求日期/)print $2}' $CONFILE`
	if [ "$DATE" = "请输入" ];then
		echo "\n需求日期:$(date +%Y%m%d)" > $RECORDFILE	
	else
		echo "\n需求日期:$DATE" > $RECORDFILE	
	fi
else
	ISNEW=false
fi
echo "编译机型:$1\n" >> $RECORDFILE
###################################################################################################################################################################################################
#修改机型名
MODELNAME=`awk -F"=" '{if(/^机型名称/)print $2}' $CONFILE`
if [ ! -z "$MODELNAME" ];then
	OK ">>>>>Configurate Model Name = $MODELNAME"
	sed -i "/^PRODUCT_MODEL/s/=.*/=$MODELNAME/" $PROFILE/elink_ID.mk
	echo "修改机型名:$MODELNAME\n" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改蓝牙名称
BLUETOOTHNAME=`awk -F"=" '{if(/^蓝牙名称/)print $2}' $CONFILE`
if [ ! -z "$BLUETOOTHNAME" ];then
	OK ">>>>>Configurate Bluetooth Name = $BLUETOOTHNAME "
	sed -i "/^bluetooth/s/=.*/=$BLUETOOTHNAME/" $CUSTOMCONF
	echo "修改蓝牙名称:$BLUETOOTHNAME" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改Wifi共享热点SSID
WLANSSID=`awk -F"=" '{if(/^共享SSID名称/)print $2}' $CONFILE`
if [ ! -z "$WLANSSID" ];then
	OK " >>>>>Configurate WLAN_SSID Display Label = $WLANSSID "
	sed -i "/^wlan.SSID/s/=.*/=$WLANSSID/" $CUSTOMCONF
	echo "修改Wifi共享热点SSID:$WLANSSID" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改编译版本
BUILDVERSION=`awk -F"=" '{if(/^编译版本/)print $2}' $CONFILE`
if [ ! -z "$BUILDVERSION" ];then
	OK " >>>>>Configurate Build version = $BUILDVERSION  "
	sed -i "/^ELINK_VERSION/s/=.*/=$BUILDVERSION/" $PROFILE/elink_ID.mk
	echo "修改编译版本:$BUILDVERSION" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改自定义编译版本
CUSTOMBUILDVERSION=`awk -F"=" '{if(/^自定义编译版本/)print $2}' $CONFILE`
if [ ! -z "$CUSTOMBUILDVERSION" ];then
	OK " >>>>>Configurate Customer build version = $CUSTOMBUILDVERSION  "
	sed -i "/^CUSTOM_BUILD_VERNO/s/=.*/=$CUSTOMBUILDVERSION/" $SRCDIR/mediatek/config/common/ProjectConfig.mk
	echo "修改自定义编译版本:$CUSTOMBUILDVERSION" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改时区
TIMEZONE=`awk -F"=" 'gsub(/\//,"\\\/"){if(/^时区/)print $2}' $CONFILE`
if [ ! -z "$TIMEZONE" ];then
	OK " >>>>>Configurate Timezone = $TIMEZONE  "
	sed -i "/^persist.sys.timezone/s/=.*/=$TIMEZONE/" $PROFILE/system.prop
	echo "修改时区:"`awk -F"=" '{if(/^时区/)print $2}' $CONFILE` >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改默认亮度
BRIGHTNESS=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认亮度/)print $2}' $CONFILE`
if [ ! -z "$BRIGHTNESS" ];then
	OK " >>>>>Configurate Screen brightness = $BRIGHTNESS  "
	sed -i "/\"def_screen_brightness\"/s/>.*</>$BRIGHTNESS</" $DEFAULTXML
	echo "修改默认亮度:$BRIGHTNESS" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改屏幕延时
SCREENTIMEOUT=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^屏幕延时/)print $2}' $CONFILE`
if [ ! -z "$SCREENTIMEOUT" ];then
	OK " >>>>>Configurate screen timeout = $SCREENTIMEOUT  "
	sed -i "/\"def_screen_off_timeout\"/s/>.*</>$SCREENTIMEOUT</" $DEFAULTXML
	echo "修改屏幕延时:$(expr $SCREENTIMEOUT \/ 1000)秒" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改未知来源默认
UNKNOWSRC=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^未知来源/)print $2}' $CONFILE`
if [ ! -z "$UNKNOWSRC" ];then
	OK " >>>>>Unkownsource selected = $UNKNOWSRC"
	sed -i "/\"def_install_non_market_apps\"/s/>.*</>$UNKNOWSRC</" $DEFAULTXML
	echo "默认打开未知来源选项" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改默认输入法
INPUTMETHOD=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认输入法/)print $2}' $CONFILE`
if [ ! -z "$INPUTMETHOD" ];then
	OK " >>>>>Modify default input_method = $INPUTMETHOD  "
	sed -i "/^DEFAULT_INPUT_METHOD/s/=.*/=$INPUTMETHOD/" $PROFILE/ProjectConfig.mk
	echo "修改默认输入法:$INPUTMETHOD" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改可移动磁盘名
DISKLABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^可移动磁盘/)print $2}' $CONFILE`
if [ ! -z "$DISKLABEL" ];then
	OK " >>>>>Modify disk = $DISKLABEL "
	cd $SRCDIR/system/core
	

	PRO=`expr substr $PROJECT 1 2`
	if [ $PRO = "md" ];then
		git apply --ignore-whitespace $PATCHDIR/lowcase.patch  
		cd ../vold
		git  apply --ignore-whitespace $PATCHDIR/parttion_label.patch 
	elif [ $PRO = "mr" ]; then
		git apply --ignore-whitespace $PATCHDIR/mr_lowcase.patch  
		cd ../vold
		git  apply --ignore-whitespace $PATCHDIR/mr_parttion_label.patch 
	fi

	sed -i "/display label/s/\".*\"/\"$DISKLABEL\"/" ./Fat.cpp 
	cd $CONFIGDIR
	echo "修改可移动磁盘名:$DISKLABEL" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改联机ID
ONLINELABEL=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^联机ID/)print $2}' $CONFILE`
if [ ! -z "$ONLINELABEL" ];then
	OK " >>>>>Modify online_id = $ONLINELABEL "
	cd $SRCDIR/kernel/drivers

	PRO=`expr substr $PROJECT 1 2`
	if [ $PRO = "md" ];then
		git apply --ignore-whitespace $PATCHDIR/usbid_label.patch
	elif [ $PRO = "mr" ]; then
		git apply --ignore-whitespace $PATCHDIR/mr_usbid_label.patch
	fi

	
	sed -i "/id display label1/s/\".*\"/\"$ONLINELABEL\"/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
	sed -i "/id display label2/s/\".*\"/\"$ONLINELABEL\"/" $SRCDIR/kernel/drivers/usb/gadget/f_mass_storage.c
	cd $CONFIGDIR
	echo "修改联机ID:$ONLINELABEL" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改浏览器主页
HOMEPAGE=`awk -F"=" 'gsub(/\//,"\\\/")sub(/^[[:blank:]]*/,"",$2){if(/^浏览器主页/)print $2}' $CONFILE`
if [ ! -z "$HOMEPAGE" ];then
	OK " >>>>>Modify default Browse Homepage = `expr substr $HOMEPAGE 10 20` "
	cd $SRCDIR/packages/apps/Browser
	git apply --ignore-whitespace $PATCHDIR/homepage.patch
	sed -i "/default homepage/s/,.*);/,\"$HOMEPAGE\");/" $SRCDIR/packages/apps/Browser/src/com/android/browser/BrowserSettings.java
	cd $CONFIGDIR
	echo "修改浏览器主页:$HOMEPAGE" >> $RECORDFILE
fi
###################################################################################################################################################################################################
# MD77修改前摄像头插值
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
	echo "修改前摄像头插值:$SUBCAMERA" >> $RECORDFILE
fi
###################################################################################################################################################################################################
# MD77修改后摄像头插值
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
	echo "修改后摄像头插值:$MAINCAMERA" >> $RECORDFILE
fi
###################################################################################################################################################################################################
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

	OK " >>>>>Modify Audio profile = $ACTIVEPROFILE  "
	sed -i "/\"def_active_profile\"/s/>.*</>$RESULT</" $SRCDIR/frameworks/base/packages/SettingsProvider/res/values/mtk_defaults.xml
	echo "修改默认情景模式:$ACTIVEPROFILE" >> $RECORDFILE
fi
###################################################################################################################################################################################################
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
		OK " >>>>>begin to make bootanimation "
		cd $BOOTANIMATIONDIR
		RESULT=bootanimation
		TIMES=$BOOTTIMES
	elif [ $1 = "shut" ];then
		OK " >>>>>begin to make shutanimation "
		cd $SHUTANIMATIONDIR
		RESULT=shutanimation
		TIMES=$SHUTTIMES
	fi

	FILES=`ls | sort -n`
	NF=`ls -l | grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		OK "${ERROR} no animation source picture!!! "
		return
	fi

	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK " mv "$f" "$TARGET" "
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
			OK " mv $i $RESULT/part0/${NAME}.$EXTENSION "
			mv $i $RESULT/part0/${NAME}.$EXTENSION
			if [ "$EXTENSION" != "png" -a "$EXTENSION" != "PNG" ];then
				convert $RESULT/part0/${NAME}.$EXTENSION $RESULT/part0/${NAME}.png
				rm $RESULT/part0/${NAME}.$EXTENSION
			fi
		done
		mkdir -p $RESULT/part1
		cp $RESULT/part0/${NAME}.* $RESULT/part1/
		OK " mv $RESULT/part0/${NAME}.png $RESULT/part1/ "
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
			OK " mv $i $RESULT/part$k/${NAME}.$EXTENSION "
			mv $i $RESULT/part$k/${NAME}.$EXTENSION
	
			if [ "$EXTENSION" != "png" -a "$EXTENSION" != "PNG" ];then
				convert $RESULT/part$k/${NAME}.$EXTENSION $RESULT/part$k/${NAME}.png
				rm $RESULT/part$k/${NAME}.$EXTENSION
			fi
		done
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
	OK " make $RESULT successfully ===========> OK "
	cd $CONFIGDIR
}
###################################################################################################################################################################################################
#开机动画
if [ ! -z "$BOOTANIMATION" ];then
	makeanimation boot;
	echo "制作开机动画" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#关机动画
if [ ! -z "$SHUTANIMATION" ];then
	makeanimation shut;
	echo "制作关机动画" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#制作开机logo
UBOOTLOGODIR=$CONFIGDIR/custom/第一屏
KERNELLOGODIR=$CONFIGDIR/custom/第二屏
HASUBOOTLOGO=`ls $CONFIGDIR/custom/第一屏 | wc -l `
HASKERNELLOGO=`ls $CONFIGDIR/custom/第二屏 | wc -l `
makelogo()
{
	if [ $1 = "uboot" ];then
		OK " >>>>>begin to make uboot logo "
		cd $UBOOTLOGODIR
	elif [ $1 = "kernel" ];then
		OK " >>>>>begin to make kernel logo "
		cd $KERNELLOGODIR
	fi

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK " mv 	"$f" "$TARGET" "
			fi
		done
	fi

	if [ $PROJECT = "md706" -o $PROJECT = "md708" -o $PROJECT = "mr706" -o $PROJECT = "mr650" ];then
		if [ $DENSITY = "L" ];then
			if [ $PROJECT = "mr706" -o $PROJECT = "mr650" ];then
				convert * wvga_$1.bmp
				cp -p wvga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wvga/
			else	
				convert * cu_wvga_$1.bmp
				cp -p cu_wvga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/cu_wvga/
			fi
		elif [ $DENSITY = "H" ];then  
			convert * wsvga_$1.bmp
			cp -p wsvga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wsvga/
		fi
	elif [ $PROJECT = "md790" -o $PROJECT = "mr790" -o $PROJECT = "mq790" ];then 
			convert * xga_$1.bmp
			cp -p xga_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/xga/
	elif [ $PROJECT = "md601" -o $PROJECT = "md680" -o $PROJECT = "mr601" ];then
			convert * cu_qhd_$1.bmp
			cp -p cu_qhd_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/cu_qhd/
	elif [ $PROJECT = "md900" -o $PROJECT = "md100" -o $PROJECT = "mr900" -o $PROJECT = "mr100" ];then
		if [ $DENSITY = "L" ];then
			convert * wvgalnl_$1.bmp
			cp -p wvgalnl_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wvgalnl/
		elif [ $DENSITY = "H" ];then  
			convert * wsvganl_$1.bmp
			cp -p wsvganl_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/wsvganl/
		fi
	elif [ $PROJECT = "mr970" -o $PROJECT = "mq970" ];then
		if [ $DENSITY = "L" ];then
			convert * xganl_$1.bmp
			cp -p xganl_$1.bmp $SRCDIR/mediatek/custom/common/lk/logo/xganl/
		fi
	fi
	rm *
	OK " make $1 logo  successfully ===========> OK "
	cd $CONFIGDIR
}
###################################################################################################################################################################################################
#开机第一屏logo
if [ "$HASUBOOTLOGO" -gt 0 ];then
	makelogo uboot
	echo "修改logo1" >> $RECORDFILE
fi


###################################################################################################################################################################################################
#开机第二屏logo
if [ "$HASKERNELLOGO" -gt 0  ];then
	makelogo kernel
	echo "修改logo2" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#修改默认壁纸
HASWALLPAPER=`ls $CONFIGDIR/custom/默认桌面壁纸 | wc -l `
WALLPAPERDIR=$CONFIGDIR/custom/默认桌面壁纸
if [ "$HASWALLPAPER" -gt 0  ];then
	OK " >>>>>Change default wallpaper!! "
	cd $WALLPAPERDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
					mv "$f" "$TARGET"
					OK " mv "$f" "$TARGET" "
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
	OK " Change default  wallpaper  successfully ===========> OK "
	cd $SRCDIR
	echo "修改默认壁纸" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#预置APK
APKHANDLE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^预置APK/)print $2}' $CONFILE`
APKDIR=$CONFIGDIR/custom/预置APK
DATAAPPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app
SYSTEMAPPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/app
BACKUPDIR=$SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/system/appbackup
if [ ! -z "$APKHANDLE" ];then
	OK " >>>>>begin copy customer apk to android soruce!! "
	cd $APKDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	if [ -z "$FILES" ];then
		OK "${ERROR} NO apk file!!! "
		return
	fi
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr -d ' '`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK " mv "$f" "$TARGET" "
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
			OK " copy $i to app "
			cp -p $i $DATAAPPDIR
			OK " copy $i to appbackup "
			cp -p $i $BACKUPDIR
			echo "/data/app/$i" >> $DATAAPPDIR/.keep_list
			echo "/system/appbackup/$i" >> $SYSTEMAPPDIR/.restore_list
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(可卸载可恢复)" >> $RECORDFILE

	elif [ "$APKHANDLE" -eq "2" ];then
		for i in `ls`
		do
			OK " copy $i to system_app "
			APKNAME=${i%\.*}
			mkdir -p  $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME
			cp -p $i $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/
			cp -p $PATCHDIR/Android.mk $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/
			sed -i "/LOCAL_MODULE :=/s/:=.*/:= $APKNAME/" $SRCDIR/vendor/common/SYSTEM_APP/$APKNAME/Android.mk
			sed -i '/ElinkEng.*/s/^/    '$APKNAME' \\\n/' $SRCDIR/vendor/common/SYSTEM_APP/products/APPS.mk
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(不可卸载)" >> $RECORDFILE
	elif [ "$APKHANDLE" -eq "3" ];then
		echo "copy $i to app"
		for i in `ls`
		do
			OK " copy $i to app "
			cp -p $i $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app/
			echo "/data/app/$i" >> $SRCDIR/vendor/mediatek/$PROJECT/artifacts/out/target/product/$PROJECT/data/app/.keep_list
		done
		rm * -r
		cd $CONFIGDIR
		echo "预置APK(可卸载不可恢复)" >> $RECORDFILE
	else
		OK "${ERROE} ERROE:error apk handle!!!! "
		return
	fi

fi
###################################################################################################################################################################################################
#添加壁纸
HASEXTRAWALLPAPER=`ls $CONFIGDIR/custom/备选壁纸 | wc -l `
EXTRAWALLPAPERDIR=$CONFIGDIR/custom/备选壁纸
if [ "$HASEXTRAWALLPAPER" -gt 0 ];then
	OK " >>>>>begin copy extra wallpaper!! "
	cd $EXTRAWALLPAPERDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
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
		echo  -e " mv "$f" wallpaper_extra_$INDEX.$EXTENSION "
		convert -resize 213x189 wallpaper_extra_"$INDEX"."$EXTENSION" wallpaper_extra_"$INDEX"_small.$EXTENSION
		cp  wallpaper_extra_"$INDEX"."$EXTENSION" $SRCDIR/packages/apps/Launcher2/res/drawable-nodpi/
		cp  wallpaper_extra_"$INDEX"_small.$EXTENSION $SRCDIR/packages/apps/Launcher2/res/drawable-nodpi/
		PRO=`expr substr $PROJECT 1 2`
		MODEL=`expr substr $PROJECT 3 3`
		if [ $PRO = "md" ];then
			sed -i "/wallpapers/s/$/\n        <item>wallpaper_extra_$INDEX<\/item>/" $SRCDIR/packages/apps/Launcher2/res/values/wallpapers.xml
		elif [ $PRO = "mr" ]; then
			if [ $MODEL = "706" ];then
				sed -i "/wallpapers/s/$/\n        <item>wallpaper_extra_$INDEX<\/item>/" $SRCDIR/packages/apps/Launcher2/res/values-sw600dp/wallpapers.xml
			elif [ $MODEL = "790" ];then 
				sed -i "/wallpapers/s/$/\n        <item>wallpaper_extra_$INDEX<\/item>/" $SRCDIR/packages/apps/Launcher2/res/values-sw720dp/wallpapers.xml
			fi
		fi
		INDEX=`expr $INDEX + 1` 
	done
	rm * -r
	cd $CONFIGDIR
	echo "预置壁纸:$NF张" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#默认语言
LANGUAGE=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^默认语言/)print $2}' $CONFILE`
if [ ! -z "$LANGUAGE" ];then
	OK " >>>>>default Language = $LANGUAGE "
	sed -i "/DEFAULT_LATIN_IME_LANGUAGES/s/=.*/=$LANGUAGE/" $PROFILE/ProjectConfig.mk
	sed -i "/MTK_PRODUCT_LOCALES/s/$LANGUAGE//" $PROFILE/ProjectConfig.mk
	sed -i "/MTK_PRODUCT_LOCALES/s/=/=$LANGUAGE /" $PROFILE/ProjectConfig.mk
	echo "修改默认语言:$LANGUAGE" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#开启ROOT权限
OPENROOT=`awk -F"=" 'sub(/^[[:blank:]]*/,"",$2){if(/^开启ROOT权限/)print $2}' $CONFILE`
if [ ! -z "$OPENROOT" ]; then
	OK " >>>>>Open root permission "
	sed -i "/^EK_ROOT_SUPPORT/s/=.*/=$OPENROOT/" $COMMONPROFILE/ProjectConfig.mk
	echo "开启ROOT权限" >> $RECORDFILE
fi
###################################################################################################################################################################################################
#默认来电铃声
HASDEFAULTRINGTONE=`ls $CONFIGDIR/custom/默认来电铃声 | wc -l `
DEFAULTRINGTONEDIR=$CONFIGDIR/custom/默认来电铃声
if [ "$HASDEFAULTRINGTONE" -gt 0 ]; then
	OK " >>>>>Change default ringtone!! "
	cd $DEFAULTRINGTONEDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		echo "Rename because any filename has blank!!!"
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK " mv "$f" "$TARGET" "
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
		echo  -e "${ERROR}  More than one audio file. "
	fi
fi
###################################################################################################################################################################################################
#备选来电铃声
HASEXTRARINGTONE=`ls $CONFIGDIR/custom/备选来电铃声 | wc -l `
EXTRARINGTONEDIR=$CONFIGDIR/custom/备选来电铃声
if [ "$HASEXTRARINGTONE" -gt 0 ]; then
	OK " >>>>>Add extra ringtone!! "
	cd $EXTRARINGTONEDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		echo  -e " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK "  mv "$f" "$TARGET" "
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
###################################################################################################################################################################################################
#默认通知铃声
HASDEFAULNOTIFICATIONE=`ls $CONFIGDIR/custom/默认通知铃声 | wc -l `
DEFAULNOTIFICATIONDIR=$CONFIGDIR/custom/默认通知铃声
if [ "$HASDEFAULNOTIFICATIONE" -gt 0 ]; then
	OK " >>>>>Change default notifications!! "
	cd $DEFAULNOTIFICATIONDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
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
		OK "${ERROR} ERROR More than one audio file.  "
	fi
fi
###################################################################################################################################################################################################
#备选通知铃声
HASEXTRANOTIFICATION=`ls $CONFIGDIR/custom/备选通知铃声 | wc -l `
EXTRANOTIFICATIONDIR=$CONFIGDIR/custom/备选通知铃声
if [ "$HASEXTRANOTIFICATION" -gt 0 ]; then
	OK " >>>>>Add extra notifications!!  "
	cd $EXTRANOTIFICATIONDIR

	FILES=`ls`
	NF=`ls -l |grep "^-"|wc -l`
	FNF=`echo $FILES | awk '{print NF}'`
	
	if [  $NF -ne $FNF ];then	
		OK " Rename because any filename has blank!!! "
		for f in `ls ./ | tr " " "\?"`
		do
			TARGET=`echo "$f" | tr " " "_"`
			if [ "$f" != "$TARGET" ];then
				mv "$f" "$TARGET"
				OK " mv "$f" "$TARGET" "
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


cd $CONFIGDIR
OK "===============================>>out $RECORDFILE "
git checkout -- config.ini

