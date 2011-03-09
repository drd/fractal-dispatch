//
//  fractalgcdAppDelegate.m
//  fractalgcd
//
//  Created by Eric O'Connell on 2/27/11.
//  Copyright 2011 Roundpeg Designs. All rights reserved.
//

#import "fractalgcdAppDelegate.h"
#import "julia.h"

@implementation fractalgcdAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	julia *j = [[julia alloc] initWithFrame:[window.contentView frame] buffers:4];
	[window.contentView addSubview: j];
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.033 target:j selector:@selector(julia) userInfo:nil repeats:YES];

}

@end
