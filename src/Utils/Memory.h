#pragma once
#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <sys/mman.h>

// Patch memory — bypass write protection
static void patchMemory(uintptr_t addr, uint8_t* patch, size_t len) {
    mach_vm_protect(mach_task_self(), addr, len, false,
                    VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    memcpy((void*)addr, patch, len);
    mach_vm_protect(mach_task_self(), addr, len, false,
                    VM_PROT_READ | VM_PROT_EXECUTE);
}

// NOP sled
static void nopRange(uintptr_t addr, size_t count) {
    uint8_t nopBuf[count];
    memset(nopBuf, 0x1F, count);     // ARM64 NOP = 0x1F200003
    uint32_t arm64nop = 0x1F2003D5;
    for (size_t i = 0; i < count; i += 4)
        memcpy(nopBuf + i, &arm64nop, 4);
    patchMemory(addr, nopBuf, count);
}

// Return true patch (MOV X0, #1; RET)
static uint8_t retTruePatch[] = {
    0x20, 0x00, 0x80, 0xD2, // MOV X0, #1
    0xC0, 0x03, 0x5F, 0xD6  // RET
};

// Return false patch (MOV X0, #0; RET)
static uint8_t retFalsePatch[] = {
    0x00, 0x00, 0x80, 0xD2, // MOV X0, #0
    0xC0, 0x03, 0x5F, 0xD6  // RET
};

// Return zero/nil
static uint8_t retNilPatch[] = {
    0x1F, 0x20, 0x03, 0xD5, // NOP
    0x00, 0x00, 0x80, 0xD2, // MOV X0, #0
    0xC0, 0x03, 0x5F, 0xD6  // RET
};
