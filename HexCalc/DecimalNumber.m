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

#import "DecimalNumber.h"

@implementation DecimalNumber

/*
 * DecimalNumberオブジェクトを初期化します。
 */
- (id)initWithMode:(DisplayMode)mode
{
    self = [super init];
    if (self != nil) {
        d_mode = mode;
        d_str[0] = '\0';
        d_isfloat = NO;
        d_isminus = NO;
    }
    return self;
}

/*
 * DecimalNumberオブジェクトを作成するコンビニエンスコンストラクタです。
 */
+ (id)decimalNumberWithMode:(DisplayMode)mode
{
	id d = [[self alloc] initWithMode: mode];
	return [d autorelease];
}

/*
 * DecimalNumberオブジェクトのデストラクタです。
 */
- (void)dealloc
{
	[super dealloc];
}

static char* strrev(char* str)
{
    char* s = str;
	char* e = str + strlen(str) - 1;

	while (s < e) {
		char t = *s;
		*s = *e;
		*e = t;
		s++;
		e--;
	}
	return str;
}

static BOOL removeDecimalPoint(char* str)
{
    char* p = str;
    char* dpp = NULL;
    while (*p++) {
        if (*p == '.') {
            dpp = p;
            break;
        }
    }
    if (dpp == NULL)
        return YES;     // 小数点なし

    // 小数点以下の後方のゼロを削除します。
    char* lp = str + strlen(str) - 1;
    while (dpp != lp) {
        if (*lp != '0')
            break;
        *lp = '\0';
        lp--;
    }
    if (dpp == lp) {
        // 小数点を削除します。
        *dpp = '\0';
        return YES;
    }
    return NO;
}

// 入力可能文字か判定します。
static BOOL checkInput(DisplayMode mode, const char* cstr)
{
    if (mode == DECIMAL) {
        if (*cstr >= '0' && *cstr <= '9')
            return YES;
    } else if (mode == HEX) {
        if ((*cstr >= '0' && *cstr <= '9') || 
            (*cstr >= 'A' && *cstr <= 'F'))
            return YES;
    } else if (mode == OCTAL) {
        if (*cstr >= '0' && *cstr <= '7')
            return YES;
    } else if (mode == BINARY) {
        if (*cstr == '0' || *cstr == '1')
            return YES;
    }
    return NO;
}

/*
static void str_to_upper(char *s)
{
    while (*s) {
        *s = toupper(*s);
        s++;
    }
}
*/

static void zero_suppress(char* buf, int size)
{
    int i = 0;
    for (; i < size; i++) {
        if (buf[i] != '0')
            break;
    }
    if (i > 0 && buf[i] != '.') {
        int shift_size = size - i;
        memmove(buf, &buf[i], shift_size+1);
    }
}

static void ull_to_decimal(uint64_t n, char* decimal)
{
    sprintf(decimal, "%llu", n);
}

static void ull_to_hex(uint64_t n, char* hex)
{
    sprintf(hex, "%llX", n);
}

static void ull_to_octal(uint64_t n, char* octal)
{
    memset(octal, '0', MAX_OCTAL_LENGTH);
    octal[MAX_OCTAL_LENGTH] = '\0';

    for (int i = MAX_OCTAL_LENGTH-1; i >= 0; i--) {
        if (n <= 0)
            break;
        int m = (int)(n % 8);
        n /= 8;
        octal[i] = (char)('0' + m);
    }

    // 前ゼロを取り除きます。
    zero_suppress(octal, MAX_OCTAL_LENGTH);
}

static void ull_to_bits(uint64_t n, char* bits)
{
    static char* hex_bits_table[] = {
        "0000", "0001", "0010", "0011",
        "0100", "0101", "0110", "0111",
        "1000", "1001", "1010", "1011",
        "1100", "1101", "1110", "1111"
    };

    // 16進文字に変換します。
    char hex[MAX_STRING_SIZE];
    ull_to_hex(n, hex);

    // ビット列表現にします。
    NSUInteger len = strlen(hex);
    *bits = '\0';
    for (int i = 0; i < len; i++) {
        int index;
        if (hex[i] >= '0' && hex[i] <= '9')
            index = hex[i] - '0';
        else
            index = (hex[i] - 'A') + 10;
        strcat(bits, hex_bits_table[index]);
    }

    // 前ゼロを取り除きます。
    zero_suppress(bits, MAX_BINARY_LENGTH);
}

static NSDecimal hex_to_decimal(const char* hex)
{
    uint64_t n = strtoull(hex, NULL, 16);
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%llu", n]];
    return [dnum decimalValue];
}

static NSDecimal octal_to_decimal(const char* octal)
{
    uint64_t n = strtoull(octal, NULL, 8);
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%llu", n]];
    return [dnum decimalValue];
}

static NSDecimal binary_to_decimal(const char* binary)
{
    uint64_t n = strtoull(binary, NULL, 2);
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%llu", n]];
    return [dnum decimalValue];
}

static void decimal_to_hex(const char* decimal, char* hex)
{
    uint64_t n = strtoull(decimal, NULL, 10);
    ull_to_hex(n, hex);
}

static void octal_to_hex(const char* octal, char* hex)
{
    uint64_t n = strtoull(octal, NULL, 8);
    ull_to_hex(n, hex);
}

static void binary_to_hex(const char* binary, char* hex)
{
    uint64_t n = strtoull(binary, NULL, 2);
    ull_to_hex(n, hex);
}

static void decimal_to_octal(const char* decimal, char* octal)
{
    uint64_t n = strtoull(decimal, NULL, 10);
    ull_to_octal(n, octal);
}

static void hex_to_octal(const char* hex, char* octal)
{
    uint64_t n = strtoull(hex, NULL, 16);
    ull_to_octal(n, octal);
}

static void binary_to_octal(const char* binary, char* octal)
{
    uint64_t n = strtoull(binary, NULL, 2);
    ull_to_octal(n, octal);
}

static void decimal_to_binary(const char* decimal, char* binary)
{
    uint64_t n = strtoull(decimal, NULL, 10);
    ull_to_bits(n, binary);
}

static void hex_to_binary(const char* hex, char* binary)
{
    uint64_t n = strtoull(hex, NULL, 16);
    ull_to_bits(n, binary);
}

static void octal_to_binary(const char* octal, char* binary)
{
    uint64_t n = strtoull(octal, NULL, 8);
    ull_to_bits(n, binary);
}

/*
 * [Internal method]
 * 10進数の場合のみ3桁毎にカンマを挿入した文字列を返します。
 */
- (NSString*)formatCommaString:(NSString*)str
{
    if (d_mode != DECIMAL)
        return str;

    char outbuf[MAX_STRING_SIZE];
    NSUInteger len = [str length];
    char* cstr = (char*)[str UTF8String];
    char* p = cstr + len - 1;
    char* outp = outbuf;

    char* periodp = strchr(cstr, '.');
    if (periodp != NULL) {
        while (periodp <= p)
            *outp++ = *p--;
    }
    for (int i = 0; cstr <= p && *p != '-'; i++) {
        if (i != 0 && i % 3 == 0)
            *outp++ = ',';
        *outp++ = *p--;
    }
    if (*cstr == '-')
        *outp++ = '-';
    *outp = '\0';
    strrev(outbuf);
    return [NSString stringWithUTF8String:outbuf];
}

/*
 * [Internal method]
 * 10進数の数値文字列を返します。
 */
- (NSString*)decimalString
{
    if (strlen(d_str) == 0) {
        if (d_isminus)
            return @"-0";
        return @"0";
    }

    if (d_mode == DECIMAL) {
        if (d_isminus)
            return [NSString stringWithFormat:@"-%s", d_str];
        return [NSString stringWithFormat:@"%s", d_str];
    } else if (d_mode == HEX) {
        NSDecimal decimal = hex_to_decimal(d_str);
        return NSDecimalString(&decimal, nil);
    } else if (d_mode == OCTAL) {
        NSDecimal decimal = octal_to_decimal(d_str);
        return NSDecimalString(&decimal, nil);
    } else if (d_mode == BINARY) {
        NSDecimal decimal = binary_to_decimal(d_str);
        return NSDecimalString(&decimal, nil);
    }
    return @"0";
}

/*
 * [Internal method]
 * 16進数の数値文字列を返します。
 */
- (NSString*)hexValue
{
    if (strlen(d_str) == 0)
        return @"0";

    char hexstr[MAX_STRING_SIZE];
    if (d_mode == DECIMAL) {
        decimal_to_hex(d_str, hexstr);
        return [NSString stringWithFormat:@"%s", hexstr];
    } else if (d_mode == HEX) {
        return [NSString stringWithFormat:@"%s", d_str];
    } else if (d_mode == OCTAL) {
        octal_to_hex(d_str, hexstr);
        return [NSString stringWithFormat:@"%s", hexstr];
    } else if (d_mode == BINARY) {
        binary_to_hex(d_str, hexstr);
        return [NSString stringWithFormat:@"%s", hexstr];
    }
    return @"0";
}

/*
 * [Internal method]
 * 8進数の数値文字列を返します。
 */
- (NSString*)octalValue
{
    if (strlen(d_str) == 0)
        return @"0";

    char octalstr[MAX_STRING_SIZE];
    if (d_mode == DECIMAL) {
        decimal_to_octal(d_str, octalstr);
        return [NSString stringWithFormat:@"%s", octalstr];
    } else if (d_mode == HEX) {
        hex_to_octal(d_str, octalstr);
        return [NSString stringWithFormat:@"%s", octalstr];
    } else if (d_mode == OCTAL) {
        return [NSString stringWithFormat:@"%s", d_str];
    } else if (d_mode == BINARY) {
        binary_to_octal(d_str, octalstr);
        return [NSString stringWithFormat:@"%s", octalstr];
    }
    return @"0";
}

/*
 * [Internal method]
 * 2進数の数値文字列を返します。
 */
- (NSString*)binaryValue
{
    if (strlen(d_str) == 0)
        return @"0";

    char binarystr[MAX_STRING_SIZE];
    if (d_mode == DECIMAL) {
        decimal_to_binary(d_str, binarystr);
        return [NSString stringWithFormat:@"%s", binarystr];
    } else if (d_mode == HEX) {
        hex_to_binary(d_str, binarystr);
        return [NSString stringWithFormat:@"%s", binarystr];
    } else if (d_mode == OCTAL) {
        octal_to_binary(d_str, binarystr);
        return [NSString stringWithFormat:@"%s", binarystr];
    } else if (d_mode == BINARY) {
        return [NSString stringWithFormat:@"%s", d_str];
    }
    return @"0";
}

/*
 * パラメータで指定された数値文字列の内容をコピーします。
 */
- (void)copyDecimalNumber:(DecimalNumber*)num
{
    strcpy(d_str, [num cStringValue]);
    d_isfloat = [num isFloatingPoint];
    d_isminus = [num isMinus];
    d_mode = [num mode];
}

/*
 * NSDecimalを表示形式の数値文字列へ設定します。
 */
- (NSString*)setDecimal:(NSDecimal)value
{
    d_isfloat = NO;
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithDecimal:value];
    d_isminus = ([dnum compare:[NSDecimalNumber zero]] == NSOrderedAscending);
    if (d_isminus) {
        // Number is negative. Multiply by -1
        NSDecimalNumber* negativeOne = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:YES];
        dnum = [dnum decimalNumberByMultiplyingBy:negativeOne];
    }
    char tstr[MAX_STRING_SIZE];
    strcpy(tstr, [[dnum stringValue] UTF8String]);
    if (d_mode == HEX)
        decimal_to_hex(tstr, d_str);
    else if (d_mode == OCTAL)
        decimal_to_octal(tstr, d_str);
    else if (d_mode == BINARY)
        decimal_to_binary(tstr, d_str);
    else {
        // 小数点以下がすべてゼロの場合は切り捨てます。
        if (! removeDecimalPoint(tstr))
            d_isfloat = YES;
        strcpy(d_str, tstr);
    }
    return [self stringValue];
}

/*
 * uint64_tの数値を表示形式の数値文字列へ設定します。
 */
- (NSString*)setUint64:(uint64_t)value
{
    d_isfloat = NO;
    d_isminus = NO;

    if (d_mode == DECIMAL)
        ull_to_decimal(value, d_str);
    else if (d_mode == HEX)
        ull_to_hex(value, d_str);
    else if (d_mode == OCTAL)
        ull_to_octal(value, d_str);
    else if (d_mode == BINARY)
        ull_to_bits(value, d_str);

    return [self stringValue];
}

/*
 * 表示形式を設定します。
 */
- (void)setMode:(DisplayMode)mode
{
    d_mode = mode;
}

/*
 * 表示形式を切り替えて現在の値の文字列を返します。
 *
 * 表示形式を切り替えると小数点以下とマイナス符号はクリアされます。
 */
- (NSString*)changeMode:(DisplayMode)mode
{
    if (d_mode == mode)
        return [self stringValue];

    if (strlen(d_str) > 0) {
        char newstr[MAX_STRING_SIZE];
        newstr[0] = '\0';

        switch (mode) {
        case DECIMAL: {
            NSDecimal decimal;
            NSString* str;
            if (d_mode == HEX)
                decimal = hex_to_decimal(d_str);
            else if (d_mode == OCTAL)
                decimal = octal_to_decimal(d_str);
            else if (d_mode == BINARY)
                decimal = binary_to_decimal(d_str);
            str = NSDecimalString(&decimal, nil);
            strcpy(newstr, [str UTF8String]);
            break;
        }
        case HEX:
            if (d_mode == DECIMAL)
                decimal_to_hex(d_str, newstr);
            else if (d_mode == OCTAL)
                octal_to_hex(d_str, newstr);
            else if (d_mode == BINARY)
                binary_to_hex(d_str, newstr);
            break;
        case OCTAL:
            if (d_mode == DECIMAL)
                decimal_to_octal(d_str, newstr);
            else if (d_mode == HEX)
                hex_to_octal(d_str, newstr);
            else if (d_mode == BINARY)
                binary_to_octal(d_str, newstr);
            break;
        case BINARY:
            if (d_mode == DECIMAL)
                decimal_to_binary(d_str, newstr);
            else if (d_mode == HEX)
                hex_to_binary(d_str, newstr);
            else if (d_mode == OCTAL)
                octal_to_binary(d_str, newstr);
            break;
        }
        strcpy(d_str, newstr);
    }
    d_mode = mode;
    d_isfloat = NO;
    d_isminus = NO;
    return [self stringValue];
}

/*
 * 文字列が入力可能かチェックします。
 */
- (BOOL)checkInputKey:(const char*)cstr
{
    if (! checkInput(d_mode, cstr))
        return NO;
    return YES;
}

/*
 * 数値文字列の最後にkey文字を追加します。
 *
 * 入力可能文字
 * (Decimal): 0,1,2,3,4,5,6,7,8,9
 * (Hex):     0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
 * (Octal):   0,1,2,3,4,5,6,7
 * (Binary):  0,1
 */
- (NSString*)inputKey:(const char*)cstr
{
    if (! [self checkInputKey: cstr])
        return [self stringValue];

    NSUInteger len = strlen(d_str);
    if (d_mode == DECIMAL) {
        // 小数点があるため、１桁多く確保してある。
        NSUInteger size = MAX_DECIMAL_LENGTH;
        if (d_isfloat)
            size++;
        if (len + strlen(cstr) > size)
            return [self stringValue];
    } else if (d_mode == HEX) {
        if (len + strlen(cstr) > MAX_HEX_LENGTH)
            return [self stringValue];
    } else if (d_mode == OCTAL) {
        if (len + strlen(cstr) > MAX_OCTAL_LENGTH)
            return [self stringValue];
    } else if (d_mode == BINARY) {
        if (len + strlen(cstr) > MAX_BINARY_LENGTH)
            return [self stringValue];
    }

    /* 2011/08/27
       10 + 0 の式が入力された場合は 0 を有効にするために d_str に入れておく。
       次のkeyが入力された場合は前ゼロを削除してから追加する。*/
    zero_suppress(d_str, (int)strlen(d_str));
    if (strcmp(cstr, "00") == 0) {
        if (*d_str == '\0')
            strcat(d_str, "0");
        else
            strcat(d_str, "00");
    } else {
        strcat(d_str, cstr);
    }

    return [self stringValue];
}

/*
 * 現在の値の最後に小数点（ピリオド）を追加します。
 * 小数点が入力できるのは(Decimal)の場合のみです。
 */
- (NSString*)inputPoint
{
    if (d_mode != DECIMAL)
        return [self stringValue];

    if (d_isfloat)
        return [self stringValue];

    if (strlen(d_str) == 0)
        strcpy(d_str, "0.");
    else
        strcat(d_str, ".");

    d_isfloat = YES;
    return [self stringValue];
}

/*
 * 現在の値の符号を反転します。
 * 符号を反転できるのは(Decimal)の場合のみです。
 */
- (NSString*)inputPlusMinus
{
    if (d_mode != DECIMAL)
        return [self stringValue];

    if (strlen(d_str) == 0)
        return [self stringValue];

    d_isminus = (d_isminus)? NO : YES;
    return [self stringValue];
}

/*
 * 現在の値の最後の文字を削除します。
 */
- (NSString*)delete
{
    NSUInteger len = strlen(d_str);
    if (len < 1)
        return [self stringValue];
    if (strcmp(d_str, "0.") == 0)
        return [self clear];

    if (d_mode == DECIMAL) {
        if (d_str[len-1] == '.')
            d_isfloat = NO;
    }
    d_str[len-1] = '\0';
    if (d_isminus && len <= 1)
        d_isminus = NO;
    return [self stringValue];
}

/*
 * 現在の値をクリアしてゼロの文字列を返します。
 * [メモリ]内容はクリアしません。
 *
 * v1.0.2 2011/9/17
 *     d_modeを DECIMAL でクリアしていたバグを修正。
 */
- (NSString*)clear
{
    d_str[0] = '\0';
    d_isfloat = NO;
    d_isminus = NO;

    return [self stringValue];
}

/*
 * 現在の値が空値か判定します。
 */
- (BOOL)isEmpty
{
    return (d_str[0] == '\0');
}

/*
 * C言語形式の数値文字列を返します。
 */
- (const char*)cStringValue
{
    return d_str;
}

/*
 * 浮動小数点かどうかを返します。
 */
- (BOOL)isFloatingPoint
{
    return d_isfloat;
}

/*
 * マイナス値かどうかを返します。
 */
- (BOOL)isMinus
{
    return d_isminus;
}

/*
 * 表示形式を返します。
 */
- (DisplayMode)mode
{
    return d_mode;
}

/*
 * 表示形式の値を返します。
 * 10進数の場合は3桁ごとにカンマを挿入した文字列を返します。
 */
- (NSString*)stringValue
{
    if (d_mode == DECIMAL)
        return [self formatCommaString:[self decimalString]];
    else if (d_mode == HEX)
        return [self hexValue];
    else if (d_mode == OCTAL)
        return [self octalValue];
    else if (d_mode == BINARY)
        return [self binaryValue];

    return @"0";
}

/*
 * NSDecimalを返します。
 */
- (NSDecimal)decimalValue
{
    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithString:@"0"];
    if (strlen(d_str) == 0)
        return [dnum decimalValue];

    if (d_mode == DECIMAL) {
        if (d_isminus)
            dnum = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"-%s", d_str]];
        else
            dnum = [NSDecimalNumber decimalNumberWithString:[NSString stringWithUTF8String:d_str]];
        return [dnum decimalValue];
    } else if (d_mode == HEX)
        return hex_to_decimal(d_str);
    else if (d_mode == OCTAL)
        return octal_to_decimal(d_str);
    else if (d_mode == BINARY)
        return binary_to_decimal(d_str);

    return [dnum decimalValue];
}

- (uint64_t)uint64
{
    if (d_mode == DECIMAL)
        return strtoull(d_str, NULL, 10);
    else if (d_mode == HEX)
        return strtoull(d_str, NULL, 16);
    else if (d_mode == OCTAL)
        return strtoull(d_str, NULL, 8);
    else if (d_mode == BINARY)
        return strtoull(d_str, NULL, 2);
    return 0;
}

/*
 * 左へ1ビットシフトします。
 */
- (NSString*)shiftLeftBit
{
    if (d_mode == HEX) {
        uint64_t n = strtoull(d_str, NULL, 16) << 1;
        ull_to_hex(n, d_str);
    } else if (d_mode == OCTAL) {
        uint64_t n = strtoull(d_str, NULL, 8) << 1;
        ull_to_octal(n, d_str);
    } else if (d_mode == BINARY) {
        uint64_t n = strtoull(d_str, NULL, 2) << 1;
        ull_to_bits(n, d_str);
    }
    return [self stringValue];
}

/*
 * 右へ1ビットシフトします。
 */
- (NSString*)shiftRightBit
{
    if (d_mode == HEX) {
        uint64_t n = strtoull(d_str, NULL, 16) >> 1;
        ull_to_hex(n, d_str);
    } else if (d_mode == OCTAL) {
        uint64_t n = strtoull(d_str, NULL, 8) >> 1;
        ull_to_octal(n, d_str);
    } else if (d_mode == BINARY) {
        uint64_t n = strtoull(d_str, NULL, 2) >> 1;
        ull_to_bits(n, d_str);
    }
    return [self stringValue];
}

- (BOOL)isZero
{
    if (strlen(d_str) == 0)
        return YES;

    NSDecimalNumber* dnum = [NSDecimalNumber decimalNumberWithDecimal:[self decimalValue]];
    return ([dnum compare:[NSDecimalNumber zero]] == NSOrderedSame);
}

@end
