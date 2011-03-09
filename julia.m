//
//  julia.m
//  fractalgcd
//
//  Created by Eric O'Connell on 2/27/11.
//  Copyright 2011 Roundpeg Designs. All rights reserved.
//

#import "julia.h"
#import <dispatch/dispatch.h>
#import <math.h>

#define ASYNC
#define N 2
#define _DIST
#define ITERATIONS 64

#if DEBUG
#define GLDEBUG() if(glGetError() != GL_NO_ERROR){NSLog(@"glError: %d caught at %s:%u\n", glGetError(), __FILE__, __LINE__);}
#else
#define GLDEBUG()
#endif


@implementation julia

- (id)initWithFrame:(NSRect)frame buffers:(int)buffers {
    self = [super initWithFrame:frame buffers:buffers];

    if (self) {
		[self initGL];
		
		time = 0.0;
		dt = 0.0125;

		re_seed = -0.687;
		im_seed = 0.312;

		re_center = 0;
		im_center = 0;
		
		re_width = 4.0;
		im_height = 3.0;
		
		iterBase = 0;
		
		glLock = [[NSLock alloc] init];
		
		colorTable = (rawBitmap) malloc(ITERATIONS * sizeof(pixel));
		
		float ct = 0, dct = 0.1 *  M_PI / ITERATIONS;
		for(int i = 0; i < ITERATIONS; i++) {
			int r, g, b;
			
			b = 255 * fabs(sin(ct * 2 - cos(ct)));
			r = 255 * fabs(sin(M_PI * cos(ct) - M_PI * sin(3 * ct)));
			g = 127 * fabs(cos(ct / 3)) + 128 * fabs(sin(M_PI - ct));
			
//			bitmap[(y_base + y) * rowPix + x_base + x] = (256 - i & 0xff) | ((i & 0xff) << 8) | ((i & 0xff) << 16);
			colorTable[i] = r | (g << 8) | (b << 16);
			
			ct += dct;
		}
	}
    
	return self;
}

- (void) initGL {
	CGLError err = 0;
	CGLContextObj ctx = [[self openGLContext] CGLContextObj];
	
	// Enable the multithreading
	err =  CGLEnable( ctx, kCGLCEMPEngine);
	
	NSAssert(err == kCGLNoError, @"Dammit");
	
	glEnable(GL_TEXTURE_2D);
	GLDEBUG();
	
	glEnable (GL_TEXTURE_RECTANGLE_ARB);
	GLDEBUG();
	
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);				// make it linear filterd
	GLDEBUG();
	
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	GLDEBUG();
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	GLDEBUG();
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	GLDEBUG();
	
	glViewport(0,0, width, height); 
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f); 
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	
	
	glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

}

- (void)julia {
#ifdef ASYNC
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
#endif
		
	NSSize size = [self bounds].size;
	double d_re = re_width / size.width;
	double d_im = im_height / size.height;
		
	int block_width = size.width / N;
	int block_height = size.height / N;
	
	double c_re = re_seed + 0.3 * cos(time * 2.0) - 0.5 * sin(time * 0.5 - .3);
	double c_im = im_seed + 0.3 * sin(time * 1.5) + 0.75 *cos(1 - time);
	time += dt;
	
	NSOpenGLContext *nsOGLContext = [self openGLContext];
	
	NSLog(@"locking %d", writeBuffer);
	[textureLocks[writeBuffer] lock];
	NSLog(@"locked %d", writeBuffer);
	
	for (int xx = 0; xx < N; xx++) {
		for (int yy = 0; yy < N; yy++) {

#ifdef ASYNC
			dispatch_group_async(group, queue, ^{
#endif
				rawBitmap bitmap = bitmaps[writeBuffer];
				
				int x_base = xx * block_width;
				int y_base = yy * block_height;

				double re, re_0 = re_center - re_width / 2.0 + x_base * d_re;
				double im = im_center - im_height / 2.0 + y_base * d_im;
				
#ifdef DIST
				double dmin = 999999, dmax = -999999;
#endif DIST
				
				re = re_0;
				
				for (int y = 0; y < block_height; y++) {
					for (int x = 0; x < block_width; x++) {
						double zx, zy;
						double zx2, zy2;
						
#ifdef DIST
						double dzx = 0, dzy = 0;
#endif DIST
						
						zx = re;
						zy = im;
						zx2 = zx * zx;
						zy2 = zy * zy;
						
						int i = 0;

						while (i < ITERATIONS && zx2 + zy2 < 4)
						{
							zy = 2 * zx * zy + c_im;
							zx = zx2 - zy2 + c_re;
							
#ifdef DIST
							double dzxt = dzx;
							
							dzx = 2 * (zx * dzx - zy * dzy) + 1;
							dzy = 2 * (zy * dzxt + dzy * zx);
#endif DIST
							
							zx2 = zx * zx;
							zy2 = zy * zy;
							
							i++;
						}
						
#ifdef DIST
						double mz = zx*zx + zy*zy;
						double mdz = dzx*dzx + dzy*dzy;
						
						double dist = log(mz*mz)*mz / mdz;
						
						if (dist > dmax) {
							dmax = dist;
						}
						if (dist < dmin) {
							dmin = dist;
						}
#endif DIST
						
						bitmap[(y_base + y) * rowPix + x_base + x] = colorTable[(i + iterBase) % ITERATIONS]; // (256 - i & 0xff) | ((i & 0xff) << 8) | ((i & 0xff) << 16);
						
						re += d_re;
					}
					
					re = re_0;
					im += d_im;
				}

#ifdef DIST
				NSLog(@"max: %f min: %f", dmax, dmin);
#endif DIST

#ifdef ASYNC
			});
#endif

		}
	}
	
#ifdef ASYNC
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_sync(queue, ^{
#endif
//		[self performSelectorOnMainThread:@selector(draw:) withObject:[NSNumber numberWithInteger:writeBuffer] waitUntilDone:YES];

//		[glLock lock];
		
		int toUnlock = writeBuffer;

		[self setOpenGLContext:nsOGLContext];
		[nsOGLContext setView:self];
		CGLLockContext([nsOGLContext CGLContextObj]);
		
		[self draw:[NSNumber numberWithInteger:writeBuffer]];
		
		[[self openGLContext] flushBuffer];
		CGLUnlockContext([nsOGLContext CGLContextObj]);

		[self nextWriteBuffer];

//		[glLock unlock];
		
		NSLog(@"unlocking %d", toUnlock);
		[textureLocks[toUnlock] unlock];
//		iterBase++;
		NSLog(@"unlocked %d", toUnlock);
		
		
#ifdef ASYNC
	});
	dispatch_release(group);
#endif
	
}

- (void) draw:(NSNumber *) buffer {
	int buff = [buffer intValue];
	
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textures[buff]);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmaps[buff]);
	GLDEBUG();
		
	glMatrixMode(GL_PROJECTION);					// Select Projection
	glPushMatrix();									// Push The Matrix
	glLoadIdentity();								// Reset The Matrix
	glOrtho( 0, width , 0 , height, -1, 1 );		// Select Ortho Mode
	glMatrixMode(GL_MODELVIEW);						// Select Modelview Matrix
	glPushMatrix();									// Push The Matrix
	glLoadIdentity();								// Reset The Matrix

	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textures[buff]);
	GLDEBUG();

	glBegin(GL_QUADS);     
	glTexCoord2f(0, 0);    glVertex2f(0, 0);
	glTexCoord2f(0, height);    glVertex2f(0, height); 
	glTexCoord2f(width, height);    glVertex2f(width, height);
	glTexCoord2f(width, 0);    glVertex2f(width, 0);
	glEnd();
}

- (void)drawRect:(NSRect)dirtyRect {
}

@end
