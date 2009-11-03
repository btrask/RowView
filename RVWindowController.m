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
#import "RVWindowController.h"

// Models
#import "RVDocument.h"
#import "RVContainer.h"

// Other Sources
#import "RVFoundationAdditions.h"

@implementation RVWindowController

#pragma mark -RVWindowController

- (IBAction)open:(id)sender
{
	NSURL *const URL = [self URLAtIndex:[sender selectedRow] container:NULL];
	if(!URL || [URL RV_isFolder]) {
		[[self document] setFileURL:URL];
		[tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		[tableView scrollRectToVisible:NSZeroRect];
	} else [[NSWorkspace sharedWorkspace] openURL:URL];
}

#pragma mark -

- (NSURL *)URLAtIndex:(NSInteger)row container:(out RVContainer **)outContainer
{
	if(-1 == row) return nil;
	NSInteger i = row;
	NSArray *const containers = [[self document] containers];
	for(RVContainer *const container in containers) {
		if(!i) {
			if(outContainer) *outContainer = container;
			return [container URL];
		}
		i -= 1;
		NSArray *const contents = [container contents];
		NSUInteger const count = [contents count];
		if(i < count) {
			if(outContainer) *outContainer = nil;
			return [contents objectAtIndex:i];
		}
		i -= count;
	}
	return nil;
}
- (NSInteger)getContainer:(out RVContainer **)outContainer forIndex:(NSInteger)row
{
	if(-1 == row) return -1;
	NSInteger containerRow = 0;
	NSArray *const containers = [[self document] containers];
	for(RVContainer *const container in containers) {
		NSUInteger const count = 1 + [[container contents] count];
		if(row - containerRow < count) {
			if(outContainer) *outContainer = container;
			return containerRow;
		}
		containerRow += count;
	}
	return -1;
}

#pragma mark -

- (void)containersDidChange:(NSNotification *)aNotif
{
	[tableView reloadData];
	[self synchronizeWindowTitleWithDocumentName];
}

#pragma mark -NSWindowController

- (void)setDocument:(NSDocument *)document
{
	[[self document] PG_removeObserver:self name:RVDocumentContainersDidChangeNotification];
	[super setDocument:document];
	[[self document] PG_addObserver:self selector:@selector(containersDidChange:) name:RVDocumentContainersDidChangeNotification];
	[self containersDidChange:nil];
}
- (void)windowDidLoad
{
	[super windowDidLoad];
	[tableView setDoubleAction:@selector(open:)];
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy | NSDragOperationMove | NSDragOperationDelete forLocal:YES];
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy | NSDragOperationMove | NSDragOperationDelete forLocal:NO];
	[tableView setVerticalMotionCanBeginDrag:NO];
}

#pragma mark -NSObject

- (id)init
{
	return [self initWithWindowNibName:@"RVDocument"];
}
- (void)dealloc
{
	[self PG_removeObserver];
	[super dealloc];
}

#pragma mark -<NSTableViewDataSource>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *const containers = [[self document] containers];
	NSInteger count = [containers count];
	for(RVContainer *const container in containers) count += [[container contents] count];
	return count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	RVContainer *container = nil;
	NSURL *const URL = [self URLAtIndex:row container:&container];
	id value = nil;
	if(container && [NSURLNameKey isEqualToString:[tableColumn identifier]]) value = [container name];
	else (void)[URL getResourceValue:&value forKey:[tableColumn identifier] error:NULL];
	if(!value) return @"--";
	if([NSURLFileSizeKey isEqualToString:[tableColumn identifier]]) return [value PG_localizedStringAsBytes];
	if([NSURLContentModificationDateKey isEqualToString:[tableColumn identifier]]) return [value PG_localizedStringWithDateStyle:kCFDateFormatterShortStyle timeStyle:kCFDateFormatterShortStyle];
	return value;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([NSURLNameKey isEqualToString:[tableColumn identifier]]) [[self URLAtIndex:row container:NULL] setResourceValue:object forKey:NSURLNameKey error:NULL];
}

#pragma mark -<NSTableViewDelegate>

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSURL *const URL = [self URLAtIndex:row container:NULL];
	BOOL bold = NO;
	if([NSURLNameKey isEqualToString:[tableColumn identifier]]) bold = [URL RV_isFolder];
	[cell setFont:bold ? [NSFont boldSystemFontOfSize:11.0f] : [NSFont systemFontOfSize:11.0f]];
}
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return !![self URLAtIndex:row container:NULL];
}
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	RVContainer *container = nil;
	(void)[self URLAtIndex:row container:&container];
	return !!container;
}

#pragma mark -

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
	NSUInteger i = [rowIndexes firstIndex];
	NSMutableArray *const URLs = [NSMutableArray array];
	for(; NSNotFound != i; i = [rowIndexes indexGreaterThanIndex:i]) [URLs addObject:[self URLAtIndex:i container:NULL]];
	[pboard writeObjects:URLs];
	return !![URLs count];
}
- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if(NSTableViewDropAbove == dropOperation) return NSDragOperationNone;
	if(![[info draggingPasteboard] canReadObjectForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]]) return NSDragOperationNone;
	if(![[self URLAtIndex:row container:NULL] RV_isFolder]) [tableView setDropRow:[self getContainer:NULL forIndex:row] dropOperation:NSTableViewDropOn];
	return NSDragOperationEvery;
}
- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	if(NSTableViewDropAbove == dropOperation) return NO;
	NSURL *const dstURLParent = [self URLAtIndex:row container:NULL];
	if(![dstURLParent RV_isFolder]) return NO;
	NSArray *const srcURLs = [[info draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]];
	if(![srcURLs count]) return NO;
	for(NSURL *const srcURL in srcURLs) {
		NSURL *const dstURL = [dstURLParent URLByAppendingPathComponent:[srcURL lastPathComponent]];
		if([info draggingSourceOperationMask] & NSDragOperationMove) [[NSFileManager defaultManager] moveItemAtURL:srcURL toURL:dstURL error:NULL];
		else if([info draggingSourceOperationMask] & NSDragOperationCopy) [[NSFileManager defaultManager] copyItemAtURL:srcURL toURL:dstURL error:NULL];
	}
	return YES;
}

@end
