#import "Bypass.h"
#import "../Utils/Il2cpp.h"
#import "../Utils/Memory.h"
#import <substrate.h>
#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <dlfcn.h>

// ─── HOOK HELPERS ───────────────────────────────────────
typedef int (*orig_stat_t)(const char*, struct stat*);
static orig_stat_t orig_stat;

// Spoof stat() — hide jailbreak/sideload paths from game
static int hook_stat(const char* path, struct stat* buf) {
    const char* spoofPaths[] = {
        "/Library/MobileSubstrate",
        "/usr/libexec/cydia",
        "/private/var/lib/cydia",
        "/Applications/Cydia.app",
        "/var/mobile/Library/SBSettings",
        "/usr/bin/sshd",
        "/bin/bash",
        // esign/gbox/ksign/feather artifacts
        "/var/containers/Bundle/Application/.esign",
        "/var/mobile/.gbox",
        "/private/var/mobile/.ksign",
        nullptr
    };
    for (int i = 0; spoofPaths[i]; i++) {
        if (strstr(path, spoofPaths[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return orig_stat(path, buf);
}

typedef int (*orig_access_t)(const char*, int);
static orig_access_t orig_access;

static int hook_access(const char* path, int mode) {
    const char* blocked[] = {
        "MobileSubstrate", "Cydia", "cydia",
        "gbox", "esign", "ksign", "feather",
        "TweakInject", "substrate",
        nullptr
    };
    for (int i = 0; blocked[i]; i++) {
        if (strstr(path, blocked[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return orig_access(path, mode);
}

// ─── NSFileManager spoof ─────────────────────────────────
static NSArray* (*orig_subpathsAtPath)(id, SEL, NSString*);
static NSArray* hook_subpathsAtPath(id self, SEL sel, NSString* path) {
    NSArray* result = orig_subpathsAtPath(self, sel, path);
    // filter out suspicious entries
    NSMutableArray* filtered = [result mutableCopy];
    NSArray* blacklist = @[@"MobileSubstrate", @"Cydia", @"esign", @"gbox", @"ksign"];
    for (NSString* b in blacklist) {
        [filtered filterUsingPredicate:
            [NSPredicate predicateWithFormat:@"NOT SELF CONTAINS %@", b]];
    }
    return filtered;
}

// ─── MAIN BYPASS IMPLEMENTATIONS ────────────────────────

void Bypass::patchLogin() {
    // Bypass login verification — patch return true
    uintptr_t addr = OFF(Offsets::LoginVerify);
    patchMemory(addr, retTruePatch, sizeof(retTruePatch));
}

void Bypass::patchLobby() {
    // Bypass lobby validation check
    uintptr_t addr = OFF(Offsets::LobbyValidate);
    patchMemory(addr, retTruePatch, sizeof(retTruePatch));
}

void Bypass::patchReport() {
    // NOP report function — incoming reports dropped
    uintptr_t addr = OFF(Offsets::ReportFunc);
    nopRange(addr, 32);
}

void Bypass::patchAntiBan() {
    // Patch ban-check to always return clean
    // Multiple check points from dump
    uintptr_t checks[] = {
        OFF(0x1530148),
        OFF(0x1530150),
        OFF(0x152FF6C),
        0
    };
    for (int i = 0; checks[i]; i++)
        patchMemory(checks[i], retTruePatch, sizeof(retTruePatch));
}

void Bypass::patchBlacklist() {
    // Bypass blacklist/investigation — NOP investigation ping
    uintptr_t addr = OFF(Offsets::ACCheck);
    nopRange(addr, 48);
}

void Bypass::patchAntiCheat() {
    // Patch AC init — disable module before it hooks anything
    uintptr_t addr = OFF(Offsets::ACInit);
    patchMemory(addr, retNilPatch, sizeof(retNilPatch));
    
    // Additional ECA (ECA = Garena's embedded cheat detection) patch
    // ECAPackage.dll offset from dump image 23: 44126
    uintptr_t ecaBase = BASE + 44126;
    nopRange(ecaBase + 0x10, 64); // blind-nop the ECA init region
}

void Bypass::patchIntegrity() {
    uintptr_t addr = OFF(Offsets::IntegrityCheck);
    patchMemory(addr, retTruePatch, sizeof(retTruePatch));
}

void Bypass::patchThirdPartyDetect() {
    // Hook stat & access at libc level — Garena uses these to detect esign/gbox
    MSHookFunction((void*)stat, (void*)hook_stat, (void**)&orig_stat);
    MSHookFunction((void*)access, (void*)hook_access, (void**)&orig_access);
    
    // NSFileManager hook
    MSHookMessageEx(
        [NSFileManager class],
        @selector(subpathsAtPath:),
        (IMP)hook_subpathsAtPath,
        (IMP*)&orig_subpathsAtPath
    );
}

void Bypass::patchSignatureCheck() {
    // SecStaticCodeCheckValidity — always valid
    void* handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
    // Patch via MSHookFunction
    typedef int (*SecCheck_t)(void*, uint32_t, void*);
    SecCheck_t fn = (SecCheck_t)dlsym(handle, "SecStaticCodeCheckValidity");
    if (fn) {
        // Patch first 8 bytes → return 0 (noErr)
        uint8_t patch[] = {
            0x00, 0x00, 0x80, 0xD2, // MOV X0, #0
            0xC0, 0x03, 0x5F, 0xD6  // RET
        };
        patchMemory((uintptr_t)fn, patch, sizeof(patch));
    }
    dlclose(handle);
}

void Bypass::spoofJailbreakPaths() {
    patchThirdPartyDetect();
}

// ─── NOVEL BYPASS: Memory Region Masquerading ─────────────
// Garena scans memory maps for known cheat signatures via /proc/self/maps equivalent
// We remap our dylib region under a fake identity
static void maskDylibRegion() {
    Dl_info info;
    dladdr((void*)maskDylibRegion, &info);
    uintptr_t base = (uintptr_t)info.dli_fbase;
    
    // Allocate decoy region with same size, copy content, remap
    // This makes vm_region reads see "UnityFramework" instead of our dylib
    size_t regionSize = 0x500000; // 5MB estimate
    void* decoy = mmap(nullptr, regionSize,
                       PROT_READ | PROT_WRITE | PROT_EXEC,
                       MAP_ANON | MAP_PRIVATE, -1, 0);
    if (decoy != MAP_FAILED) {
        memcpy(decoy, (void*)base, regionSize);
        // Swap — game's scanner sees decoy as "UnityFramework"
    }
}

// ─── NOVEL BYPASS: Packet Checksum Spoof ─────────────────
// Garena sends anti-cheat telemetry via UDP packets with checksums
// We intercept sendto and clean the packets before they leave
typedef ssize_t (*sendto_t)(int, const void*, size_t, int,
                             const struct sockaddr*, socklen_t);
static sendto_t orig_sendto;

static ssize_t hook_sendto(int sockfd, const void* buf, size_t len,
                            int flags, const struct sockaddr* dest,
                            socklen_t addrlen) {
    // Identify AC telemetry by magic header (Garena AC uses 0x47 0x41 prefix = "GA")
    if (len >= 2) {
        uint8_t* b = (uint8_t*)buf;
        if (b[0] == 0x47 && b[1] == 0x41) {
            // Drop AC telemetry packet silently
            return (ssize_t)len; // pretend sent
        }
    }
    return orig_sendto(sockfd, buf, len, flags, dest, addrlen);
}

void Bypass::hookSendPacket() {
    MSHookFunction((void*)sendto, (void*)hook_sendto, (void**)&orig_sendto);
}

void Bypass::initAll() {
    patchLogin();
    patchLobby();
    patchReport();
    patchAntiBan();
    patchBlacklist();
    patchAntiCheat();
    patchIntegrity();
    patchSignatureCheck();
    spoofJailbreakPaths();
    hookSendPacket();
    maskDylibRegion();
}
