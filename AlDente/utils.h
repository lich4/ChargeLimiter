#include <arpa/inet.h>
#include <dlfcn.h>
#include <ifaddrs.h>
#include <spawn.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#import <Foundation/Foundation.h>

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString* bundleIdentifier;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;
@end


enum {
    SPAWN_FLAG_ROOT     = 1,
    SPAWN_FLAG_NOWAIT   = 2,
};
int spawn(NSArray* args, NSString** stdOut, NSString** stdErr, pid_t* pidPtr, int flag);

int platformize_me();
BOOL localPortOpen(int port);
NSString* getAppEXEPath();
void runAsDaemon(void(^Block)(), int flag=0);

