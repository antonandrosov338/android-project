#!/bin/sh
#CONFIGURATION
LIBS=libs
PACKAGE=ru/notecode/application
FILES=src/java/$PACKAGE
RESOURCES=$FILES/res/

MANIFEST=$FILES/AndroidManifest.xml
ANDROID=$ANDROID_HOME/platforms/android-30/android.jar

mkdir -p bin/res bin/obj bin/apk bin/dex

#BUILD
aapt package -f -m -J bin/res/ -S $RESOURCES -M $MANIFEST -I $ANDROID && \

javac -source 1.8 -target 1.8 -bootclasspath $JAVA_HOME/jre/lib/rt.jar \
-classpath $ANDROID -d bin/obj/ bin/res/$PACKAGE/R.java $FILES/*.java && \

dx --dex --output=bin/dex/classes.dex bin/obj/ && \

#CREATE APKS
aapt package -f -M $MANIFEST -S $RESOURCES/ -I $ANDROID \
-F bin/apk/build.unsigned.apk bin/dex/ && \

zipalign -f -p 4 bin/apk/build.unsigned.apk bin/apk/build.align.apk && \

if ! [ -f bin/keystore.jks ]; then 
	keytool -genkeypair -keystore bin/keystore.jks -alias androidKey \
	-validity 10000 -keyalg RSA -keysize 2048 -storepass android -keypass android	
fi && \

apksigner sign --ks bin/keystore.jks --ks-key-alias androidKey --ks-pass pass:android \
--key-pass pass:android --out bin/apk/build.apk bin/apk/build.align.apk && \

#INSTALL
PACKAGE=`echo $PACKAGE | tr '/' '.'` && \

adb devices && \
adb install -r bin/apk/build.apk && \
adb shell am start -a -S $PACKAGE/.MainActivity && \

exit 0