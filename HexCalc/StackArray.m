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

#import "StackArray.h"

@implementation StackArray

/*
 * StackArrayオブジェクトを初期化します。
 */
- (id)init
{
    self = [super init];
    if (self != nil) {
        s_array = [[NSMutableArray alloc] init];
    }
    s_pos = -1;
    return self;
}

/*
 * StackArrayオブジェクトを作成するコンビニエンスコンストラクタです。
 */
+ (id)stackArray
{
	id p = [[self alloc] init];
	return [p autorelease];
}

/*
 * StackArrayオブジェクトのデストラクタです。
 */
- (void)dealloc
{
    [s_array release];

	[super dealloc];
}

/*
 * push
 */
- (void)pushObject: (id)object
{
    [s_array addObject: object];
    s_pos++;
}

/*
 * pop
 */
- (id)pop
{
    if (s_pos < 0 || s_pos >= [s_array count])
        return nil;
    id obj = [s_array objectAtIndex: s_pos];
    [s_array removeObjectAtIndex: s_pos];
    s_pos--;
    return obj;
}

@end
