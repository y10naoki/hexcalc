//
//  ViewController.m
//  HexCalc
//
//  Created by YAMAMOTO Naoki on 12/10/02.
//  Copyright (c) 2012年 YAMAMOTO Naoki. All rights reserved.
//

#import "ViewController.h"

#define BUTTON_WIDTH    55.0
#define BUTTON_HEIGHT   40.0
#define BUTTON_COLNUM   5
#define BUTTON_ROWNUM   8

#define KEY_FONTSIZE    20.0

#define RESULT_FONTSIZE     48.0
#define DEC_MIN_FONTSIZE    20.0
#define HEX_MIN_FONTSIZE    32.0
#define OCT_MIN_FONTSIZE    12.0
#define BIN_MIN_FONTSIZE     8.0

@implementation ViewController

@synthesize resultLabel;
@synthesize memoryLabel;
@synthesize modeSeg;

static DisplayMode modeTable[] = { DECIMAL, HEX, OCTAL, BINARY };

- (void)enableButtonMode:(DisplayMode)mode
{
    switch (mode) {
    case DECIMAL:
        AButton.enabled = NO;
        BButton.enabled = NO;
        CButton.enabled = NO;
        DButton.enabled = NO;
        EButton.enabled = NO;
        FButton.enabled = NO;
        num0Button.enabled = YES;
        num1Button.enabled = YES;
        num2Button.enabled = YES;
        num3Button.enabled = YES;
        num4Button.enabled = YES;
        num5Button.enabled = YES;
        num6Button.enabled = YES;
        num7Button.enabled = YES;
        num8Button.enabled = YES;
        num9Button.enabled = YES;
        num00Button.enabled = YES;
        pointButton.enabled = YES;
        plusMinusButton.enabled = YES;
        andButton.enabled = NO;
        orButton.enabled = NO;
        xorButton.enabled = NO;
        shiftLeftButton.enabled = NO;
        shiftRightButton.enabled = NO;
        break;

    case HEX:
        AButton.enabled = YES;
        BButton.enabled = YES;
        CButton.enabled = YES;
        DButton.enabled = YES;
        EButton.enabled = YES;
        FButton.enabled = YES;
        num0Button.enabled = YES;
        num1Button.enabled = YES;
        num2Button.enabled = YES;
        num3Button.enabled = YES;
        num4Button.enabled = YES;
        num5Button.enabled = YES;
        num6Button.enabled = YES;
        num7Button.enabled = YES;
        num8Button.enabled = YES;
        num9Button.enabled = YES;
        num00Button.enabled = YES;
        pointButton.enabled = NO;
        plusMinusButton.enabled = NO;
        andButton.enabled = YES;
        orButton.enabled = YES;
        xorButton.enabled = YES;
        shiftLeftButton.enabled = YES;
        shiftRightButton.enabled = YES;
        break;

    case OCTAL:
        AButton.enabled = NO;
        BButton.enabled = NO;
        CButton.enabled = NO;
        DButton.enabled = NO;
        EButton.enabled = NO;
        FButton.enabled = NO;
        num0Button.enabled = YES;
        num1Button.enabled = YES;
        num2Button.enabled = YES;
        num3Button.enabled = YES;
        num4Button.enabled = YES;
        num5Button.enabled = YES;
        num6Button.enabled = YES;
        num7Button.enabled = YES;
        num8Button.enabled = NO;
        num9Button.enabled = NO;
        num00Button.enabled = YES;
        pointButton.enabled = NO;
        plusMinusButton.enabled = NO;
        andButton.enabled = YES;
        orButton.enabled = YES;
        xorButton.enabled = YES;
        shiftLeftButton.enabled = YES;
        shiftRightButton.enabled = YES;
        break;

    case BINARY:
        AButton.enabled = NO;
        BButton.enabled = NO;
        CButton.enabled = NO;
        DButton.enabled = NO;
        EButton.enabled = NO;
        FButton.enabled = NO;
        num0Button.enabled = YES;
        num1Button.enabled = YES;
        num2Button.enabled = NO;
        num3Button.enabled = NO;
        num4Button.enabled = NO;
        num5Button.enabled = NO;
        num6Button.enabled = NO;
        num7Button.enabled = NO;
        num8Button.enabled = NO;
        num9Button.enabled = NO;
        num00Button.enabled = YES;
        pointButton.enabled = NO;
        plusMinusButton.enabled = NO;
        andButton.enabled = YES;
        orButton.enabled = YES;
        xorButton.enabled = YES;
        shiftLeftButton.enabled = YES;
        shiftRightButton.enabled = YES;
        break;
    }
}

- (void)displayCurrentMode
{
    DisplayMode mode = [calc mode];
    for (int i = 0; i < sizeof(modeTable) / sizeof(DisplayMode); i++) {
        if (modeTable[i] == mode) {
            modeSeg.selectedSegmentIndex = i;
            break;
        }
    }
}

- (UIButton*)addButtonKey:(NSString*)key
                  originX:(CGFloat)x
                  originY:(CGFloat)y
                    width:(CGFloat)width
                   height:(CGFloat)height
                     font:(UIFont*)font
          normalImageName:(NSString*)normalImageName
        selectedImageName:(NSString*)selectedImageName
        disabledImageName:(NSString*)disabledImageName
                   action:(SEL)action
{
    UIButtonType btnType = (normalImageName)? UIButtonTypeCustom : UIButtonTypeRoundedRect;

    UIButton* btn = [[UIButton buttonWithType:btnType] retain];
    btn.frame = CGRectMake(x, y, width, height);
    [btn setTitle:key forState:UIControlStateNormal];
    btn.titleLabel.font = font;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;

    if (btnType == UIButtonTypeCustom) {
        // 背景画像を指定
        [btn setBackgroundImage:[UIImage imageNamed:normalImageName] forState:UIControlStateNormal];
        if (selectedImageName)
            [btn setBackgroundImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
        if (disabledImageName)
            [btn setBackgroundImage:[UIImage imageNamed:disabledImageName] forState:UIControlStateDisabled];
        btn.titleLabel.textColor = [UIColor whiteColor];
    }

    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

- (void)makeButtonKeys:(CGRect)statusBar
{
    CGFloat buttonWidth = BUTTON_WIDTH;
    CGFloat buttonHeight = BUTTON_HEIGHT;
    
    CGSize frameSize = [[UIScreen mainScreen] applicationFrame].size;
    if (frameSize.height + statusBar.size.height == 568) {
        // Code for iPhone 5 or iPod 5 (screensize 480 x 568)
        buttonHeight = 50.0;
    }
    
    CGFloat base_x = 7.0;
    CGFloat base_y = self.modeSeg.frame.origin.y;
    CGFloat wspaces = ((frameSize.width - base_x) - buttonWidth * BUTTON_COLNUM) / BUTTON_COLNUM;
    CGFloat hspaces = ((frameSize.height - base_y) - buttonHeight * BUTTON_ROWNUM) / (BUTTON_ROWNUM + 1);
    
    CGFloat ios_version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (ios_version >= 7.0) {
        base_x = 0.0;
        wspaces = 0.0;
        hspaces = 0.0;
        frameSize.height += 20.0;
        buttonWidth = frameSize.width / BUTTON_COLNUM;
        buttonHeight = (frameSize.height - base_y) / BUTTON_ROWNUM;
        self.modeSeg.frame = CGRectMake(buttonWidth,
                                        base_y,
                                        frameSize.width - buttonWidth,
                                        buttonHeight);
    }
    
    CGFloat x0 = base_x;
    CGFloat x1 = x0 + buttonWidth + wspaces;
    CGFloat x2 = x1 + buttonWidth + wspaces;
    CGFloat x3 = x2 + buttonWidth + wspaces;
    CGFloat x4 = x3 + buttonWidth + wspaces;
    
    
    clearButton = [self addButtonKey:@"AC" originX:x0 originY:base_y width:buttonWidth height:buttonHeight
                                font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                     normalImageName:@"red.png" selectedImageName:nil disabledImageName:nil
                              action:@selector(doAllClearKey:)];
    
    CGFloat y = base_y + buttonHeight + hspaces;
    
    plusMinusButton = [self addButtonKey:@"+/-" originX:x0 originY:y width:buttonWidth height:buttonHeight
                                    font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                         normalImageName:@"brown.png" selectedImageName:nil disabledImageName:@"grey.png"
                                  action:@selector(doPlusMinusKey:)];
    mcButton = [self addButtonKey:@"MC" originX:x1 originY:y width:buttonWidth height:buttonHeight
                             font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                  normalImageName:@"green.png" selectedImageName:nil disabledImageName:@"grey.png"
                           action:@selector(doMemoryClearKey:)];
    mPlusButton = [self addButtonKey:@"M+" originX:x2 originY:y width:buttonWidth height:buttonHeight
                                font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                     normalImageName:@"green.png" selectedImageName:nil disabledImageName:@"grey.png"
                              action:@selector(doMemoryPlusKey:)];
    mMinusButton = [self addButtonKey:@"M-" originX:x3 originY:y width:buttonWidth height:buttonHeight
                                 font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                      normalImageName:@"green.png" selectedImageName:nil disabledImageName:@"grey.png"
                               action:@selector(doMemoryMinusKey:)];
    mrButton = [self addButtonKey:@"MR" originX:x4 originY:y width:buttonWidth height:buttonHeight
                             font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                  normalImageName:@"green.png" selectedImageName:nil disabledImageName:@"grey.png"
                           action:@selector(doMemoryReadKey:)];
    
    y += buttonHeight + hspaces;
    delButton = [self addButtonKey:@"DEL" originX:x0 originY:y width:buttonWidth height:buttonHeight
                              font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                   normalImageName:@"brown.png" selectedImageName:nil disabledImageName:@"grey.png"
                            action:@selector(doDelKey:)];
    DButton = [self addButtonKey:@"D" originX:x1 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    EButton = [self addButtonKey:@"E" originX:x2 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    FButton = [self addButtonKey:@"F" originX:x3 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    divideButton = [self addButtonKey:@"÷" originX:x4 originY:y width:buttonWidth height:buttonHeight
                                 font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                      normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                               action:@selector(doDivideKey:)];
    
    y += buttonHeight + hspaces;
    shiftRightButton = [self addButtonKey:@">>" originX:x0 originY:y width:buttonWidth height:buttonHeight
                                     font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                          normalImageName:@"brown.png" selectedImageName:nil disabledImageName:@"grey.png"
                                   action:@selector(doShiftRightKey:)];
    AButton = [self addButtonKey:@"A" originX:x1 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    BButton = [self addButtonKey:@"B" originX:x2 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    CButton = [self addButtonKey:@"C" originX:x3 originY:y width:buttonWidth height:buttonHeight
                            font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                 normalImageName:@"blue.png" selectedImageName:nil disabledImageName:@"grey.png"
                          action:@selector(doKey:)];
    multiplyButton = [self addButtonKey:@"×" originX:x4 originY:y width:buttonWidth height:buttonHeight
                                   font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                        normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                                 action:@selector(doMultiplyKey:)];
    
    y += buttonHeight + hspaces;
    shiftLeftButton = [self addButtonKey:@"<<" originX:x0 originY:y width:buttonWidth height:buttonHeight
                                    font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                         normalImageName:@"brown.png" selectedImageName:nil disabledImageName:@"grey.png"
                                  action:@selector(doShiftLeftKey:)];
    num7Button = [self addButtonKey:@"7" originX:x1 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num8Button = [self addButtonKey:@"8" originX:x2 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num9Button = [self addButtonKey:@"9" originX:x3 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    subtractButton = [self addButtonKey:@"-" originX:x4 originY:y width:buttonWidth height:buttonHeight
                                   font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                        normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                                 action:@selector(doSubtractKey:)];
    
    y += buttonHeight + hspaces;
    xorButton = [self addButtonKey:@"XOR" originX:x0 originY:y width:buttonWidth height:buttonHeight
                              font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                   normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                            action:@selector(doXORKey:)];
    num4Button = [self addButtonKey:@"4" originX:x1 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num5Button = [self addButtonKey:@"5" originX:x2 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num6Button = [self addButtonKey:@"6" originX:x3 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    addButton = [self addButtonKey:@"+" originX:x4 originY:y width:buttonWidth height:buttonHeight
                              font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                   normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                            action:@selector(doAddKey:)];
    
    y += buttonHeight + hspaces;
    orButton = [self addButtonKey:@"OR" originX:x0 originY:y width:buttonWidth height:buttonHeight
                             font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                  normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                           action:@selector(doORKey:)];
    num1Button = [self addButtonKey:@"1" originX:x1 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num2Button = [self addButtonKey:@"2" originX:x2 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    num3Button = [self addButtonKey:@"3" originX:x3 originY:y width:buttonWidth height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                             action:@selector(doKey:)];
    CGFloat equalHeight = buttonHeight * 2 + hspaces;
    equalButton = [self addButtonKey:@"=" originX:x4 originY:y width:buttonWidth height:equalHeight
                                font:[UIFont systemFontOfSize:KEY_FONTSIZE+4.0]
                     normalImageName:@"orange.png" selectedImageName:nil disabledImageName:nil
                              action:@selector(doEqualKey:)];
    
    y += buttonHeight + hspaces;
    andButton = [self addButtonKey:@"AND" originX:x0 originY:y width:buttonWidth height:buttonHeight
                              font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                   normalImageName:@"brown.png" selectedImageName:@"sel_brown.png" disabledImageName:@"grey.png"
                            action:@selector(doANDKey:)];
    num0Button = [self addButtonKey:@"0" originX:x1 originY:y width:buttonWidth*2+wspaces height:buttonHeight
                               font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                    normalImageName:@"black.png" selectedImageName:nil disabledImageName:nil
                             action:@selector(doKey:)];
    pointButton = [self addButtonKey:@"." originX:x3 originY:y width:buttonWidth height:buttonHeight
                                font:[UIFont systemFontOfSize:KEY_FONTSIZE]
                     normalImageName:@"black.png" selectedImageName:nil disabledImageName:@"grey.png"
                              action:@selector(doPointKey:)];
}

- (void)moveButtonKeys:(CGRect)statusBar
{
    CGFloat buttonWidth = BUTTON_WIDTH;
    CGFloat buttonHeight = BUTTON_HEIGHT;
    
    CGSize frameSize = [[UIScreen mainScreen] applicationFrame].size;
    if (frameSize.height + statusBar.size.height == 568) {
        // Code for iPhone 5 or iPod 5 (screensize 480 x 568)
        buttonHeight = 50.0;
    }
    
    CGFloat base_x = 7.0;
    CGFloat base_y = self.modeSeg.frame.origin.y;
    CGFloat wspaces = ((frameSize.width - base_x) - buttonWidth * BUTTON_COLNUM) / BUTTON_COLNUM;
    CGFloat hspaces = ((frameSize.height - base_y) - buttonHeight * BUTTON_ROWNUM) / (BUTTON_ROWNUM + 1);
    
    CGFloat ios_version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (ios_version >= 7.0) {
        base_x = 0.0;
        wspaces = 0.0;
        hspaces = 0.0;
        frameSize.height += 20.0;
        buttonWidth = frameSize.width / BUTTON_COLNUM;
        buttonHeight = (frameSize.height - base_y) / BUTTON_ROWNUM;
        self.modeSeg.frame = CGRectMake(buttonWidth,
                                        base_y,
                                        frameSize.width - buttonWidth,
                                        buttonHeight);
    }
    
    CGFloat x0 = base_x;
    CGFloat x1 = x0 + buttonWidth + wspaces;
    CGFloat x2 = x1 + buttonWidth + wspaces;
    CGFloat x3 = x2 + buttonWidth + wspaces;
    CGFloat x4 = x3 + buttonWidth + wspaces;
    
    
    clearButton.frame = CGRectMake(x0, base_y, buttonWidth, buttonHeight);
    
    CGFloat y = base_y + buttonHeight + hspaces;
    
    plusMinusButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    mcButton.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    mPlusButton.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    mMinusButton.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    mrButton.frame = CGRectMake(x4, y, buttonWidth, buttonHeight);
    
    y += buttonHeight + hspaces;
    delButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    DButton.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    EButton.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    FButton.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    divideButton.frame = CGRectMake(x4, y, buttonWidth, buttonHeight);
    
    y += buttonHeight + hspaces;
    shiftRightButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    AButton.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    BButton.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    CButton.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    multiplyButton.frame = CGRectMake(x4, y, buttonWidth, buttonHeight);
    
    y += buttonHeight + hspaces;
    shiftLeftButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    num7Button.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    num8Button.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    num9Button.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    subtractButton.frame = CGRectMake(x4, y, buttonWidth, buttonHeight);
    
    y += buttonHeight + hspaces;
    xorButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    num4Button.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    num5Button.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    num6Button.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    addButton.frame = CGRectMake(x4, y, buttonWidth, buttonHeight);
    
    y += buttonHeight + hspaces;
    orButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    num1Button.frame = CGRectMake(x1, y, buttonWidth, buttonHeight);
    num2Button.frame = CGRectMake(x2, y, buttonWidth, buttonHeight);
    num3Button.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
    CGFloat equalHeight = buttonHeight * 2 + hspaces;
    equalButton.frame = CGRectMake(x4, y, buttonWidth, equalHeight);
    
    y += buttonHeight + hspaces;
    andButton.frame = CGRectMake(x0, y, buttonWidth, buttonHeight);
    num0Button.frame = CGRectMake(x1, y, buttonWidth*2+wspaces, buttonHeight);
    pointButton.frame = CGRectMake(x3, y, buttonWidth, buttonHeight);
}

// ステータスバーのサイズが変更される直前に呼び出されるメソッド
- (void)statusBarFrameWillChange:(NSNotification*)notification
{
    NSValue* rectValue = [[notification userInfo] valueForKey:UIApplicationStatusBarFrameUserInfoKey];
    CGRect newFrame;
    [rectValue getValue:&newFrame];
//    NSLog(@"statusBarFrameWillChange: newSize %f, %f", newFrame.size.width, newFrame.size.height);

    [self moveButtonKeys:newFrame];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ステータスバーのサイズ変更を通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarFrameWillChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];

	// Do any additional setup after loading the view, typically from a nib.
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat ios_version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (ios_version >= 7.0) {
        self.view.backgroundColor =
        resultLabel.backgroundColor =
        memoryLabel.backgroundColor = [UIColor whiteColor];
        memoryLabel.textColor = [UIColor grayColor];

        NSArray* subviews = [self.view subviews];
        for (UIView* v in subviews) {
            v.frame = CGRectMake(v.frame.origin.x,
                                 v.frame.origin.y+20.0,
                                 v.frame.size.width,
                                 v.frame.size.height);
        }
    }

    // ボタンを作成
    [self makeButtonKeys:statusRect];

    // 計算クラスのインスタンス化
    calc = [[Calculator alloc] initWithMode:DECIMAL];
    
    resultLabel.text = [calc currentValue];
    
    memoryLabel.text = @"";
    
    [self displayCurrentMode];
    [self enableButtonMode:DECIMAL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [resultLabel release];
    [memoryLabel release];
    [modeSeg release];

    [num0Button release];
    [num1Button release];
    [num2Button release];
    [num3Button release];
    [num4Button release];
    [num5Button release];
    [num6Button release];
    [num7Button release];
    [num8Button release];
    [num9Button release];
    [num00Button release];
    [AButton release];
    [BButton release];
    [CButton release];
    [DButton release];
    [EButton release];
    [FButton release];
    [addButton release];
    [subtractButton release];
    [multiplyButton release];
    [divideButton release];
    [plusMinusButton release];
    [equalButton release];
    [pointButton release];
    [delButton release];
    [mPlusButton release];
    [mMinusButton release];
    [mrButton release];
    [mcButton release];
    [clearButton release];
    [andButton release];
    [orButton release];
    [xorButton release];
    [shiftLeftButton release];
    [shiftRightButton release];

    [calc release];

    [super dealloc];
}

- (NSString*)stringMode:(DisplayMode)mode
{
    switch (mode) {
    case DECIMAL:
        return @"(Dec)";
    case HEX:
        return @"(Hex)";
    case OCTAL:
        return @"(Oct)";
    case BINARY:
        return @"(Bin)";
    }
    return @"";
}

- (void)selectedOperator:(Operator)op
{
    switch (op) {
    case ADD:
        addButton.selected = YES;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    case SUBTRACT:
        addButton.selected = NO;
        subtractButton.selected = YES;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    case MULTIPLY:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = YES;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    case DIVIDE:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = YES;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    case BIT_AND:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = YES;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    case BIT_OR:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = YES;
        xorButton.selected = NO;
        break;
    case BIT_XOR:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = YES;
        break;
    default:
        addButton.selected = NO;
        subtractButton.selected = NO;
        multiplyButton.selected = NO;
        divideButton.selected = NO;
        andButton.selected = NO;
        orButton.selected = NO;
        xorButton.selected = NO;
        break;
    }
}

- (IBAction)doMode:(id)sender
{
    UISegmentedControl* seg =  (UISegmentedControl*)sender;
    int index = (int)seg.selectedSegmentIndex;
    DisplayMode mode = modeTable[index];

    // 最小フォントサイズの指定(2013/07/30)
    switch (mode) {
    case DECIMAL:
//        resultLabel.minimumFontSize = DEC_MIN_FONTSIZE;
        resultLabel.minimumScaleFactor = DEC_MIN_FONTSIZE / RESULT_FONTSIZE;
        break;
    case HEX:
//        resultLabel.minimumFontSize = HEX_MIN_FONTSIZE;
        resultLabel.minimumScaleFactor = HEX_MIN_FONTSIZE / RESULT_FONTSIZE;
        break;
    case OCTAL:
//        resultLabel.minimumFontSize = OCT_MIN_FONTSIZE;
        resultLabel.minimumScaleFactor = OCT_MIN_FONTSIZE / RESULT_FONTSIZE;
        break;
    case BINARY:
//        resultLabel.minimumFontSize = BIN_MIN_FONTSIZE;
        resultLabel.minimumScaleFactor = BIN_MIN_FONTSIZE / RESULT_FONTSIZE;
        break;
    }

    NSString* curString = [calc changeMode:mode];
    resultLabel.text = curString;
    [self enableButtonMode:mode];
}

- (void)doKey:(id)sender
{
    UIButton* btn = (UIButton*)sender;
    NSString* ch = btn.titleLabel.text;
    NSString* curString = [calc inputKey:ch];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

- (void)doEqualKey:(id)sender
{
    if ([calc enableCalculatorEqual]) {
        // 計算します。
        NSString* curString = [calc calculate];
        resultLabel.text = curString;
    }
    [self selectedOperator:NONE];
}

- (void)doPointKey:(id)sender
{
    NSString* curString = [calc inputPoint];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

- (void)doDelKey:(id)sender
{
    NSString* curString = [calc deleteKey];
    resultLabel.text = curString;
}

- (void)doAddKey:(id)sender
{
    NSString* curString = [calc inputOperator:ADD];
    resultLabel.text = curString;
    [self selectedOperator:ADD];
}

- (void)doSubtractKey:(id)sender
{
    NSString* curString = [calc inputOperator:SUBTRACT];
    resultLabel.text = curString;
    [self selectedOperator:SUBTRACT];
}

- (void)doMultiplyKey:(id)sender
{
    NSString* curString = [calc inputOperator:MULTIPLY];
    resultLabel.text = curString;
    [self selectedOperator:MULTIPLY];
}

- (void)doDivideKey:(id)sender
{
    NSString* curString = [calc inputOperator:DIVIDE];
    resultLabel.text = curString;
    [self selectedOperator:DIVIDE];
}

- (void)doPlusMinusKey:(id)sender
{
    NSString* curString = [calc inputPlusMinus];
    resultLabel.text = curString;
}

- (void)doMemoryPlusKey:(id)sender
{
    if ([calc plusMemory]) {
        NSString* memValue = [calc memoryValue];
        DisplayMode memMode = [calc memoryMode];
        NSString* memString = [NSString stringWithFormat:@"Memory:%@ %@", memValue, [self stringMode:memMode]];
        memoryLabel.text = memString;
    }
}

- (void)doMemoryMinusKey:(id)sender
{
    if ([calc minusMemory]) {
        NSString* memValue = [calc memoryValue];
        DisplayMode memMode = [calc memoryMode];
        NSString* memString = [NSString stringWithFormat:@"Memory:%@ %@", memValue, [self stringMode:memMode]];
        memoryLabel.text = memString;
    }
}

- (void)doMemoryReadKey:(id)sender
{
    // 現在のモードで読み込む
    NSString* curString = [calc readMemory];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

- (void)doMemoryClearKey:(id)sender
{
    [calc clearMemory];
    memoryLabel.text = @"";
}

- (void)doAllClearKey:(id)sender
{
    NSString* curString = [calc clearAll];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

- (void)doORKey:(id)sender
{
    NSString* curString = [calc inputOperator:BIT_OR];
    resultLabel.text = curString;
    [self selectedOperator:BIT_OR];
}

- (void)doANDKey:(id)sender
{
    NSString* curString = [calc inputOperator:BIT_AND];
    resultLabel.text = curString;
    [self selectedOperator:BIT_AND];
}

- (void)doXORKey:(id)sender
{
    NSString* curString = [calc inputOperator:BIT_XOR];
    resultLabel.text = curString;
    [self selectedOperator:BIT_XOR];
}

- (void)doShiftLeftKey:(id)sender
{
    NSString* curString = [calc shiftLeftBit];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

- (void)doShiftRightKey:(id)sender
{
    NSString* curString = [calc shiftRightBit];
    resultLabel.text = curString;
    [self selectedOperator:NONE];
}

@end
