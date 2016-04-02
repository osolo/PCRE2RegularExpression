//
//  PCRE2RegularExpression.m
//  Scribe
//
//  Created by Oz Solomon on 2016-02-20.
//  Copyright © 2016 Social Graph Studios. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PCRE2RegularExpression.h"

@interface PCRE2RegularExpressionTests : XCTestCase

#define EXTRA_LOGGING 0

@end

@implementation PCRE2RegularExpressionTests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSimpleNoMatches {
    [self performStandardTestForPattern:@"foo"
                              andString:@"bar"];
}

- (void)testSimpleOneMatch {
    [self performStandardTestForPattern:@"foo"
                              andString:@"foo"];
}

- (void)testSimpleMultipleMatches {
    [self performStandardTestForPattern:@"foo"
                              andString:@"foofoo xfoo"];
}

- (void)testMatchGroups {
    [self performStandardTestForPattern:@"a*(b+)"
                              andString:@"a aab babxbb"];
}

- (void)testMatchGroupsWithRange {
    NSString *s = @"bbxa aab babxbb!b";
    NSString *pat = @"a*(b+)";
    NSUInteger l = s.length, i;
    for (i = 1; i <= l; ++i)
    {
#if EXTRA_LOGGING
        NSLog(@"Iteration %lu", (unsigned long)i);
#endif
        [self performStandardTestForPattern:pat
                                  andString:s
                                   andRange:NSMakeRange(0, i)];
        [self performStandardTestForPattern:pat
                                  andString:s
                                   andRange:NSMakeRange(i, l - i)];
    }
}

- (void)testMatchAnchor1 {
    [self performStandardTestForPattern:@"^a*(b+)"
                              andString:@"a aab babxbb"];
}

- (void)testMatchAnchor2 {
    [self performStandardTestForPattern:@"a*(b+)$"
                              andString:@"a aab babxbb"];
}

- (void)testMatchAnchor3 {
    [self performStandardTestForPattern:@"^a*(b+)$"
                              andString:@"a aab babxbb"];
}

- (void)testMatchUnicode {
    [self performStandardTestForPattern:@"(\\P{M})(\\p{M})"
                              andString:@"xa\u0300y"];
}

- (void)testPatternError {
    NSString *pat = @"(forgot to close it";
    NSError *error;
    PCRE2RegularExpression *re;
    re = [PCRE2RegularExpression regularExpressionWithPattern:pat 
                                                     options:NSRegularExpressionCaseInsensitive 
                                                       error:&error];
    XCTAssertNil(re);
    XCTAssertNotNil(error);
    XCTAssertEqual(114, error.code);
    XCTAssertEqualObjects(@"missing closing parenthesis", error.userInfo[NSLocalizedDescriptionKey]);
    XCTAssertEqualObjects(@(19), error.userInfo[PCRE2RegularExpressionErrorOffsetKey]);
}

// PCRE only
- (void)testNamedSubroutine {
    NSError *error;
    NSString *pat = @"(?(DEFINE)(?'INPARENS'(?:\\([a-z]+(?P>INPARENS)?\\))))a(?P>INPARENS)b";
    PCRE2RegularExpression *re;
    re = [PCRE2RegularExpression regularExpressionWithPattern:pat 
                                                     options:NSRegularExpressionCaseInsensitive 
                                                       error:&error];
    XCTAssertNotNil(re);
    NSString *s = @"bA(one(two(three)))bBABA(one(two))B a(not((this)))";
    NSArray<NSTextCheckingResult *> *res = [re matchesInString:s options:0 range:NSMakeRange(0, s.length)];
    XCTAssertEqual(2, res.count);
    XCTAssertEqualObjects(@"A(one(two(three)))b", [s substringWithRange:res[0].range]);
    XCTAssertEqualObjects(@"A(one(two))B", [s substringWithRange:res[1].range]);
}

// PCRE only
- (void)testNamedCaptureGroup {
    NSError *error;
    NSString *pat = @"(a)(?P<namedgroup>b+)(c)";
    PCRE2RegularExpression *re;
    re = [PCRE2RegularExpression regularExpressionWithPattern:pat 
                                                     options:NSRegularExpressionCaseInsensitive 
                                                       error:&error];
    XCTAssertNotNil(re);
    NSString *s = @"abBbc";
    NSArray<NSTextCheckingResult *> *res = [re matchesInString:s options:0 range:NSMakeRange(0, s.length)];
    XCTAssertEqual(1, res.count);
    NSTextCheckingResult *cr = res[0];
    XCTAssertEqual(4, cr.numberOfRanges);
    XCTAssertEqualObjects(@"abBbc", [s substringWithRange:cr.range]);
    XCTAssertEqualObjects(@"a",     [s substringWithRange:[cr rangeAtIndex:1]]);
    XCTAssertEqualObjects(@"bBb",   [s substringWithRange:[cr rangeAtIndex:2]]);
    XCTAssertEqualObjects(@"c",     [s substringWithRange:[cr rangeAtIndex:3]]);
    
    XCTAssertEqual(NSNotFound, [re indexOfNamedCaptureGroup:@"foo"]);
    XCTAssertEqual(2, [re indexOfNamedCaptureGroup:@"namedgroup"]);
    XCTAssertEqualObjects(@"bBb", [s substringWithRange:[re rangeOfNamedCapture:@"namedgroup" inTextCheckingResult:cr]]);
}


/**
 * Compares the results of using PCRE2RegularExpression with the results of 
 * using the built-in NSRegularExpression class.
 * 
 * @param pattern The regex pattern.
 * @param string The string to search.  The whole string is searched.
 */
- (void)performStandardTestForPattern:(NSString *)pattern
                            andString:(NSString *)string
{
    [self performStandardTestForPattern:pattern 
                              andString:string
                               andRange:NSMakeRange(0, string.length)];
}


/**
 * Compares the results of using PCRE2RegularExpression with the results of 
 * using the built-in NSRegularExpression class.
 * 
 * @param pattern The regex pattern.
 * @param string The string to search.
 * @param range The range to search within @c string.
 */
- (void)performStandardTestForPattern:(NSString *)pattern
                            andString:(NSString *)string
                             andRange:(NSRange)range
{
    NSError *error = nil;
    NSRegularExpression *reBuiltin = [NSRegularExpression regularExpressionWithPattern:pattern 
                                                                               options:0 
                                                                                 error:&error];
    if (error || !reBuiltin)
    {
        XCTFail(@"Error in compiling pattern %@ with NSRegularExpression: %@", pattern, error);
        return;
    }
    
    NSRegularExpression *rePCRE = [PCRE2RegularExpression regularExpressionWithPattern:pattern 
                                                                              options:0 
                                                                                error:&error];
    if (error || !rePCRE)
    {
        XCTFail(@"Error in compiling pattern %@ with PCRE: %@", pattern, error);
        return;
    }
    
#if EXTRA_LOGGING    
    NSLog(@"Testing %@", [string substringWithRange:range]);
#endif
    
    XCTAssertEqual(reBuiltin.numberOfCaptureGroups, rePCRE.numberOfCaptureGroups);
    
    NSMutableArray *builtinResults = [NSMutableArray array];
    [reBuiltin enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [builtinResults addObject:@[result, @(flags)]];
    }];
    
    NSMutableArray *pcreResults = [NSMutableArray array];
    [rePCRE enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [pcreResults addObject:@[result, @(flags)]];
    }];
    
    XCTAssertEqual(builtinResults.count, pcreResults.count);
    if (builtinResults.count == pcreResults.count)
    {
        for (NSUInteger i = 0; i < builtinResults.count; ++i)
        {
            NSTextCheckingResult *crBuiltin = builtinResults[i][0];
            NSTextCheckingResult *crPCRE = pcreResults[i][0];
            
#if EXTRA_LOGGING    
            NSLog(@" %@: %@", NSStringFromRange(crBuiltin.range), [string substringWithRange:crBuiltin.range]);
#endif            
            // ranges
            XCTAssertEqualObjects(NSStringFromRange(crBuiltin.range), 
                                  NSStringFromRange(crPCRE.range));
            XCTAssertEqual(crBuiltin.numberOfRanges, 
                           crPCRE.numberOfRanges);
            for (NSUInteger j = 0; j < crBuiltin.numberOfRanges; ++j)
            {
                XCTAssertEqualObjects(NSStringFromRange([crBuiltin rangeAtIndex:j]), 
                                      NSStringFromRange([crPCRE rangeAtIndex:j]));
            }
            
            // flags
            // todo: makes flags work
            //            XCTAssertEqualObjects(builtinResults[i][1], pcreResults[i][1]);
        }
    }    
#if EXTRA_LOGGING    
    NSLog(@"Completed with %lu matches", (unsigned long)builtinResults.count);
#endif
}


@end
