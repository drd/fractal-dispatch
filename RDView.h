/* RDView */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

typedef UInt32 * rawBitmap;

@interface RDView : NSOpenGLView
{
	int numBuffers, writeBuffer, readBuffer;
	NSBitmapImageRep ** offscreens;
	NSLock ** textureLocks;
	rawBitmap *bitmaps;
	GLuint *textures;
	UInt32 width, height, rowBytes, rowPix;
}

- (id) initWithFrame:(NSRect)frameRect buffers:(int)buffers;

- (void) initOffscreen;

- (void) nextWriteBuffer;
- (NSBitmapImageRep *) getWriteOffscreen;
- (rawBitmap) getWriteBitmap;

- (void) nextReadBuffer;
- (NSBitmapImageRep *) getReadOffscreen;
- (rawBitmap) getReadBitmap;

- (UInt32) getWidth;
- (UInt32) getHeight;

- (UInt32) getWidthPower2;
- (UInt32) getHeightPower2;

@end
