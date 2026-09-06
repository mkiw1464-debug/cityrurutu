#import "ESP.h"
#import "../Utils/Il2cpp.h"
#import "../Utils/Config.h"
#import <UIKit/UIKit.h>

// Draw text helper
static void drawText(CGContextRef ctx, NSString* text,
                     CGFloat x, CGFloat y, UIColor* color) {
    NSDictionary* attrs = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10.f weight:UIFontWeightBold],
        NSForegroundColorAttributeName: color
    };
    [text drawAtPoint:CGPointMake(x, y) withAttributes:attrs];
}

static void drawRect(CGContextRef ctx, CGRect r, UIColor* c) {
    CGContextSetStrokeColorWithColor(ctx, c.CGColor);
    CGContextSetLineWidth(ctx, 1.5f);
    CGContextStrokeRect(ctx, r);
}

static void drawLine(CGContextRef ctx, CGPoint a, CGPoint b, UIColor* c) {
    CGContextSetStrokeColorWithColor(ctx, c.CGColor);
    CGContextSetLineWidth(ctx, 1.f);
    CGContextMoveToPoint(ctx, a.x, a.y);
    CGContextAddLineToPoint(ctx, b.x, b.y);
    CGContextStrokePath(ctx);
}

void ESP::drawAll(CGContextRef ctx) {
    auto& cfg = Config::get();
    if (!cfg.espEnabled) return;
    
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    uintptr_t mgr   = Read<uintptr_t>(OFF(Offsets::PlayerManager));
    uintptr_t list  = Read<uintptr_t>(mgr + Offsets::PlayerList);
    int       count = Read<int>(list + 0x18);
    
    uintptr_t localPlayer = Read<uintptr_t>(OFF(Offsets::LocalPlayer));
    int       localTeam   = Read<int>(localPlayer + Offsets::TeamID);
    
    int enemyCount = 0;
    
    for (int i = 0; i < count && i < 60; i++) {
        uintptr_t player = Read<uintptr_t>(list + 0x20 + i * 0x8);
        if (!player || player == localPlayer) continue;
        
        int teamID = Read<int>(player + Offsets::TeamID);
        if (teamID == localTeam) continue; // skip teammates
        
        float hp = Read<float>(player + Offsets::PlayerHP);
        if (hp <= 0.f) continue;
        
        enemyCount++;
        
        Vector3 headPos = {
            Read<float>(player + Offsets::PlayerBone + 7*0x10 + 0x38),
            Read<float>(player + Offsets::PlayerBone + 7*0x10 + 0x3C),
            Read<float>(player + Offsets::PlayerBone + 7*0x10 + 0x40)
        };
        Vector3 feetPos = {
            Read<float>(player + Offsets::PlayerPosition),
            Read<float>(player + Offsets::PlayerPosition + 0x4),
            Read<float>(player + Offsets::PlayerPosition + 0x8)
        };
        
        Vector2 headScr, feetScr;
        bool hOk = Aimbot::worldToScreen(headPos, headScr);
        bool fOk = Aimbot::worldToScreen(feetPos, feetScr);
        if (!hOk || !fOk) continue;
        
        float boxH = fabs(feetScr.y - headScr.y);
        float boxW = boxH * 0.4f;
        CGRect box = CGRectMake(headScr.x - boxW/2.f,
                                headScr.y,
                                boxW, boxH);
        
        UIColor* red = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.85f];
        UIColor* wht = [UIColor whiteColor];
        UIColor* grn = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
        
        if (cfg.espBox)
            drawRect(ctx, box, red);
        
        if (cfg.espName) {
            uintptr_t namePtr = Read<uintptr_t>(player + Offsets::PlayerName);
            // Il2cpp String: length at +0x10, chars at +0x14
            int nameLen = Read<int>(namePtr + 0x10);
            if (nameLen > 0 && nameLen < 32) {
                NSMutableString* name = [NSMutableString string];
                for (int j = 0; j < nameLen; j++) {
                    unichar c = Read<uint16_t>(namePtr + 0x14 + j*2);
                    [name appendFormat:@"%C", c];
                }
                drawText(ctx, name, headScr.x - boxW/2.f, headScr.y - 14.f, wht);
            }
        }
        
        if (cfg.espLine) {
            CGPoint bottom = CGPointMake(sw/2.f, sh);
            CGPoint target = CGPointMake(feetScr.x, feetScr.y);
            drawLine(ctx, bottom, target, red);
        }
        
        if (cfg.espHealthBar) {
            float hpPct    = hp / 200.f; // FF max HP = 200
            float barH     = boxH * hpPct;
            UIColor* hpClr = hpPct > 0.5f ? grn :
                             hpPct > 0.25f ? [UIColor yellowColor] : red;
            CGRect barBg = CGRectMake(box.origin.x - 5.f,
                                      box.origin.y, 3.f, boxH);
            CGRect bar   = CGRectMake(box.origin.x - 5.f,
                                      box.origin.y + (boxH - barH),
                                      3.f, barH);
            CGContextSetFillColorWithColor(ctx, [UIColor darkGrayColor].CGColor);
            CGContextFillRect(ctx, barBg);
            CGContextSetFillColorWithColor(ctx, hpClr.CGColor);
            CGContextFillRect(ctx, bar);
        }
    }
    
    if (cfg.enemyCounter) {
        NSString* cntStr = [NSString stringWithFormat:@"Enemies: %d", enemyCount];
        drawText(ctx, cntStr, 10.f, 30.f, [UIColor redColor]);
    }
}
