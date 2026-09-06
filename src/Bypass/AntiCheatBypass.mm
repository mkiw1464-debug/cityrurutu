// ECA + Unity AntiCheat layer bypass
#import "AntiCheatBypass.h"
#import "../Utils/Memory.h"
#import "../Utils/Il2cpp.h"
#import <substrate.h>

// Hook NSUserDefaults to hide cheat presence from AC telemetry
static NSDictionary* (*orig_dictionaryRepresentation)(id, SEL);
static NSDictionary* hook_dictionaryRepresentation(id self, SEL sel) {
    NSMutableDictionary* d = [orig_dictionaryRepresentation(self, sel) mutableCopy];
    // Remove any keys AC module might read
    NSArray* strip = @[@"ffnet_aimbot", @"ffnet_esp", @"ffnet_silent",
                       @"cheat", @"hack", @"mod"];
    for (NSString* k in strip) [d removeObjectForKey:k];
    return d;
}

// Hook NSBundle to spoof bundle ID  
static NSString* (*orig_bundleIdentifier)(id, SEL);
static NSString* hook_bundleIdentifier(id self, SEL sel) {
    return @"com.dts.freefireth"; // always return legit bundle ID
}

void AntiCheatBypass::init() {
    MSHookMessageEx([NSUserDefaults class],
        @selector(dictionaryRepresentation),
        (IMP)hook_dictionaryRepresentation,
        (IMP*)&orig_dictionaryRepresentation);
    
    MSHookMessageEx([NSBundle class],
        @selector(bundleIdentifier),
        (IMP)hook_bundleIdentifier,
        (IMP*)&orig_bundleIdentifier);
}
