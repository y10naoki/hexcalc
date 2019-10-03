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
#import "DecimalNumber.h"

typedef enum {
    NONE,
    ADD,
    SUBTRACT,
    MULTIPLY,
    DIVIDE,
    BIT_OR,
    BIT_AND,
    BIT_XOR
} Operator;


#define MAX_DECIMAL_VALUE   ULLONG_MAX    // 18,446,744,073,709,551,615

// Formula
@interface Formula : NSObject {
    NSMutableArray* f_cell_array;
}

- (id)init;
- (void)dealloc;

+ (BOOL)isValidDecimal:(NSDecimal)value;

- (void)clear;
- (NSUInteger)count;

- (void)inputOperator:(Operator)op;
- (void)inputDecimal:(DecimalNumber*)number;

- (BOOL)enableComputeWithOperator:(Operator)op;
- (BOOL)enableComputeEqual;
- (BOOL)computeAnswerDecimal:(DecimalNumber*)ans;

- (NSString*)addDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;
- (NSString*)subtractDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;
- (NSString*)multiplyDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;
- (NSString*)divideDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;

- (NSString*)andDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;
- (NSString*)orDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;
- (NSString*)xorDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval answerDecimal:(DecimalNumber*)ans;

- (NSArray*)formula;

@end
