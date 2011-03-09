#import "RDView.h"

@implementation RDView

- (id) initWithFrame:(NSRect)frameRect buffers:(int)buffers
{
	NSOpenGLPixelFormatAttribute att[] = 
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAAccelerated,
		0
	};
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:att]; 
	
	if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat]) != nil) {
		numBuffers = buffers;
		[self initOffscreen];
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
}

- (void) initOffscreen
{
	NSLog(@"initOffscreen");
	offscreens = malloc(numBuffers * sizeof(NSBitmapImageRep *));
	bitmaps = malloc(numBuffers * sizeof(UInt32 *));
	textures = malloc(numBuffers * sizeof(GLuint));
	textureLocks = malloc(numBuffers * sizeof(NSLock *));

	width = [self bounds].size.width;
	height = [self bounds].size.height;
	
	rowPix = width;
	rowBytes = width * 4;
	
	for(int i = 0; i < numBuffers; i++) {
//		offscreens[i] = [NSBitmapImageRep alloc];
//		
//		[offscreens[i] initWithBitmapDataPlanes: NULL 
//									 pixelsWide: width
//									 pixelsHigh: height
//								  bitsPerSample: 8
//								samplesPerPixel: 4
//									   hasAlpha: YES
//									   isPlanar: NO
//								 colorSpaceName: NSCalibratedRGBColorSpace
//									bytesPerRow: rowBytes
//								   bitsPerPixel: 32];
		
		bitmaps[i] = (UInt32 *)malloc(rowBytes * height); //[offscreens[i] bitmapData];
		
		glGenTextures(1, &textures[i]);
		
		textureLocks[i] = [[NSLock alloc] init];
	}
	
}

- (void) nextWriteBuffer
{
	writeBuffer = (writeBuffer + 1) % numBuffers;
}

- (NSBitmapImageRep *) getWriteOffscreen
{
	return offscreens[writeBuffer];
}

- (rawBitmap) getWriteBitmap
{
	return (rawBitmap)([offscreens[writeBuffer] bitmapData]);
}

- (void) nextReadBuffer
{
	readBuffer = (readBuffer + 1) % numBuffers;
}

- (NSBitmapImageRep *) getReadOffscreen
{
	return offscreens[readBuffer];
}

- (rawBitmap) getReadBitmap
{
	return (rawBitmap)([offscreens[readBuffer] bitmapData]);
}

- (void) dealloc 
{
	[super dealloc];
	
	for(int i = 0; i < numBuffers; i++) {
		[offscreens[i] release];
	}
	
	free(offscreens);
	free(bitmaps);
}	

@end
