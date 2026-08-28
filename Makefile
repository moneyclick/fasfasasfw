TARGET := iphone:clang:latest:14.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Sa1zyTikTokMod

Sa1zyTikTokMod_FILES = Tweak.x
Sa1zyTikTokMod_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
