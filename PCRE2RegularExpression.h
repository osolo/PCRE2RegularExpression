//
// PCRE2RegularExpression.h
// Scribe
//
// Created by Oz Solomon on 2016-02-20.
// Copyright © 2016 Social Graph Studios. All rights reserved.
//
// MIT LICENSE
// 
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation 
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
// 


@import Foundation;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const PCRE2RegularExpressionErrorOffsetKey;


@interface PCRE2RegularExpression : NSRegularExpression

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithPattern:(NSString *)pattern 
                                 options:(NSRegularExpressionOptions)options 
                                   error:(NSError * _Nullable *)error NS_DESIGNATED_INITIALIZER;
+ (nullable instancetype)regularExpressionWithPattern:(NSString *)pattern 
                                              options:(NSRegularExpressionOptions)options 
                                                error:(NSError * _Nullable *)error;


/**
 * Adds backslash escapes as necessary to the given string, to escape any 
 * characters that would otherwise be treated as pattern meta-characters.
 */
//+ (NSString *)escapedPatternForString:(NSString *)string;

#pragma mark - Matching

- (void)enumerateMatchesInString:(NSString *)string 
                         options:(NSMatchingOptions)options 
                           range:(NSRange)range 
                      usingBlock:(void (^)(NSTextCheckingResult * __nullable result, NSMatchingFlags flags, BOOL *stop))block;

- (NSArray<NSTextCheckingResult *> *)matchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (NSUInteger)numberOfMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (nullable NSTextCheckingResult *)firstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (NSRange)rangeOfFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;


#pragma mark - Replacement

- (NSString *)stringByReplacingMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ;
- (NSUInteger)replaceMatchesInString:(NSMutableString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ;
- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result inString:(NSString *)string offset:(NSInteger)offset template:(NSString *)templ;
+ (NSString *)escapedTemplateForString:(NSString *)string;


#pragma mark - PCRE Specific

/**
 * Returns the capture group index of a named capture group, or NSNotFound.
 * 
 * The result of calling this function for a non-unique capture group name is 
 * undefined.
 */
- (NSUInteger)indexOfNamedCaptureGroup:(NSString *)name;

/**
 * Returns the range of a named capture group matched by this regular 
 * expression.
 * 
 * @param name The name of the capture group from the regex pattern.
 * @param textCheckingResult A result returned by one of the matching methods.
 * @return The matched ranged.
 */
- (NSRange)rangeOfNamedCapture:(NSString *)name inTextCheckingResult:(NSTextCheckingResult *)textCheckingResult;

@end

NS_ASSUME_NONNULL_END