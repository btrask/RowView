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
// Models
@class RVContainer;

@interface RVWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
	@private
	IBOutlet NSTableView *tableView;
	IBOutlet NSTableColumn *nameColumn;
	IBOutlet NSTableColumn *kindColumn;
	IBOutlet NSTableColumn *appColumn;
	IBOutlet NSTableColumn *dateModifiedColumn;
	IBOutlet NSTableColumn *sizeColumn;
}

- (IBAction)open:(id)sender;
- (IBAction)openWith:(id)sender;

- (void)openURL:(NSURL *)URL;
- (NSMenuItem *)openWithItemWithTitle:(NSString *)title fileURL:(NSURL *)fileURL applicationURL:(NSURL *)appURL;
- (NSMenu *)openWithMenuForFileURL:(NSURL *)URL;

- (NSURL *)URLAtIndex:(NSInteger)row container:(out RVContainer **)outContainer;
- (NSInteger)getContainer:(out RVContainer **)outContainer forIndex:(NSInteger)row;

- (void)containersDidChange:(NSNotification *)aNotif;

@end
