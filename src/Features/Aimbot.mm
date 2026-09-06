#import "Aimbot.h"
#import "../Utils/Il2cpp.h"
#import "../Utils/Config.h"
#import <UIKit/UIKit.h>
#import <simd/simd.h>

static CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
static CGFloat screenH = [UIScreen mainScreen].bounds.size.height;

Vector3 Aimbot::getTargetBone(uintptr_t player, int part) {
    // Bone indices: 0=head(7) 1=neck(6) 2=chest(1) 3=pelvis(0)
    static int boneMap[] = {7, 6, 1, 0};
    int boneIdx = boneMap[part < 4 ? part : 0];
    
    uintptr_t boneArr = Read<uintptr_t>(player + Offsets::PlayerBone);
    uintptr_t bone    = Read<uintptr_t>(boneArr + boneIdx * 0x10);
    Vector3   pos;
    pos.x = Read<float>(bone + 0x38);
    pos.y = Read<float>(bone + 0x3C);
    pos.z = Read<float>(bone + 0x40);
    return pos;
}

bool Aimbot::worldToScreen(Vector3 world, Vector2& screen) {
    uintptr_t cam = Read<uintptr_t>(OFF(Offsets::Camera));
    float mat[16];
    for (int i = 0; i < 16; i++)
        mat[i] = Read<float>(cam + Offsets::ViewMatrix + i * 4);
    
    float w = mat[12]*world.x + mat[13]*world.y + mat[14]*world.z + mat[15];
    if (w < 0.1f) return false;
    
    float x = (mat[0]*world.x + mat[1]*world.y + mat[2]*world.z  + mat[3])  / w;
    float y = (mat[4]*world.x + mat[5]*world.y + mat[6]*world.z  + mat[7])  / w;
    
    screen.x = (screenW / 2.f) * (1.f + x);
    screen.y = (screenH / 2.f) * (1.f - y);
    return true;
}

float Aimbot::getDistance(Vector3 a, Vector3 b) {
    float dx = a.x-b.x, dy = a.y-b.y, dz = a.z-b.z;
    return sqrtf(dx*dx + dy*dy + dz*dz);
}

bool Aimbot::inFov(Vector2 target, float fovRadius) {
    float cx = screenW / 2.f;
    float cy = screenH / 2.f;
    float dx = target.x - cx;
    float dy = target.y - cy;
    return sqrtf(dx*dx + dy*dy) <= fovRadius;
}

void Aimbot::silentAim(uintptr_t targetPlayer) {
    auto& cfg = Config::get();
    Vector3 bonePos = getTargetBone(targetPlayer, cfg.targetPart);
    // Write target position into aim angle buffer (silent = no crosshair move)
    Write<float>(OFF(Offsets::AimAngle) + 0x0, bonePos.x);
    Write<float>(OFF(Offsets::AimAngle) + 0x4, bonePos.y);
    Write<float>(OFF(Offsets::AimAngle) + 0x8, bonePos.z);
}

void Aimbot::update() {
    auto& cfg = Config::get();
    if (!cfg.aimbotEnabled && !cfg.aimSilent) return;
    
    uintptr_t mgr     = Read<uintptr_t>(OFF(Offsets::PlayerManager));
    uintptr_t list    = Read<uintptr_t>(mgr + Offsets::PlayerList);
    int       count   = Read<int>(list + 0x18);
    
    uintptr_t localPlayer = Read<uintptr_t>(OFF(Offsets::LocalPlayer));
    Vector3   localPos    = {
        Read<float>(localPlayer + Offsets::PlayerPosition),
        Read<float>(localPlayer + Offsets::PlayerPosition + 0x4),
        Read<float>(localPlayer + Offsets::PlayerPosition + 0x8)
    };
    int localTeam = Read<int>(localPlayer + Offsets::TeamID);
    
    float     bestDist  = FLT_MAX;
    uintptr_t bestEnemy = 0;
    
    for (int i = 0; i < count && i < 60; i++) {
        uintptr_t player = Read<uintptr_t>(list + 0x20 + i * 0x8);
        if (!player || player == localPlayer) continue;
        
        int teamID = Read<int>(player + Offsets::TeamID);
        if (teamID == localTeam) continue; // skip teammates
        
        float hp = Read<float>(player + Offsets::PlayerHP);
        if (hp <= 0.f) continue;
        
        Vector3 enemyPos = {
            Read<float>(player + Offsets::PlayerPosition),
            Read<float>(player + Offsets::PlayerPosition + 0x4),
            Read<float>(player + Offsets::PlayerPosition + 0x8)
        };
        
        Vector2 screen;
        if (!worldToScreen(enemyPos, screen)) continue;
        if (!inFov(screen, cfg.aimFov))       continue;
        
        float dist = getDistance(localPos, enemyPos);
        if (dist < bestDist) {
            bestDist  = dist;
            bestEnemy = player;
        }
    }
    
    if (!bestEnemy) return;
    
    if (cfg.aimSilent) {
        silentAim(bestEnemy);
    } else {
        // Regular aimbot — adjust fire angle
        Vector3 bonePos = getTargetBone(bestEnemy, cfg.targetPart);
        Write<float>(OFF(Offsets::FireControl) + 0x0, bonePos.x);
        Write<float>(OFF(Offsets::FireControl) + 0x4, bonePos.y);
        Write<float>(OFF(Offsets::FireControl) + 0x8, bonePos.z);
    }
}
