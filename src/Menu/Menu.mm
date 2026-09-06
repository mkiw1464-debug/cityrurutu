#import "Menu.h"
#import "GlassUI.h"
#import "../Utils/Config.h"
#import "../Features/Aimbot.h"
#import "../Features/ESP.h"
#import <UIKit/UIKit.h>

// ─── ESP Overlay ──────────────────────────────────────────
@interface ESPOverlay : UIView @end
@implementation ESPOverlay
- (void)drawRect:(CGRect)r {
    auto& cfg = Config::get();
    if (cfg.streamProof) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    ESP::drawAll(ctx);
}
- (BOOL)isOpaque { return NO; }
@end

// ─── Glassmorphism Menu ──────────────────────────────────
@interface FFNETMenuVC : UIViewController
@property (nonatomic, strong) UIView*              glassView;
@property (nonatomic, strong) UISegmentedControl*  pageControl;
@property (nonatomic, strong) UIScrollView*        contentView;
@property (nonatomic, assign) NSInteger            currentPage;
@end

@implementation FFNETMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self buildGlassContainer];
    [self buildPageTabs];
    [self buildPage:0];
}

- (void)buildGlassContainer {
    // Glass blur background
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
    UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = CGRectMake(20, 60, 320, 480);
    blurView.layer.cornerRadius = 20.f;
    blurView.clipsToBounds = YES;
    blurView.layer.borderWidth = 0.5f;
    blurView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2f].CGColor;
    [self.view addSubview:blurView];
    self.glassView = blurView;
    
    // Header
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, 200, 24)];
    title.text = [NSString stringWithFormat:@"FFNET IOS  %s", DYLIB_VERSION];
    title.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    title.textColor = [UIColor whiteColor];
    [blurView.contentView addSubview:title];
    
    // Close button (X)
    UIButton* close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(270, 10, 36, 36);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [close setTitleColor:[UIColor colorWithWhite:1 alpha:0.7f]
                forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeTapped)
    forControlEvents:UIControlEventTouchUpInside];
    [blurView.contentView addSubview:close];
    
    // Separator
    UIView* sep = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 320, 0.5f)];
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15f];
    [blurView.contentView addSubview:sep];
    
    // Content scroll
    UIScrollView* scroll = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, 100, 320, 370)];
    scroll.showsVerticalScrollIndicator = NO;
    [blurView.contentView addSubview:scroll];
    self.contentView = scroll;
}

- (void)buildPageTabs {
    NSArray* pages = @[@"AIMBOT", @"ESP", @"SETTINGS"];
    UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:pages];
    seg.frame = CGRectMake(10, 56, 300, 32);
    seg.selectedSegmentIndex = 0;
    seg.tintColor = [UIColor whiteColor];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}
                       forState:UIControlStateNormal];
    [seg addTarget:self action:@selector(pageSwitched:)
  forControlEvents:UIControlEventValueChanged];
    [self.glassView.subviews.lastObject addSubview:seg];  // add to contentView superview
    [(UIVisualEffectView*)self.glassView addSubviewToContentView:seg];
    self.pageControl = seg;
}

// Glass toggle row helper
- (UIView*)makeToggleRow:(NSString*)label
                 enabled:(BOOL)on
                  action:(SEL)action
                      at:(CGFloat)y {
    UIView* row = [[UIView alloc] initWithFrame:CGRectMake(0, y, 300, 44)];
    
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, 44)];
    lbl.text = label;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13.f];
    [row addSubview:lbl];
    
    UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectMake(240, 8, 0, 0)];
    sw.on = on;
    sw.onTintColor = [UIColor colorWithRed:0.4f green:0.8f blue:1.f alpha:1.f];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    
    return row;
}

// Slider row
- (UIView*)makeSliderRow:(NSString*)label
                     val:(float)val min:(float)mn max:(float)mx
                  action:(SEL)action
                      at:(CGFloat)y {
    UIView* row = [[UIView alloc] initWithFrame:CGRectMake(0, y, 300, 56)];
    
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 150, 24)];
    lbl.text = [NSString stringWithFormat:@"%@: %.0f", label, val];
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:12.f];
    lbl.tag = 999;
    [row addSubview:lbl];
    
    UISlider* slider = [[UISlider alloc] initWithFrame:CGRectMake(16, 26, 270, 22)];
    slider.minimumValue = mn; slider.maximumValue = mx;
    slider.value = val;
    slider.minimumTrackTintColor = [UIColor colorWithRed:0.4f green:0.8f blue:1.f alpha:1.f];
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [row addSubview:slider];
    
    return row;
}

- (void)buildPage:(NSInteger)page {
    // Clear
    for (UIView* v in self.contentView.subviews) [v removeFromSuperview];
    
    CGFloat y = 8.f;
    auto& cfg = Config::get();
    
    if (page == 0) { // AIMBOT
        [self.contentView addSubview:[self makeToggleRow:@"Aimbot"
            enabled:cfg.aimbotEnabled action:@selector(toggleAimbot:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Aim Silent"
            enabled:cfg.aimSilent action:@selector(toggleSilent:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Show FOV Circle"
            enabled:cfg.showFovCircle action:@selector(toggleFovVis:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeSliderRow:@"FOV Radius"
            val:cfg.aimFov min:0 max:200 action:@selector(fovChanged:) at:y]]; y+=64;
        
        // Target part picker
        NSArray* parts = @[@"Head", @"Neck", @"Body", @"Leg"];
        UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:parts];
        seg.frame = CGRectMake(8, y, 284, 32);
        seg.selectedSegmentIndex = cfg.targetPart;
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}
                           forState:UIControlStateNormal];
        seg.tintColor = [UIColor colorWithRed:0.4f green:0.8f blue:1.f alpha:1.f];
        [seg addTarget:self action:@selector(targetPartChanged:)
      forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:seg];
        
    } else if (page == 1) { // ESP
        [self.contentView addSubview:[self makeToggleRow:@"ESP Enable"
            enabled:cfg.espEnabled action:@selector(toggleESP:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Name ESP"
            enabled:cfg.espName action:@selector(toggleESPName:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Box ESP"
            enabled:cfg.espBox action:@selector(toggleESPBox:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Line ESP"
            enabled:cfg.espLine action:@selector(toggleESPLine:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Health Bar"
            enabled:cfg.espHealthBar action:@selector(toggleESPHP:) at:y]]; y+=52;
        [self.contentView addSubview:[self makeToggleRow:@"Enemy Counter"
            enabled:cfg.enemyCounter action:@selector(toggleCounter:) at:y]];
        
    } else { // SETTINGS
        [self.contentView addSubview:[self makeToggleRow:@"Stream Proof"
            enabled:cfg.streamProof action:@selector(toggleStream:) at:y]]; y+=52;
        
        UILabel* ver = [[UILabel alloc] initWithFrame:CGRectMake(16, y, 280, 24)];
        ver.text = [NSString stringWithFormat:@"Version: %s", DYLIB_VERSION];
        ver.textColor = [UIColor colorWithWhite:1 alpha:0.5f];
        ver.font = [UIFont systemFontOfSize:11.f];
        [self.contentView addSubview:ver]; y+=32;
        
        UIButton* saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        saveBtn.frame = CGRectMake(60, y, 180, 40);
        [saveBtn setTitle:@"Save Config" forState:UIControlStateNormal];
        saveBtn.backgroundColor = [UIColor colorWithRed:0.4f green:0.8f blue:1.f alpha:0.3f];
        saveBtn.layer.cornerRadius = 10.f;
        [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [saveBtn addTarget:self action:@selector(saveConfig)
          forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:saveBtn];
    }
    
    self.contentView.contentSize = CGSizeMake(300, y + 60);
}

// ─── Toggle Handlers ──────────────────────────────────────
-(void)toggleAimbot:(UISwitch*)s { Config::get().aimbotEnabled=s.on; }
-(void)toggleSilent:(UISwitch*)s { Config::get().aimSilent=s.on;     }
-(void)toggleFovVis:(UISwitch*)s { Config::get().showFovCircle=s.on; }
-(void)fovChanged:(UISlider*)s   {
    Config::get().aimFov = s.value;
    UIView* row = s.superview;
    UILabel* lbl=(UILabel*)[row viewWithTag:999];
    lbl.text=[NSString stringWithFormat:@"FOV Radius: %.0f", s.value];
}
-(void)targetPartChanged:(UISegmentedControl*)s { Config::get().targetPart=(int)s.selectedSegmentIndex; }
-(void)toggleESP:(UISwitch*)s    { Config::get().espEnabled=s.on;    }
-(void)toggleESPName:(UISwitch*)s{ Config::get().espName=s.on;       }
-(void)toggleESPBox:(UISwitch*)s { Config::get().espBox=s.on;        }
-(void)toggleESPLine:(UISwitch*)s{ Config::get().espLine=s.on;       }
-(void)toggleESPHP:(UISwitch*)s  { Config::get().espHealthBar=s.on;  }
-(void)toggleCounter:(UISwitch*)s{ Config::get().enemyCounter=s.on;  }
-(void)toggleStream:(UISwitch*)s { Config::get().streamProof=s.on;   }
-(void)saveConfig                { Config::get().save(); }

-(void)pageSwitched:(UISegmentedControl*)s {
    self.currentPage = s.selectedSegmentIndex;
    [self buildPage:self.currentPage];
}

-(void)closeTapped {
    [[GlassMenuWindow shared] toggleMenu];
}

@end

// ─── Glass Window ─────────────────────────────────────────
@implementation GlassMenuWindow {
    FFNETMenuVC* _vc;
    BOOL         _visible;
    ESPOverlay*  _espOverlay;
}

+ (instancetype)shared {
    static GlassMenuWindow* w;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        CGRect s = [UIScreen mainScreen].bounds;
        w = [[GlassMenuWindow alloc] initWithFrame:s];
        w.windowLevel = UIWindowLevelAlert + 100;
        w.backgroundColor = [UIColor clearColor];
        w.userInteractionEnabled = YES;
        [w makeKeyAndVisible];
    });
    return w;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _vc  = [FFNETMenuVC new];
        _vc.view.hidden = YES;
        self.rootViewController = _vc;
        
        // Tap gesture: 3 taps to open menu
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleTripleTap:)];
        tap.numberOfTapsRequired    = 3;
        tap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tap];
        
        // ESP overlay
        _espOverlay = [[ESPOverlay alloc] initWithFrame:frame];
        _espOverlay.userInteractionEnabled = NO;
        _espOverlay.backgroundColor = [UIColor clearColor];
        [self addSubview:_espOverlay];
        
        // Refresh ESP on display link
        CADisplayLink* link = [CADisplayLink displayLinkWithTarget:self
                                                          selector:@selector(tick)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick {
    Aimbot::update();
    [_espOverlay setNeedsDisplay];
}

- (void)handleTripleTap:(UITapGestureRecognizer*)g {
    [self toggleMenu];
}

- (void)toggleMenu {
    _visible = !_visible;
    _vc.view.hidden = !_visible;
    if (_visible) Config::get().load();
}

- (UIView*)hitTest:(CGPoint)p withEvent:(UIEvent*)e {
    if (!_visible) return nil;
    return [super hitTest:p withEvent:e];
}

// Streamproof: hide from ReplayKit/screenshot
- (void)didAddSubview:(UIView*)v {
    [super didAddSubview:v];
    if (Config::get().streamProof) {
        // Move UIWindow to secure layer (not captured by screen recording)
        // This requires entitlements, best-effort via tag
        v.tag = 0x5EC4E;
    }
}

@end
