/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import "SFHorosAuthorizationView.h"


@class PreferencesView, PreferencesWindowContext;


/** \brief Window Controller for Preferences */
@interface PreferencesWindowController : NSWindowController <NSWindowDelegate>
{
	IBOutlet NSScrollView* scrollView;
	IBOutlet PreferencesView* panesListView;
	IBOutlet NSButton* authButton;
	IBOutlet SFHorosAuthorizationView* authView;
	PreferencesWindowContext* currentContext;
	NSMutableArray* animations;
}

@property(readonly) NSMutableArray* animations;
@property(readonly) SFHorosAuthorizationView* authView;

+ (PreferencesWindowController*) sharedPreferencesWindowController;
+(void) addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image;
+(void) removePluginPaneWithBundle:(NSBundle*)parentBundle;

-(BOOL)isUnlocked;

-(IBAction)showAllAction:(id)sender;
-(IBAction)navigationAction:(id)sender;
-(IBAction)authAction:(id)sender;

-(void)reopenDatabase;
-(void)setCurrentContextWithResourceName: (NSString*) name;
-(void)setCurrentContext:(PreferencesWindowContext*)context;
@end


@interface PreferencesWindowContext : NSObject {
	NSString* _title;
	NSBundle* _parentBundle;
	NSString* _resourceName;
	NSPreferencePane* _pane;
}

@property(retain) NSString* title;
@property(retain) NSBundle* parentBundle;
@property(retain) NSString* resourceName;
@property(nonatomic, retain) NSPreferencePane* pane;

-(id)initWithTitle:(NSString*)title withResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle;

@end
