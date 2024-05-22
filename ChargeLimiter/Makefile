export THEOS = /opt/theos
export THEOS_DEVICE_IP=127.0.0.1
export THEOS_DEVICE_PORT=22
ARCHS=arm64

_THEOS_PLATFORM_DPKG_DEB=dpkg-deb
THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
THEOS_PLATFORM_DEB_COMPRESSION_LEVEL=9

include $(THEOS)/makefiles/common.mk

TOOL_NAME = ChargeLimiter
${TOOL_NAME}_FILES = main.mm utils.mm
${TOOL_NAME}_CODESIGN_FLAGS = -SChargeLimiter.entitlements
${TOOL_NAME}_CFLAGS = -fobjc-arc -std=c++11 -Wno-objc-property-no-attribute -F/opt/framework
${TOOL_NAME}_LDFLAGS = -lz BackBoardServices.tbd -lz IOKit.tbd -lz GraphicsServices.tbd 
${TOOL_NAME}_LDFLAGS += -F/opt/framework -framework GCDWebServers -framework CoreServices -lxml2
${TOOL_NAME}_INSTALL_PATH = /Applications/ChargeLimiter.app

include $(THEOS_MAKE_PATH)/tool.mk
