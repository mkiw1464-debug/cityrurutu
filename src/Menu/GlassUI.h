#pragma once
#import <UIKit/UIKit.h>

// Glassmorphism iOS-style menu
@interface GlassMenuWindow : UIWindow
+ (instancetype)shared;
- (void)toggleMenu;
@end
