#ifndef common_h
#define common_h

#include <arpa/inet.h>
#include <dlfcn.h>
#include <ifaddrs.h>
#include <objc/runtime.h>
#include <spawn.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#import <os/log.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define PRODUCT         "ChargeLimiter"
#define GSERV_PORT      1230
#define TRACE           false
#define FLOAT_ORIGINX   100
#define FLOAT_ORIGINY   100
#define FLOAT_WIDTH     80
#define FLOAT_HEIGHT    60

#define LOG_PATH        "/var/root/aldente.log"
#define CONF_PATH       "/var/root/aldente.conf"
#define DB_PATH         "/var/root/aldente.db"

extern NSString*        log_prefix;

#endif // common_h

