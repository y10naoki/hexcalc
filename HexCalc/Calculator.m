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

#import "Calculator.h"

@implementation Calculator

/*
 * Calculatorオブジェクトを初期化します。
 */
- (id)initWithMode:(DisplayMode)mode
{
    self = [super init];
    if (self != nil) {
        c_mode = mode;
        c_op = NONE;
        c_flags = CALC_CLEAR_CURRENT;

        c_formula = [[Formula alloc] init];

        c_decimal_cur = [[DecimalNumber alloc] initWithMode:DECIMAL];
        c_decimal_mem = [[DecimalNumber alloc] initWithMode:DECIMAL];

        c_op_last = NONE;
        c_decimal_last = [[DecimalNumber alloc] initWithMode:DECIMAL];
    }
    return self;
}

/*
 * Calculatorオブジェクトを作成するコンビニエンスコンストラクタです。
 */
+ (id)calculatorWithMode:(DisplayMode)mode
{
	id c = [[self alloc] initWithMode:mode];
	return [c autorelease];
}

/*
 * Calculatorオブジェクトのデストラクタです。
 */
- (void)dealloc
{
    [c_formula release];
    [c_decimal_cur release];
    [c_decimal_mem release];
    [c_decimal_last release];

	[super dealloc];
}

/*
 * 計算可能かどうかを返します。
 */
- (BOOL)enableCalculatorOperator:(Operator)op
{
    if (c_op == NONE)
        return NO;
    if (! (c_flags & CALC_INPUT_DECIMAL))
        return NO;
    return [c_formula enableComputeWithOperator:op];
}

/*
 * '='キーが押されたときに計算可能かどうかを返します。
 */
- (BOOL)enableCalculatorEqual
{
    if ([c_decimal_cur isEmpty])
        return NO;
    // = の後に続けて = が押されたか、演算子が入力されている場合は計算可能。
    if ((c_flags & CALC_DONE) || (c_op != NONE))
        return YES;
    return [c_formula enableComputeEqual];
}

/*
 * 表示形式を切り替えて現在の値の文字列を返します。
 */
- (NSString*)changeMode:(DisplayMode)mode
{
    c_mode = mode;
    [c_decimal_last changeMode:mode];
    return [c_decimal_cur changeMode:mode];
}

/*
 * 現在の値の最後にkey文字を追加します。
 */
- (NSString*)inputKey:(NSString*)key
{
    // 演算子が入力された直後は現在の値をクリアする。
    if (c_flags & CALC_CLEAR_CURRENT) {
        [c_decimal_cur clear];
        c_flags &= ~CALC_CLEAR_CURRENT;
    }
    c_flags |= CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;
    return [c_decimal_cur inputKey:[key UTF8String]];
}

/*
 * 現在の値の最後に小数点（ピリオド）を追加します。
 * 小数点が入力できるのは(Decimal)の場合のみです。
 */
- (NSString*)inputPoint
{
    NSString* str;
    if (c_mode == DECIMAL) {
        // 演算子が入力された直後は現在の値をクリアする。
        if (c_flags & CALC_CLEAR_CURRENT) {
            [c_decimal_cur clear];
            c_flags &= ~CALC_CLEAR_CURRENT;
        }
        str = [c_decimal_cur inputPoint];
    } else {
        str = [c_decimal_cur stringValue];
    }
    c_flags |= CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;
    return str;
}

/*
 * 現在の値の符号を反転します。
 * 符号反転は(Decimal)の場合のみです。
 */
- (NSString*)inputPlusMinus
{
    NSString* str;
    if (c_mode == DECIMAL)
        str = [c_decimal_cur inputPlusMinus];
    else
        str = [c_decimal_cur stringValue];
    c_flags |= CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;
    return str;
}

/*
 * 現在の値の最後の文字を削除します。
 */
- (NSString*)deleteKey
{
    c_flags |= CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;
    return [c_decimal_cur delete];
}

/*
 * 演算子を登録します。
 *
 * 演算子が続けて入力された場合は演算子を置換します。
 * 値が入力されている場合は現在の値と演算子を計算式に追加します。
 */
- (NSString*)inputOperator:(Operator)op
{
    c_op = op;

    if ((c_flags & CALC_CLEAR_CURRENT) && [c_formula count] > 0) {
        // 続けて演算子が入力されたので演算子を置換します。
        [c_formula inputOperator:op];
    } else {
        c_flags |= CALC_CLEAR_CURRENT;
        c_flags &= ~CALC_INPUT_DECIMAL;
        if (op != NONE)
            c_flags &= ~CALC_DONE;

        // 現在の値を式に追加します。
        [c_formula inputDecimal:c_decimal_cur];

        // 計算可能であれば計算します。
        if ([c_formula enableComputeWithOperator:op])
            [c_formula computeAnswerDecimal:c_decimal_cur];

        // 演算子を式に追加します。
        [c_formula inputOperator:op];
    }
    
    return [c_decimal_cur stringValue];
}

/*
 * 計算を行い結果を文字列として返します。
 * 計算結果が現在の値になります。
 */
- (NSString*)calculate
{
    if (c_flags & CALC_DONE) {
        // = の後に続けて = が押された。

        // 前回の値がゼロの場合は結果が変わらないため無視します。
        if ([c_decimal_last isZero])
            return [c_decimal_cur stringValue];
            
        // 現在の値を式に登録します。
        [c_formula inputDecimal:c_decimal_cur];

        // last -> cur
        [c_decimal_cur copyDecimalNumber:c_decimal_last];
        // last_op -> c_op
        c_op = c_op_last;

        // 演算子を式に登録します。
        [c_formula inputOperator:c_op];
    } else {
        // 計算可能かチェックします。
        if (c_op == NONE)
            return [c_decimal_cur stringValue];

        // = が続けて押された場合のために現在の値を保存しておきます。
        c_op_last = c_op;
        [c_decimal_last copyDecimalNumber:c_decimal_cur];
    }
    
    // 演算子をクリアします。
    c_op = NONE;

    c_flags |= CALC_CLEAR_CURRENT;
    c_flags &= ~CALC_INPUT_DECIMAL;
    c_flags |= CALC_DONE;

    // 現在の値を式に追加します。
    [c_formula inputDecimal:c_decimal_cur];

    // 計算を行います。
    BOOL result = [c_formula computeAnswerDecimal:c_decimal_cur];

    // 計算式のクリア
    [c_formula clear];

    if (! result) {
        [c_decimal_cur clear];
        return @"Error";
    }
    return [c_decimal_cur stringValue];
}

/*
 * 現在の値をクリアしてゼロの文字列を返します。
 *
 * 計算履歴から編集中の式をクリアします。
 * [メモリ]内容はクリアしません。
 */
- (NSString*)clearAll
{
    c_op = NONE;
    c_flags &= ~CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;

    [c_formula clear];
    return [c_decimal_cur clear];
}

/*
 * 現在の値を表示形式の文字列としてかえします。
 */
- (NSString*)currentValue
{
    return [c_decimal_cur stringValue];
}

/*
 * 現在の値を[メモリ]に設定します。
 */
- (BOOL)inMemory
{
    const char* str = [c_decimal_cur cStringValue];
    if (*str == '\0')
        return NO;

    [c_decimal_mem copyDecimalNumber:c_decimal_cur];
    c_flags |= CALC_EXIST_MEMORY;
    return YES;
}

/*
 * [メモリ]に現在の値を加算します。
 */
- (BOOL)plusMemory
{
    const char* str = [c_decimal_cur cStringValue];
    if (*str == '\0')
        return NO;

    if ([c_formula addDecimal:c_decimal_mem
                      decimal:c_decimal_cur
                answerDecimal:c_decimal_mem] == nil)
        return NO;

    [c_decimal_mem changeMode:[c_decimal_cur mode]];

    c_flags |= CALC_EXIST_MEMORY;
    return YES;
}

/*
 * [メモリ]から現在の値を減算します。
 */
- (BOOL)minusMemory
{
    const char* str = [c_decimal_cur cStringValue];
    if (*str == '\0')
        return NO;
    
    if ([c_formula subtractDecimal:c_decimal_mem
                           decimal:c_decimal_cur
                     answerDecimal:c_decimal_mem] == nil)
        return NO;

    [c_decimal_mem changeMode:[c_decimal_cur mode]];

    c_flags |= CALC_EXIST_MEMORY;
    return YES;
}

/*
 * [メモリ]領域の文字列を現在の値に設定して現在の値を返します。
 * 表示モードは現在のモードが使用されます。
 */
- (NSString*)readMemory
{
    if (! (c_flags & CALC_EXIST_MEMORY))
        return [c_decimal_cur stringValue];

    [c_decimal_cur copyDecimalNumber:c_decimal_mem];

    c_flags |= CALC_CLEAR_CURRENT;
    c_flags |= CALC_INPUT_DECIMAL;
    c_flags &= ~CALC_DONE;

    NSString* str;
    if (c_mode == [c_decimal_cur mode]) {
        str = [c_decimal_cur stringValue];
    } else {
        // 現在のモードに変換します。
        str = [self changeMode:c_mode];
    }
    return str;
}

/*
 * [メモリ]領域をクリアします。
 */
- (void)clearMemory
{
    c_flags &= ~CALC_EXIST_MEMORY;
    [c_decimal_mem clear];
}

/*
 * [メモリ]の mode を返します。
 */
- (DisplayMode)memoryMode
{
    return [c_decimal_mem mode];
}

/*
 * [メモリ]の値を表示形式の文字列としてかえします。
 */
- (NSString*)memoryValue
{
    return [c_decimal_mem stringValue];
}

/*
 * 左へ1ビットシフトします。
 */
- (NSString*)shiftLeftBit
{
    return [c_decimal_cur shiftLeftBit];
}

/*
 * 右へ1ビットシフトします。
 */
- (NSString*)shiftRightBit
{
    return [c_decimal_cur shiftRightBit];
}

/*
 * Calculatorオブジェクトの mode を返します。
 */
- (DisplayMode)mode
{
    return c_mode;
}

@end
