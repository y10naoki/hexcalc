/* -*- Mode: C; tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
 * The MIT License
 *
 * Copyright (c) 2011 YAMAMOTO Naoki
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "Formula.h"
#import "DecimalNumber.h"

// c_flags
#define CALC_CLEAR_CURRENT   0x0001
#define CALC_INPUT_DECIMAL   0x0002
#define CALC_EXIST_MEMORY    0x0004
#define CALC_DONE            0x0008

// Calculator
@interface Calculator : NSObject {
    DisplayMode c_mode;
    Operator c_op;
    NSUInteger c_flags;

    Formula* c_formula;
    DecimalNumber* c_decimal_cur;
    DecimalNumber* c_decimal_mem;

    Operator c_op_last;
    DecimalNumber* c_decimal_last;
}

- (id)initWithMode:(DisplayMode)mode;
+ (id)calculatorWithMode:(DisplayMode)mode;
- (void)dealloc;

- (BOOL)enableCalculatorOperator:(Operator)op;
- (BOOL)enableCalculatorEqual;
- (NSString*)changeMode:(DisplayMode)mode;

- (NSString*)inputKey:(NSString*)key;
- (NSString*)inputPoint;
- (NSString*)inputPlusMinus;
- (NSString*)deleteKey;
- (NSString*)inputOperator:(Operator)op;

- (NSString*)calculate;
- (NSString*)clearAll;
- (NSString*)currentValue;

- (BOOL)inMemory;
- (BOOL)plusMemory;
- (BOOL)minusMemory;
- (NSString*)readMemory;
- (void)clearMemory;
- (DisplayMode)memoryMode;
- (NSString*)memoryValue;

- (NSString*)shiftLeftBit;
- (NSString*)shiftRightBit;

- (DisplayMode)mode;

@end
