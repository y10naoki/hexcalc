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

#define BIT_SIZE            (sizeof(int64_t) * 8)

#define MAX_STRING_SIZE     (BIT_SIZE + 1)
#define MAX_DECIMAL_LENGTH  (38+1)              // decimal point length(plus one is point)
#define MAX_HEX_LENGTH      16                  // (BIT_SIZE / 4)
#define MAX_OCTAL_LENGTH    22                  // (BIT_SIZE / 3)
#define MAX_BINARY_LENGTH   BIT_SIZE

// (int64_t)
// -9,223,372,036,854,775,808
// +9,223,372,036,854,775,807

// 有効範囲
//+18,446,744,073,709,551,615
//-18,446,744,073,709,551,615

typedef enum {
    DECIMAL,
    HEX,
    OCTAL,
    BINARY
} DisplayMode;

// DecimalNumber
@interface DecimalNumber : NSObject {
    DisplayMode d_mode;
    char d_str[MAX_STRING_SIZE];
    BOOL d_isfloat;
    BOOL d_isminus;
}

- (id)initWithMode:(DisplayMode)mode;
+ (id)decimalNumberWithMode:(DisplayMode)mode;
- (void)dealloc;

- (void)copyDecimalNumber:(DecimalNumber*)num;
- (NSString*)setDecimal:(NSDecimal)value;
- (NSString*)setUint64:(uint64_t)value;

- (void)setMode:(DisplayMode)mode;
- (NSString*)changeMode:(DisplayMode)mode;

- (BOOL)checkInputKey:(const char*)cstr;
- (NSString*)inputKey:(const char*)cstr;
- (NSString*)inputPoint;
- (NSString*)inputPlusMinus;
- (NSString*)delete;

- (NSString*)clear;

- (BOOL)isEmpty;
- (const char*)cStringValue;
- (BOOL)isFloatingPoint;
- (BOOL)isMinus;
- (DisplayMode)mode;

- (NSString*)stringValue;
- (NSDecimal)decimalValue;
- (uint64_t)uint64;

- (NSString*)shiftLeftBit;
- (NSString*)shiftRightBit;

- (BOOL)isZero;

@end
