//
// PCRE2RegularExpression.m
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


#import "PCRE2RegularExpression.h"
#include <wchar.h>

#define PCRE2_CODE_UNIT_WIDTH 16

#import <pcre2.h>

NSString * const PCRE2RegularExpressionErrorDomain = @"PCRE2RegularExpression";
NSString * const PCRE2RegularExpressionErrorOffsetKey = @"offset";

const PCRE2_SIZE CAPTURE_NOT_FOUND = (PCRE2_SIZE)-1;

@interface PCRE2RegularExpression() {
    pcre2_code *pcre;
    int patternCaptureCount;
}

@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *namedCaptureGroupsIndexes;

@end

@implementation PCRE2RegularExpression


- (nullable instancetype)initWithPattern:(NSString *)pattern 
                                 options:(NSRegularExpressionOptions)options 
                                   error:(NSError * _Nullable *)error
{
    if (!(self = [super initWithPattern:@"a" options:options error:nil])) { return nil; }

    NSAssert(sizeof(unichar) == sizeof(PCRE2_UCHAR16), @"unexpected character sizes");

    self->pcre = NULL;
    
    self->_pattern = pattern;
    
    int pcreOptions = PCRE2_UTF | PCRE2_UCP;
    if (options & NSRegularExpressionCaseInsensitive)
    {
        pcreOptions |= PCRE2_CASELESS;
    }
    if (options & NSRegularExpressionAllowCommentsAndWhitespace)
    {
        pcreOptions |= PCRE2_EXTENDED;
    }
    if (options & NSRegularExpressionIgnoreMetacharacters)
    {
        NSAssert(false, @"NSRegularExpressionIgnoreMetacharacters is currently not supported");
    }
    if (options & NSRegularExpressionDotMatchesLineSeparators)
    {
        pcreOptions |= PCRE2_DOTALL;
    }
    if (options & NSRegularExpressionAnchorsMatchLines)
    {
        pcreOptions |= PCRE2_MULTILINE;
    }
    if (options & NSRegularExpressionUseUnixLineSeparators)
    {
        pcreOptions |= PCRE2_NEWLINE_ANY;
    }
    if (options & NSRegularExpressionUseUnicodeWordBoundaries)
    {
        NSAssert(false, @"NSRegularExpressionUseUnicodeWordBoundaries is currently not supported");
    }
    
    int pcreErrorCode = 0;
    PCRE2_SIZE pcreErrorOffset = 0;
    unichar *cstrPattern = malloc((pattern.length + 1) * sizeof(unichar));
    [pattern getCharacters:cstrPattern range:NSMakeRange(0, pattern.length)];
    //(PCRE2_SPTR8)pattern.UTF8String;
    self->pcre = pcre2_compile(cstrPattern,
                               pattern.length,
                               pcreOptions, 
                               &pcreErrorCode, 
                               &pcreErrorOffset, 
                               NULL);
    free(cstrPattern);
    
    if (!self->pcre) 
    {
        PCRE2_UCHAR pcreErrorMsg[512];
        pcre2_get_error_message(pcreErrorCode, pcreErrorMsg, sizeof(pcreErrorMsg));
        NSString *nsPcreErrorMsg = [NSString stringWithFormat:@"%S", (const unichar *)pcreErrorMsg];
        *error = [NSError errorWithDomain:PCRE2RegularExpressionErrorDomain 
                                     code:pcreErrorCode 
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: nsPcreErrorMsg,
                                            PCRE2RegularExpressionErrorOffsetKey: @(pcreErrorOffset)
                                            }];
        return nil;
    }
    
    pcre2_jit_compile(self->pcre, 0);
    
    pcreErrorCode = pcre2_pattern_info(self->pcre, 
                                       PCRE2_INFO_CAPTURECOUNT, 
                                       &self->patternCaptureCount);
    if (pcreErrorCode)
    {
        NSLog(@"pcre2_pattern_info failed: %d", pcreErrorCode);
        return nil;
    }
    self->patternCaptureCount += 1; // account for "all" group at index 0
    
    self->_namedCaptureGroupsIndexes = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)dealloc
{
    if (self->pcre)
    {
        pcre2_code_free(self->pcre);
    }
}

- (NSUInteger)numberOfCaptureGroups
{
    return self->patternCaptureCount - 1;
}

+ (nullable instancetype)regularExpressionWithPattern:(NSString *)pattern 
                                              options:(NSRegularExpressionOptions)options 
                                                error:(NSError * _Nullable *)error
{
    return [[PCRE2RegularExpression alloc] initWithPattern:pattern 
                                                  options:options 
                                                    error:error];
}


+ (NSString *)escapedPatternForString:(NSString *)string
{
    NSAssert(false, @"not implemented");
    return string;
}


#pragma mark - Matching

- (void)enumerateMatchesInString:(NSString *)string 
                         options:(NSMatchingOptions)options 
                           range:(NSRange)range 
                      usingBlock:(void (^)(NSTextCheckingResult * __nullable result, NSMatchingFlags flags, BOOL *stop))block
{
    pcre2_match_data *match_data = pcre2_match_data_create_from_pattern(self->pcre, NULL);
    
    NSRange *ranges = malloc(self->patternCaptureCount * sizeof(NSRange));
    NSUInteger maxRange = NSMaxRange(range);

    BOOL stop = NO;

    int pcreOptions = PCRE2_NO_UTF_CHECK;
    if (options & NSMatchingReportProgress)
    {
        NSAssert(false, @"NSMatchingReportProgress not currently supported");
    }
    if (options & NSMatchingReportCompletion)
    {
        NSAssert(false, @"NSMatchingReportCompletion not currently supported");
    }
    if (options & NSMatchingAnchored)
    {
        pcreOptions |= PCRE2_ANCHORED;
    }
    if (options & NSMatchingWithTransparentBounds)
    {
        NSAssert(false, @"NSMatchingWithTransparentBounds not currently supported");
    }
    if (options & NSMatchingWithoutAnchoringBounds)
    {
        NSAssert(false, @"NSMatchingWithoutAnchoringBounds not currently supported");
    }
    
    const int origPcreOptions = options;
    
    unichar *cstr = malloc((range.length + 1) * sizeof(unichar));
    [string getCharacters:cstr range:range];
    // remember how much we chopped off the front
    const NSUInteger startOffset = range.location; 
    range.location = 0;
    const int strLen = (int)range.length;
    
    while (range.length)
    {
        int actualCaptureCount = pcre2_match(self->pcre, 
                                             cstr, 
                                             strLen, 
                                             (int)range.location,
                                             pcreOptions, 
                                             match_data, 
                                             NULL);

        // just return if nothing found
        if (actualCaptureCount <= 0)
        {
            // nothing found is not an error
            if (actualCaptureCount == PCRE2_ERROR_NOMATCH) { break; }

            // 0 means "not enough room in ovector", negative values are one 
            // of the PCRE2_ERROR_xxx constants
            NSLog(@"pcre2_match failure: error code=%d", actualCaptureCount);
            NSAssert(false, @"got PCRE error: %d", actualCaptureCount);
            break;
        }
        
        PCRE2_SIZE *ovector = pcre2_get_ovector_pointer(match_data);
        
        // convert to ranges
        NSUInteger i;
        for (i = 0; i < actualCaptureCount; ++i)
        {
            PCRE2_SIZE start = ovector[i * 2];
            if (start != CAPTURE_NOT_FOUND)
            {
                PCRE2_SIZE end = ovector[i * 2 + 1];
                ranges[i] = NSMakeRange(start + startOffset, end - start);
            }
            else
            {
                ranges[i] = NSMakeRange(NSNotFound, 0);
            }
        }
        // PCRE omits captures groups at the end if nothing was found, so 
        // we'll manually add them back here to mimic NSRegularExpression
        for (; i < self->patternCaptureCount; ++i)
        {
            ranges[i] = NSMakeRange(NSNotFound, 0);
        }
        
        NSTextCheckingResult *r = [NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges 
                                                                                            count:self->patternCaptureCount 
                                                                                regularExpression:self];
        NSUInteger endOfMatchPos = NSMaxRange(ranges[0]);
        NSMatchingFlags flags = 0;
        if (endOfMatchPos >= maxRange)
        {
            flags |= NSMatchingHitEnd;
        }
        
        block(r, flags, &stop);
        if (stop)
        {
            break;
        }
        
        endOfMatchPos -= startOffset; // back to local coordinates
        range = NSMakeRange(endOfMatchPos, 
                            range.length - (endOfMatchPos - range.location));
        pcreOptions = origPcreOptions;
        if (endOfMatchPos == 0)
        {
            // there was a 0-length match at the beginning so adjust the 
            // matching options to protect against an infinite loop
            pcreOptions |= PCRE2_NOTEMPTY_ATSTART | PCRE2_ANCHORED;
        }
    }
    
    pcre2_match_data_free(match_data);
    free(ranges);
    free(cstr);
}

- (NSArray<NSTextCheckingResult *> *)matchesInString:(NSString *)string
                                             options:(NSMatchingOptions)options
                                               range:(NSRange)range
{
    NSMutableArray<NSTextCheckingResult *> *results = [NSMutableArray arrayWithCapacity:5];
    [self enumerateMatchesInString:string
                           options:options 
                             range:range 
                        usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) 
    {
        if (result)
        {
            [results addObject:(NSTextCheckingResult *)result];   
        }
    }];
    return results;
}

- (NSUInteger)numberOfMatchesInString:(NSString *)string 
                              options:(NSMatchingOptions)options 
                                range:(NSRange)range
{
    // not optimal, but it works
    return [self matchesInString:string options:options range:range].count;
}

- (nullable NSTextCheckingResult *)firstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range
{
    __block NSTextCheckingResult *firstResult = nil;
    [self enumerateMatchesInString:string
                           options:options 
                             range:range 
                        usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) 
     {
         if (result)
         {
             firstResult = result;
             *stop = YES;
         }
     }];
    return firstResult;
}

- (NSRange)rangeOfFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range
{
    NSTextCheckingResult *cr = [self firstMatchInString:string options:options range:range];
    if (cr) { return cr.range; }
    return NSMakeRange(NSNotFound, 0);
}


#pragma mark - Replacement

- (NSString *)stringByReplacingMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ
{
    NSAssert(false, @"not implemented");
    return @"";
}

- (NSUInteger)replaceMatchesInString:(NSMutableString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ
{
    NSAssert(false, @"not implemented");
    return 0;
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result inString:(NSString *)string offset:(NSInteger)offset template:(NSString *)templ;
{
    NSAssert(false, @"not implemented");
    return @"";
}

+ (NSString *)escapedTemplateForString:(NSString *)string
{
    NSAssert(false, @"not implemented");
    return string;
}


#pragma mark - PCRE Specific

- (NSUInteger)indexOfNamedCaptureGroup:(NSString *)name
{
    @synchronized(self->_namedCaptureGroupsIndexes) 
    {
        NSNumber *cached = self->_namedCaptureGroupsIndexes[name];
        if (cached)
        {
            return cached.unsignedIntegerValue;
        }
    
        unichar *cstrName = malloc((name.length + 1) * sizeof(unichar));
        [name getCharacters:cstrName range:NSMakeRange(0, name.length)];
        cstrName[name.length] = '\0';
        int ndx = pcre2_substring_number_from_name(self->pcre, cstrName); 
        free(cstrName);
        
        NSUInteger res = (ndx > 0)? ndx : NSNotFound;
        self->_namedCaptureGroupsIndexes[name] = @(res);
        return res;
    }
}

- (NSRange)rangeOfNamedCapture:(NSString *)name 
          inTextCheckingResult:(NSTextCheckingResult *)textCheckingResult
{
    NSUInteger groupNum = [self indexOfNamedCaptureGroup:name];
    if (groupNum == NSNotFound)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    return [textCheckingResult rangeAtIndex:groupNum];
}

@end
