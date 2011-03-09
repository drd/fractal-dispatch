//
//  julia.h
//  fractalgcd
//
//  Created by Eric O'Connell on 2/27/11.
//  Copyright 2011 Roundpeg Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <complex.h>
#import "RDView.h"

@interface julia : RDView {
	double time, dt;
	double re_center, im_center, re_width, im_height;
	double re_seed, im_seed;
	
	NSLock *glLock;
}

- (void) julia;
- (void) initGL;
- (void) draw:(NSNumber *) buffer;

@end
