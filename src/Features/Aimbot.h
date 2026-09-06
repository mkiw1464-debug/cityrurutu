#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

struct Vector3 { float x, y, z; };
struct Vector2 { float x, y; };

namespace Aimbot {
    Vector3 getTargetBone(uintptr_t player, int part);
    bool    worldToScreen(Vector3 world, Vector2& screen);
    float   getDistance(Vector3 a, Vector3 b);
    bool    inFov(Vector2 target, float fovRadius);
    void    silentAim(uintptr_t player);
    void    update();
}
