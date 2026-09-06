TARGET_ARCH    = arm64
SDK            = $(THEOS)/sdks/iPhoneOS16.5.sdk
THEOS_DEVICE_IP =

TWEAK_NAME     = FFNET_IOS
FFNET_IOS_FILES = src/main.mm \
                  src/Bypass/Bypass.mm \
                  src/Bypass/AntiCheatBypass.mm \
                  src/Bypass/IntegrityBypass.mm \
                  src/Features/Aimbot.mm \
                  src/Features/ESP.mm \
                  src/Menu/Menu.mm

FFNET_IOS_FRAMEWORKS  = UIKit CoreGraphics Foundation Security
FFNET_IOS_LIBRARIES   = substrate
FFNET_IOS_CFLAGS      = -fobjc-arc -O2 -std=c++17 \
                         -Isrc/Utils -Isrc/Features -Isrc/Bypass -Isrc/Menu

include $(THEOS)/makefiles/tweak.mk
