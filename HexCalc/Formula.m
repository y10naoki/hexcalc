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

#import "Formula.h"
#import "StackArray.h"

@implementation Formula

/*
 * Formulaオブジェクトを初期化します。
 */
- (id)init
{
    self = [super init];
    if (self != nil) {
        f_cell_array = [[NSMutableArray alloc] init];
    }
    return self;
}

/*
 * Formulaオブジェクトのデストラクタです。
 */
- (void)dealloc
{
    for (id cell in f_cell_array)
        [cell release];
    [f_cell_array release];

	[super dealloc];
}

/*
static BOOL check_overflow_add(int64_t x, int64_t y)
{
    return (((x > 0 && y > 0) && (x > INT64_MAX - y)) ||
            ((x < 0 && y < 0) && (x < INT64_MIN - y)));
}

static BOOL check_overflow_sub(int64_t x, int64_t y)
{
    return (((x > 0 && y < 0) && (x > INT64_MAX + y)) ||
            ((x < 0 && y > 0) && (x < INT64_MIN + y)));
}

static BOOL check_overflow_mul(int64_t x, int64_t y)
{
    if (y == -1)
        return (x == INT64_MIN);
    return ((y > 0 && (x > INT64_MAX / y || x < INT64_MIN / y)) ||
            (y < 0 && (x < INT64_MAX / y || x > INT64_MIN / y)));
}

static BOOL check_overflow_div(int64_t x, int64_t y)
{
    return ((y == 0) || (x == INT64_MIN && y == -1));
}
*/

+ (BOOL)isValidDecimal:(NSDecimal)value
{
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithDecimal:value];
    BOOL isminus = ([dnum compare:[NSNumber numberWithInt:0]] == NSOrderedAscending);

    if (isminus) {
        // underflow check
        NSDecimalNumber* dmin = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"-%llu", MAX_DECIMAL_VALUE]];
        NSDecimal x = [dnum decimalValue];
        NSDecimal y = [dmin decimalValue];
        if (NSDecimalCompare (&x, &y) == NSOrderedAscending)
            return NO;
    } else {
        // overflow check
        NSDecimalNumber* dmax = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%llu", MAX_DECIMAL_VALUE]];
        NSDecimal x = [dnum decimalValue];
        NSDecimal y = [dmax decimalValue];
        if (NSDecimalCompare (&x, &y) == NSOrderedDescending)
            return NO;
    }
    return YES;
}

/*
 * 式をクリアします。
 */
- (void)clear
{
    for (id cell in f_cell_array)
        [cell release];
    [f_cell_array removeAllObjects];
}

/*
 * 式を項目数を返します。
 */
- (NSUInteger)count
{
    return [f_cell_array count];
}

/*
 * 演算子を式に登録します。
 */
- (void)inputOperator:(Operator)op
{
    NSUInteger n = [f_cell_array count];
    if (n > 0) {
        NSUInteger last_index = n - 1;
        // 末尾のセルが数値かチェックします。
        id obj = [f_cell_array objectAtIndex:last_index];
        if ([obj isKindOfClass:[NSNumber class]]) {
            // 末尾の演算子を置き換えます。
            [f_cell_array removeObjectAtIndex:last_index];
            [obj release];
        }
    }
    NSNumber* op_num = [[NSNumber alloc] initWithInt:op];
    [f_cell_array addObject:op_num];
}

/*
 * 値を式に登録します。
 * 値のコピーを作成して登録します。
 */
- (void)inputDecimal:(DecimalNumber*)number
{
    NSUInteger n = [f_cell_array count];
    if (n > 0) {
        NSUInteger last_index = n - 1;
        // 末尾のセルが演算子かチェックします。
        id obj = [f_cell_array objectAtIndex:last_index];
        if ([obj isKindOfClass:[DecimalNumber class]]) {
            // 末尾の値を置き換えます。
            [f_cell_array removeObjectAtIndex:last_index];
            [obj release];
        }
    }
    DecimalNumber* val = [[DecimalNumber alloc] initWithMode:[number mode]];
    [val copyDecimalNumber:number];
    [f_cell_array addObject:val];
}

/*
 * [Internal method]
 * 演算子の優先順位値を求めます。
 */
- (NSInteger)priorityOperator:(Operator)op
{
    switch (op) {
    case ADD:
    case SUBTRACT:
        return 20;
    case MULTIPLY:
    case DIVIDE:
        return 30;
    case BIT_AND:
    case BIT_OR:
    case BIT_XOR:
        return 10;
    default:
        break;
    }
    return 0;
}

/*
 * 計算可能かどうかを返します。
 *
 * 最後の演算子と OP の演算レベルの関係で判定します。
 *
 * 演算子  OP  関係  結果
 *-------------------------
 *   +,-   *    <     不可
 *   *,/   +    >     可
 *   +     -    =     可（但しすべて同じ演算レベルであること）
 *-------------------------
 *
 * 1 + 2 * 3 (op)= ->YES
 * 1 + 2 * 3 (op)* ->NO
 * 1 + 2 (op)+ -> YES
 * 1 + 2 (op)* -> NO
 * 1 + 2 * 3 (op)+ ->YES
 * 1 + 2 + 3 (op)+ ->YES
 * 1 + 2 * 3 (op)* ->NO
 */
- (BOOL)enableComputeWithOperator:(Operator)op
{
    NSUInteger n = [f_cell_array count];
    if (n < 3)
        return NO;

    NSInteger op_priority = [self priorityOperator:op];
    if (op_priority == 0)
        return YES;  // '='が入力された

    NSInteger last_cell_priority = 0;
    for (id cell in f_cell_array) {
        if ([cell isKindOfClass:[NSNumber class]])
            last_cell_priority = [self priorityOperator:[(NSNumber*)cell intValue]];
    }
    if (last_cell_priority == 0)
        return NO;

    if (op_priority < last_cell_priority)
        return YES;
    if (op_priority > last_cell_priority)
        return NO;
    for (id cell in f_cell_array) {
        if ([cell isKindOfClass:[NSNumber class]]) {
            if (op_priority != [self priorityOperator:[(NSNumber*)cell intValue]])
                return NO;
        }
    }
    return YES;
}

/*
 * '='が押された場合に計算可能かどうかを返します。
 */
- (BOOL)enableComputeEqual
{
    return [self enableComputeWithOperator:NONE];
}

/*
 * [Internal method]
 * 逆ポーランド記法の配列に変換します。
 */
- (void)doReversePolishNotationArray:(NSMutableArray*)rpn_array
{
    StackArray* stack = [[StackArray alloc] init];

    NSNumber* stack_op;
    for (id cell in f_cell_array) {
        if ([cell isKindOfClass:[DecimalNumber class]]) {
            // 数値はそのまま出力
            [rpn_array addObject:cell];
        } else {
            // 演算子の場合はスタックの先頭と優先順位を比較して
            // スタックの先頭の優先度が低くなるまでスタックの内容を書き出す
            // その後、読んだ演算子をスタックに積む
            stack_op = [stack pop];
            if (stack_op != nil) {
                NSInteger stack_priority = [self priorityOperator:[stack_op intValue]];
                NSInteger cell_priority = [self priorityOperator:[(NSNumber*)cell intValue]];
                if (cell_priority > stack_priority) {
                    // スタックの先頭より優先順位の高い演算子はスタックに積む
                    [stack pushObject:stack_op];
                } else {
                    // スタックの値と比較してスタックの方が優先順位が高いか等しい演算子を書き出す
                    while (stack_op != nil) {
                        stack_priority = [self priorityOperator:[stack_op intValue]];
                        if (stack_priority >= cell_priority) {
                            [rpn_array addObject:stack_op];
                            stack_op = [stack pop];
                        } else {
                            [stack pushObject:stack_op];
                            break;
                        }
                    }
                }
            }
            [stack pushObject:cell];
        }
    }
    // スタックの内容をすべて書き出す
    while ((stack_op = [stack pop]) != nil)
        [rpn_array addObject:stack_op];

    [stack release];
}

/*
 * [Internal method]
 * 逆ポーランド記法の数式を計算して答えを ans に設定します。
 */
- (BOOL)calcReversePolishNotationArray:(NSMutableArray*)rpn_array
                         answerDecimal:(DecimalNumber*)ans
{
    StackArray* stack = [[StackArray alloc] init];
    NSMutableArray* val_array = [[NSMutableArray alloc] init];
    BOOL result = NO;

    for (id cell in rpn_array) {
        if ([cell isKindOfClass:[DecimalNumber class]]) {
            // 数値の場合はスタックに積む
            [stack pushObject:cell];
        } else {
            // 演算子の場合はスタックから２つ数値を取り出して計算し、結果をスタックに積む
            Operator op = [(NSNumber*)cell intValue];
            DecimalNumber* v2 = [stack pop];
            DecimalNumber* v1 = [stack pop];
            if (v1 == nil || v2 == nil) {
                if (v2 != nil) {
                    [ans copyDecimalNumber:v2];
                    result = YES;
                }
                goto final;
            }

            // 一時的な答えの領域を確保
            DecimalNumber* val = [[DecimalNumber alloc] initWithMode:[ans mode]];
            [val_array addObject:val];

            switch (op) {
            case ADD:
                if ([self addDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case SUBTRACT:
                if ([self subtractDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case MULTIPLY:
                if ([self multiplyDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case DIVIDE:
                if ([self divideDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case BIT_AND:
                if ([self andDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case BIT_OR:
                if ([self orDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            case BIT_XOR:
                if ([self xorDecimal:v1 decimal:v2 answerDecimal:val] == nil)
                    goto final;
                break;
            default:
                goto final;
            }
            // 答えをスタックに積む
            [stack pushObject:val];
        }
    }
    // 最終的な答えをスタックから取り出す
    DecimalNumber* num = [stack pop];
    [ans copyDecimalNumber:num];
    result = YES;

final:
    for (id val in val_array)
        [val release];
    [val_array release];

    [stack release];
    return result;
}

/*
 * 逆ポーランド記法で計算して答えを answer オブジェクトに設定します。
 * Reverse Polish Notation: RPN
 */
- (BOOL)computeAnswerDecimal:(DecimalNumber*)ans
{
    NSMutableArray* rpn_array = [[NSMutableArray alloc] init];

    // 逆ポーランド記法に変換します。
    [self doReversePolishNotationArray:rpn_array];

    // 逆ポーランド記法の数式を計算します。
    BOOL result = [self calcReversePolishNotationArray:rpn_array answerDecimal:ans];

    [rpn_array release];
    return result;
}

- (BOOL)isSignedModeDecimal:(DecimalNumber*)xval decimal:(DecimalNumber*)yval
{
    DisplayMode xmode = [xval mode];
    DisplayMode ymode = [yval mode];
    if (xmode == DECIMAL || ymode == DECIMAL)
        return YES;
    return NO;
}

/*
 * 加算処理を行います。
 * ans = xval + yval
 */
- (NSString*)addDecimal:(DecimalNumber*)xval
                decimal:(DecimalNumber*)yval
          answerDecimal:(DecimalNumber*)ans
{
    NSDecimal x = [xval decimalValue];
    NSDecimal y = [yval decimalValue];
    NSDecimal r;
    NSCalculationError err = NSDecimalAdd(&r, &x, &y, NSRoundPlain);
    if (err != NSCalculationNoError && err != NSCalculationLossOfPrecision)
        return nil;
    if (! [Formula isValidDecimal:r])
        return nil;
    return [ans setDecimal:r];
}

/*
 * 減算処理を行います。
 * ans = xval - yval
 */
- (NSString*)subtractDecimal:(DecimalNumber*)xval
                     decimal:(DecimalNumber*)yval
               answerDecimal:(DecimalNumber*)ans
{
    NSDecimal x = [xval decimalValue];
    NSDecimal y = [yval decimalValue];
    NSDecimal r;
    NSCalculationError err = NSDecimalSubtract(&r, &x, &y, NSRoundPlain);
    if (err != NSCalculationNoError && err != NSCalculationLossOfPrecision)
        return nil;
    if (! [Formula isValidDecimal:r])
        return nil;
    return [ans setDecimal:r];
}

/*
 * 乗算処理を行います。
 * ans = xval * yval
 */
- (NSString*)multiplyDecimal:(DecimalNumber*)xval
                     decimal:(DecimalNumber*)yval
               answerDecimal:(DecimalNumber*)ans
{
    NSDecimal x = [xval decimalValue];
    NSDecimal y = [yval decimalValue];
    NSDecimal r;
    NSCalculationError err = NSDecimalMultiply(&r, &x, &y, NSRoundPlain);
    if (err != NSCalculationNoError && err != NSCalculationLossOfPrecision)
        return nil;
    if (! [Formula isValidDecimal:r])
        return nil;
    return [ans setDecimal:r];
}

/*
 * 除算処理を行います。
 * ans = xval / yval
 */
- (NSString*)divideDecimal:(DecimalNumber*)xval
                   decimal:(DecimalNumber*)yval
             answerDecimal:(DecimalNumber*)ans
{
    if ([yval isZero])
        return nil;

    NSDecimal x = [xval decimalValue];
    NSDecimal y = [yval decimalValue];
    NSDecimal r;
    NSCalculationError err = NSDecimalDivide(&r, &x, &y, NSRoundPlain);
    if (err != NSCalculationNoError && err != NSCalculationLossOfPrecision)
        return nil;
    if (! [Formula isValidDecimal:r])
        return nil;
    return [ans setDecimal:r];
}

/*
 * ビット列のAND処理を行います。
 * ans = xval & yval
 */
- (NSString*)andDecimal:(DecimalNumber*)xval
                decimal:(DecimalNumber*)yval
          answerDecimal:(DecimalNumber*)ans
{
    uint64_t x = [xval uint64];
    uint64_t y = [yval uint64];
    uint64_t a = x & y;
    return [ans setUint64:a];
}

/*
 * ビット列のOR処理を行います。
 * ans = xval | yval
 */
- (NSString*)orDecimal:(DecimalNumber*)xval
               decimal:(DecimalNumber*)yval
         answerDecimal:(DecimalNumber*)ans
{
    uint64_t x = [xval uint64];
    uint64_t y = [yval uint64];
    uint64_t a = x | y;
    return [ans setUint64:a];
}

/*
 * ビット列のXOR処理を行います。
 * ans = xval ^ yval
 */
- (NSString*)xorDecimal:(DecimalNumber*)xval
                decimal:(DecimalNumber*)yval
          answerDecimal:(DecimalNumber*)ans
{
    uint64_t x = [xval uint64];
    uint64_t y = [yval uint64];
    uint64_t a = x ^ y;
    return [ans setUint64:a];
}

/*
 * 式を配列として返します。
 */
- (NSArray*)formula
{
    return f_cell_array;
}

@end
