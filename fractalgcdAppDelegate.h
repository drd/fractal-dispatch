//
//  fractalgcdAppDelegate.h
//  fractalgcd
//
//  Created by Eric O'Connell on 2/27/11.
//  Copyright 2011 Roundpeg Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface fractalgcdAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSTimer *animationTimer;
}

@property (assign) IBOutlet NSWindow *window;

@end
