#pragma once
#import <Foundation/Foundation.h>

#define DYLIB_VERSION "V1.0.0 Beta"
#define DYLIB_NAME    "FFNET IOS"

struct Config {
    // Aimbot
    bool  aimbotEnabled   = false;
    int   targetPart      = 0;   // 0=head 1=neck 2=body 3=leg
    float aimFov          = 80.0f;
    bool  showFovCircle   = false;
    bool  aimSilent       = false;
    
    // ESP
    bool  espEnabled      = false;
    bool  espName         = false;
    bool  espBox          = false;
    bool  espLine         = false;
    bool  espHealthBar    = false;
    bool  enemyCounter    = false;
    
    // Settings
    bool  streamProof     = false;
    
    static Config& get() {
        static Config instance;
        return instance;
    }
    
    void save() {
        NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
        [d setBool:aimbotEnabled forKey:@"ffnet_aimbot"];
        [d setInteger:targetPart forKey:@"ffnet_target"];
        [d setFloat:aimFov forKey:@"ffnet_fov"];
        [d setBool:showFovCircle forKey:@"ffnet_fovvisual"];
        [d setBool:aimSilent forKey:@"ffnet_silent"];
        [d setBool:espEnabled forKey:@"ffnet_esp"];
        [d setBool:espName forKey:@"ffnet_espname"];
        [d setBool:espBox forKey:@"ffnet_espbox"];
        [d setBool:espLine forKey:@"ffnet_espline"];
        [d setBool:espHealthBar forKey:@"ffnet_esphealth"];
        [d setBool:enemyCounter forKey:@"ffnet_counter"];
        [d setBool:streamProof forKey:@"ffnet_stream"];
        [d synchronize];
    }
    
    void load() {
        NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
        aimbotEnabled = [d boolForKey:@"ffnet_aimbot"];
        targetPart    = (int)[d integerForKey:@"ffnet_target"];
        aimFov        = [d floatForKey:@"ffnet_fov"] ?: 80.0f;
        showFovCircle = [d boolForKey:@"ffnet_fovvisual"];
        aimSilent     = [d boolForKey:@"ffnet_silent"];
        espEnabled    = [d boolForKey:@"ffnet_esp"];
        espName       = [d boolForKey:@"ffnet_espname"];
        espBox        = [d boolForKey:@"ffnet_espbox"];
        espLine       = [d boolForKey:@"ffnet_espline"];
        espHealthBar  = [d boolForKey:@"ffnet_esphealth"];
        enemyCounter  = [d boolForKey:@"ffnet_counter"];
        streamProof   = [d boolForKey:@"ffnet_stream"];
    }
};
