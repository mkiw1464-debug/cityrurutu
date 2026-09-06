#import <substrate.h>
#import <Foundation/Foundation.h>
#import "Bypass/Bypass.h"
#import "Bypass/AntiCheatBypass.h"
#import "Bypass/IntegrityBypass.h"
#import "Menu/GlassUI.h"
#import "../Utils/Config.h"

static void initFFNET() {
    // 1. All bypasses — first, before anything else loads
    Bypass::initAll();
    AntiCheatBypass::init();
    IntegrityBypass::init();
    
    // 2. Load saved config
    Config::get().load();
    
    // 3. Spin up menu on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [GlassMenuWindow shared]; // init singleton + display
        NSLog(@"[FFNET] %s loaded | com.dts.freefireth OB54", DYLIB_VERSION);
    });
}

__attribute__((constructor))
static void ctor() {
    // Delay slightly so the game binary is fully mapped
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        initFFNET();
    });
}
