//  Copyright (C) 2015 Pierre-Olivier Latour <info@pol-online.net>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <GitUpKit/GitUpKit.h>

#import "Document.h"

#define kToolbarItem_LeftView @"left"
#define kToolbarItem_RightView @"right"

@interface Document () <NSToolbarDelegate, NSTableViewDelegate, GCLiveRepositoryDelegate, GIDiffContentsViewControllerDelegate>
@property(nonatomic, strong) IBOutlet NSArrayController* arrayController;
@property(nonatomic, strong) IBOutlet NSView* leftToolbarView;
@property(nonatomic, strong) IBOutlet NSView* rightToolbarView;
@property(nonatomic, weak) IBOutlet NSTabView* tabView;
@property(nonatomic, weak) IBOutlet NSView* diffView;
@property(nonatomic, strong) IBOutlet NSView* headerView;
@property(nonatomic, weak) IBOutlet NSTextField* messageTextField;
@property(nonatomic) NSUInteger viewIndex;  // Used for bindings in XIB
@end

@implementation Document {
  GCLiveRepository* _repository;
  GIWindowController* _windowController;
  NSToolbar* _toolbar;
  GIDiffContentsViewController* _diffContentsViewController;
  GIAdvancedCommitViewController* _commitViewController;
  GCDiff* _currentDiff;
  CGFloat _messageTextFieldMargins;
  CGFloat _headerViewMinHeight;
}

- (BOOL)readFromURL:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError {
  BOOL success = NO;
    
    _repository = [[GCLiveRepository alloc] initWithExistingLocalRepository:url.path error:outError];
  if (_repository) {
    if (_repository.bare) {
      if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Bare repositories are not supported!"}];
      }
    } else {
      _repository.delegate = self;
      success = YES;
    }
  }
  return success;
}

- (void)close {
  [super close];

  _repository.delegate = nil;
  _repository = nil;
}

- (void)makeWindowControllers {
  _windowController = [[GIWindowController alloc] initWithWindowNibName:@"Document" owner:self];
  [self addWindowController:_windowController];
}


- (void)windowControllerDidLoadNib:(NSWindowController*)aController {
  [super windowControllerDidLoadNib:aController];

    NSArray *argv = [[NSProcessInfo processInfo] arguments];
    NSArray *args = [argv subarrayWithRange:NSMakeRange(1, argv.count - 1)];
    NSLog(@"git:args:%@", args);
    NSString *message = @"";
    for (NSString *arg in args) {
        if ([arg hasPrefix:@"--message="]) {
            message = [arg substringWithRange:NSMakeRange(10, arg.length-10)];
        }
    }
    
   NSLog(@"git:message:%@", message);
    
  _commitViewController = [[GIAdvancedCommitViewController alloc] initWithRepository:_repository];
    [_commitViewController stageAllFiles];
    _commitViewController.messageTextView.string = message;
    [_commitViewController.messageTextView moveToEndOfLine:nil];
  [[_tabView tabViewItemAtIndex:0] setView:_commitViewController.view];


  [self repositoryDidUpdateHistory:nil];
}

// Override -updateChangeCount: which is trigged by NSUndoManager to do nothing and not mark document as updated
- (void)updateChangeCount:(NSDocumentChangeType)change {
  ;
}

#pragma mark - GCLiveRepositoryDelegate

- (void)repositoryDidUpdateHistory:(GCLiveRepository*)repository {
  _arrayController.content = _repository.history.allCommits;
}

- (void)repository:(GCLiveRepository*)repository historyUpdateDidFailWithError:(NSError*)error {
  [self presentError:error];
}


@end
