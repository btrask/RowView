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
#import "RVContainer.h"
#import <SystemConfiguration/SystemConfiguration.h>

// Other Sources
#import "PGSubscription.h"
#import "RVFoundationAdditions.h"

NSString *const RVContainerContentsDidChangeNotification = @"RVContainerContentsDidChange";

@implementation RVContainer

#pragma mark -RVContainer

- (NSString *)name
{
	return NSLocalizedString(@"Computer", @"Root container name.");
}
- (NSURL *)URL
{
	return nil;
}
- (NSArray *)contents
{
	return [NSArray array];
}

@end

@implementation RVDirectory

#pragma mark -RVDirectory

- (id)initWithURL:(NSURL *)URL
{
	if((self = [super init])) {
		_URL = [URL copy];
		_subscription = [[PGSubscription subscriptionWithPath:[_URL path]] retain];
		[_subscription PG_addObserver:self selector:@selector(eventDidOccur:) name:PGSubscriptionEventDidOccurNotification];
	}
	return self;
}

#pragma mark -RVContainer

- (NSString *)name
{
	NSString *name = nil;
	(void)[_URL getResourceValue:&name forKey:NSURLNameKey error:NULL];
	return name ? name : @"";
}
- (NSURL *)URL
{
	return [[_URL retain] autorelease];
}
- (NSArray *)contents
{
	if(!_cachedContents) {
		_cachedContents = [[[[NSFileManager defaultManager] contentsOfDirectoryAtURL:_URL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL] sortedArrayUsingSelector:@selector(RV_nameCompare:)] copy];
	}
	return _cachedContents;
}

#pragma mark -

- (void)eventDidOccur:(NSNotification *)aNotif
{
	[_cachedContents release];
	_cachedContents = nil;
	[self PG_postNotificationName:RVContainerContentsDidChangeNotification];
}

#pragma mark -NSObject

- (void)dealloc
{
	[self PG_removeObserver];
	[_URL release];
	[_subscription release];
	[super dealloc];
}

@end

@implementation RVRootContainer

#pragma mark -RVContainer

- (NSString *)name
{
	NSString *const name = [(NSString *)SCDynamicStoreCopyComputerName(NULL, NULL) autorelease];
	return name ? name : NSLocalizedString(@"Computer", @"Root container name.");
}
- (NSArray *)contents
{
	return [[[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:NSVolumeEnumerationSkipHiddenVolumes] sortedArrayUsingSelector:@selector(RV_nameCompare:)];
}

@end
