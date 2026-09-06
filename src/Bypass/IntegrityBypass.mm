#import "IntegrityBypass.h"
#import "../Utils/Memory.h"
#import "../Utils/Il2cpp.h"
#import <substrate.h>
#import <CommonCrypto/CommonDigest.h>

// Hook CC_MD5 & CC_SHA256 — game hashes its own binary for integrity
// Return a pre-computed "clean" hash every time
static unsigned char* (*orig_md5)(const void*, CC_LONG, unsigned char*);
static unsigned char* hook_md5(const void* data, CC_LONG len, unsigned char* md) {
    orig_md5(data, len, md);
    // Replace with precomputed clean hash (fake clean binary hash)
    static uint8_t cleanHash[16] = {
        0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
        0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10
    };
    memcpy(md, cleanHash, 16);
    return md;
}

static unsigned char* (*orig_sha256)(const void*, CC_LONG, unsigned char*);
static unsigned char* hook_sha256(const void* data, CC_LONG len, unsigned char* md) {
    orig_sha256(data, len, md);
    static uint8_t cleanHash256[32] = {
        0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
        0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10,
        0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
        0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10
    };
    memcpy(md, cleanHash256, 32);
    return md;
}

void IntegrityBypass::init() {
    MSHookFunction((void*)CC_MD5,    (void*)hook_md5,    (void**)&orig_md5);
    MSHookFunction((void*)CC_SHA256, (void*)hook_sha256, (void**)&orig_sha256);
}
