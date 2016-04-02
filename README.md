## PCRE2RegularExpression

*PCRE2RegularExpression* is an Objective-C wrapper for the [PCRE2] regular expression library.  *PCRE2RegularExpression* aims to be a drop-in replacement for *NSRegularExpression*.  In many cases all you need to do is replace references to *NSRegularExpression* with *PCRE2RegularExpression* in your code.

*PCRE2RegularExpression* is fully Unicode safe.


## Background

Although Cocoa provides built-in support for regular expressions through the *NSRegularExpression* class, *NSRegularExpression* only supports the ICU regular expression pattern syntax, which lacks many features found in more powerful engines such as PCRE/PCRE2.

I created this project to support my own needs while developing the [Scribe for Xcode] plugin, and it only implements the subset of functionality that I needed.  However, since Scribe relies heavily on complicated regular expressions, I believe this code will be immediately useful to most people, and can serve as a foundation for others.  


## Usage

Use *PCRE2RegularExpression* just like you would *NSRegularExpression*:
```objc
PCRE2RegularExpression *re;
re = [PCRE2RegularExpression regularExpressionWithPattern:@"foo"
options:NSRegularExpressionCaseInsensitive 
error:&error];
[re enumerateMatchesInString:myString 
options:NSRegularExpressionCaseInsensitive 
range:myRange
usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
// ...
}];
```

Harness the power of PCRE2 features like named capture groups:
```objc
NSString *pat = @"(a)(?P<mygroup>b+)(c)";
PCRE2RegularExpression *re;
re = [PCRE2RegularExpression regularExpressionWithPattern:pat 
options:NSRegularExpressionCaseInsensitive 
error:&error];
NSString *s = @"abbbc";
NSArray<NSTextCheckingResult *> *res = [re matchesInString:s options:0 range:NSMakeRange(0, s.length)];
NSRange rangeOf_bbb = [re rangeOfNamedCapture:@"mygroup" inTextCheckingResult:res[0]];
```


## Installation

Install PCRE2 on your system using [Homebrew]:
```bsh
brew install pcre2
```
The above installs into something like `/usr/local/Cellar/pcre2/10.20`.

In your Xcode project, under *Build Settings* add `/usr/local/Cellar/pcre2/10.20/include` to the *Header Search Paths*.

In your target, under the *General* tab, press + under *Linked Frameworks and Libraries*.  Click "Other" and add `/usr/local/Cellar/pcre2/10.20/lib/libpcre2-16.a`.  We're using the `-16` version which uses 16-bit characters.

Finally, add `PCRE2RegularExpression.m` and `PCRE2RegularExpression.h` to your project.


## Possible Future Enhancements

1. Improved code optimizations.
2. Expose more PCRE2-specific functionality through new APIs.
3. Support a fuller subset of the NSRegularExpression API.


## Acknowledgments

This project was inspired by cmkliger's [PCRERegex].  In comparison to PCRERegex, this project uses PCRE2 (vs PCRE1), and has Unicode support.


## License

MIT License.

[PCRE2]: <http://www.pcre.org/>
[Scribe for Xcode]: <https://scribeplugin.com>
[PCRERegex]: <https://github.com/cmkilger/PCRERegex>
[Homebrew]: <http://brew.sh>
