//
//  ViewController.h
//  HexCalc
//
//  Created by YAMAMOTO Naoki on 12/10/02.
//  Copyright (c) 2012年 YAMAMOTO Naoki. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Calculator.h"

@interface ViewController : UIViewController
{
    IBOutlet UILabel* resultLabel;          // result label
    IBOutlet UILabel* memoryLabel;          // memory label
    IBOutlet UISegmentedControl* modeSeg;   // [Dec/Hex/Oct/Bin]

    UIButton* num0Button;          // [0]
    UIButton* num1Button;          // [1]
    UIButton* num2Button;          // [2]
    UIButton* num3Button;          // [3]
    UIButton* num4Button;          // [4]
    UIButton* num5Button;          // [5]
    UIButton* num6Button;          // [6]
    UIButton* num7Button;          // [7]
    UIButton* num8Button;          // [8]
    UIButton* num9Button;          // [9]
    UIButton* num00Button;         // [00]
    UIButton* AButton;             // [A]
    UIButton* BButton;             // [B]
    UIButton* CButton;             // [C]
    UIButton* DButton;             // [D]
    UIButton* EButton;             // [E]
    UIButton* FButton;             // [F]
    UIButton* pointButton;         // [.]
    UIButton* delButton;           // [DEL]
    UIButton* addButton;           // [+]
    UIButton* subtractButton;      // [-]
    UIButton* multiplyButton;      // [*]
    UIButton* divideButton;        // [/]
    UIButton* plusMinusButton;     // [+/-]
    UIButton* equalButton;         // [=]
    UIButton* mPlusButton;         // [M+]
    UIButton* mMinusButton;        // [M-]
    UIButton* mrButton;            // [MR]
    UIButton* mcButton;            // [MC]
    UIButton* clearButton;         // [AC]
    UIButton* andButton;           // [AND]
    UIButton* orButton;            // [OR]
    UIButton* xorButton;           // [XOR]
    UIButton* shiftLeftButton;     // [<<]
    UIButton* shiftRightButton;    // [>>]

    Calculator* calc;   // 計算機インスタンス
}

@property (nonatomic, retain) UILabel* resultLabel;
@property (nonatomic, retain) UILabel* memoryLabel;
@property (nonatomic, retain) UISegmentedControl* modeSeg;

@end
