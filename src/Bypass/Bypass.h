#pragma once

namespace Bypass {
    void initAll();
    void patchLogin();
    void patchLobby();
    void patchReport();
    void patchAntiBan();
    void patchBlacklist();
    void patchAntiCheat();
    void patchIntegrity();
    void patchThirdPartyDetect();
    void patchSignatureCheck();
    void spoofJailbreakPaths();
    void hookSendPacket();
}
