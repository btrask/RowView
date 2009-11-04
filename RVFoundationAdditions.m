/* Copyright (c) 2009, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "RVFoundationAdditions.h"

// Other Sources
#import "PGDebug.h"

#define PGUnitSize 1000

@implementation NSDate(PGFoundationAdditions)

- (NSString *)PG_localizedStringWithDateStyle:(CFDateFormatterStyle)dateStyle timeStyle:(CFDateFormatterStyle)timeStyle
{
	static CFDateFormatterRef f = nil;
	if(!f || CFDateFormatterGetDateStyle(f) != dateStyle || CFDateFormatterGetTimeStyle(f) != timeStyle) {
		if(f) CFRelease(f);
		CFLocaleRef const locale = CFLocaleCopyCurrent();
		f = CFDateFormatterCreate(kCFAllocatorDefault, locale, dateStyle, timeStyle);
		CFRelease(locale);
	}
	return [(NSString *)CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, f, (CFDateRef)self) autorelease];
}

@end

@implementation NSNumber(PGFoundationAdditions)

- (NSString *)PG_localizedStringAsBytes
{
	CGFloat b = (CGFloat)[self unsignedLongLongValue];
	NSUInteger magnitude = 0;
	for(; b >= PGUnitSize && magnitude < 4; magnitude++) b /= PGUnitSize;
	NSString *unit = nil;
	switch(magnitude) {
		case 0: unit = NSLocalizedString(@"B", @"Unit (bytes)"); break;
		case 1: unit = NSLocalizedString(@"KB", @"Unit (kilobytes)"); break;
		case 2: unit = NSLocalizedString(@"MB", @"Unit (megabytes)"); break;
		case 3: unit = NSLocalizedString(@"GB", @"Unit (gigabytes)"); break;
		case 4: unit = NSLocalizedString(@"TB", @"Unit (terabytes)"); break;
		default: PGAssertNotReached(@"Divided too far.");
	}
	return [NSString localizedStringWithFormat:@"%.1f %@", b, unit];
}

@end

@implementation NSObject(PGFoundationAdditions)

#pragma mark -NSObject(PGFoundationAdditions)

- (void)PG_postNotificationName:(NSString *)aName
{
	[self PG_postNotificationName:aName userInfo:nil];
}
- (void)PG_postNotificationName:(NSString *)aName userInfo:(NSDictionary *)aDict
{
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:aName object:self userInfo:aDict];
}

#pragma mark -

- (void)PG_addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName
{
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:aName object:self];
}
- (void)PG_removeObserver
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)PG_removeObserver:(id)observer name:(NSString *)aName
{
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:observer name:aName object:self];
}

@end

@implementation NSString(PGFoundationAdditions)

#pragma mark -NSString(PGFoundationAdditions)

- (NSComparisonResult)PG_localizedCaseInsensitiveNumericCompare:(NSString *)aString
{
	static UniChar *str1 = NULL;
	static UniChar *str2 = NULL;
	static UniCharCount max1 = 0;
	static UniCharCount max2 = 0;
	UniCharCount const length1 = [self length], length2 = [aString length];
	if(max1 < length1) {
		max1 = length1;
		str1 = str1 ? realloc(str1, max1 * sizeof(UniChar)) : malloc(max1 * sizeof(UniChar));
	}
	if(max2 < length2) {
		max2 = length2;
		str2 = str2 ? realloc(str2, max2 * sizeof(UniChar)) : malloc(max2 * sizeof(UniChar));
	}
	NSAssert(str1 && str2, @"Couldn't allocate.");
	[self getCharacters:str1];
	[aString getCharacters:str2];
	SInt32 result = NSOrderedSame;
	(void)UCCompareTextDefault(kUCCollateComposeInsensitiveMask | kUCCollateWidthInsensitiveMask | kUCCollateCaseInsensitiveMask | kUCCollateDigitsOverrideMask | kUCCollateDigitsAsNumberMask | kUCCollatePunctuationSignificantMask, str1, length1, str2, length2, NULL, &result);
	return (NSComparisonResult)result;
}

@end

@implementation NSURL(RVFoundationAdditions)

- (BOOL)RV_isFolder
{
	NSDictionary *const values = [self resourceValuesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLIsPackageKey, nil] error:NULL];
	return [[values objectForKey:NSURLIsDirectoryKey] boolValue] && ![[values objectForKey:NSURLIsPackageKey] boolValue];
}
- (NSArray *)RV_componentURLs
{
	NSMutableArray *const URLs = [NSMutableArray array];
	NSURL *URL = self;
	NSUInteger i = [[self pathComponents] count];
	for(; i--; URL = [URL URLByDeletingLastPathComponent]) [URLs addObject:URL];
	return URLs;
}
- (NSComparisonResult)RV_nameCompare:(NSURL *)URL
{
	NSString *n1 = nil, *n2 = nil;
	if(![self getResourceValue:&n1 forKey:NSURLNameKey error:NULL] || ![URL getResourceValue:&n2 forKey:NSURLNameKey error:NULL]) return NSOrderedSame;
	return [n1 PG_localizedCaseInsensitiveNumericCompare:n2];
}

@end
