#pragma once
#include <stdint.h>
#include <string>
#include <dlfcn.h>
#include <mach-o/dyld.h>

static uintptr_t getBase() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, "UnityFramework") || strstr(name, "GameAssembly")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

#define BASE getBase()
#define OFF(x) (BASE + x)

template<typename T>
T Read(uintptr_t addr) {
    return *(T*)addr;
}

template<typename T>
void Write(uintptr_t addr, T val) {
    *(T*)addr = val;
}

// OB54 offsets dari dump
namespace Offsets {
    // Player
    static const uintptr_t LocalPlayer     = 0x152FF64; // adjust from dump
    static const uintptr_t PlayerManager   = 0x1530048;
    static const uintptr_t PlayerList      = 0x1530144;
    static const uintptr_t PlayerHP        = 0x1530150;
    static const uintptr_t PlayerPosition  = 0x15301B8;
    static const uintptr_t PlayerBone      = 0x15304C4;
    static const uintptr_t PlayerName      = 0x1530128;
    static const uintptr_t IsEnemy         = 0x20;
    static const uintptr_t TeamID          = 0x24;
    
    // Aimbot
    static const uintptr_t BulletSpeed     = 0x729F8E8;
    static const uintptr_t AimAngle        = 0x729F474;
    static const uintptr_t FireControl     = 0x729F970;
    
    // Camera
    static const uintptr_t Camera          = 0x729F9FC;
    static const uintptr_t ViewMatrix      = 0x729F4DC;
    
    // AntiCheat hooks target
    static const uintptr_t ACInit          = 0x152FF6C;
    static const uintptr_t ACCheck        = 0x1530148;
    static const uintptr_t ReportFunc     = 0x152FF74;
    static const uintptr_t LoginVerify    = 0x729F480;
    static const uintptr_t IntegrityCheck = 0x729F488;
    static const uintptr_t LobbyValidate  = 0x729F77C;
}
