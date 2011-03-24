//
//  ES1Renderer.m
//  ARDetection
//
//  Created by NIMESH DESAI on 10/19/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "NSObject+Console.h"
#import "ES1Renderer.h"
#import "Object3D.h"

@interface ES1Renderer ()

static float spinZ = 0;
static GLfloat move = 0.0f;

- (void) loadObject:(Object3D*) object;
- (void) loadTexture;
- (void) unloadTexture;

@end

@implementation ES1Renderer

@synthesize object = _object;

#pragma mark -
#pragma mark Custom getter/setter
- (void)setModelViewMatrix:(NSArray *)matrix {
	if (!_modelViewMatrix)
		_modelViewMatrix = (float *) malloc([matrix count] * sizeof(float));
	
	int i = 0;
	
	for (NSNumber *number in matrix) {
		_modelViewMatrix[i] = [number floatValue];
		i++;
	}
}

- (void)setProjectionMatrix:(NSArray *)matrix {
	if (!_projectionMatrix)
		_projectionMatrix = (float *) malloc([matrix count] * sizeof(float));
	
	int i = 0;
	
	for (NSNumber *number in matrix) {
		_projectionMatrix[i] = [number floatValue];
		i++;
	}
}

// Create an OpenGL ES 1.1 context
- (id)init
{
    if ((self = [super init]))
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext:context])
        {
            [self release];
            return nil;
        }
		
		scale = 1;		
    }

    return self;
}

- (void)setupView:(float)viewportWidth height:(float)viewportHeight {
	const GLfloat			lightAmbient[] = {1.0, 1.0, 1.0, 1.0};
	const GLfloat			lightDiffuse[] = {1.0, 1.0, 1.0, 1.0};
	const GLfloat			matAmbient[] = {1.0, 1.0, 1.0, 1.0};
	const GLfloat			matDiffuse[] = {1.0, 1.0, 1.0, 1.0};	
	const GLfloat			matSpecular[] = {1.0, 1.0, 1.0, 1.0};
	const GLfloat			lightPosition[] = {1.0, 1.0, 1.0, 1.0}; 
	const GLfloat			lightShininess = 100.0;
	
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, matAmbient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, matDiffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, matSpecular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, lightShininess);
	glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);	
	glShadeModel(GL_SMOOTH);
	glEnable(GL_DEPTH_TEST);
	
	/*configure the projection*/
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glLoadMatrixf(_projectionMatrix);
	glViewport(0, 0, viewportWidth, viewportHeight);
	
	//Make the OpenGL modelview matrix the default
	glMatrixMode(GL_MODELVIEW);
	
	//We enable normalization
	glEnable(GL_NORMALIZE);
	
	[self addConfigVariable: @"scale"
				  withValue: [NSNumber numberWithFloat: scale]
				andCallback: @"updateScale:"];
}

- (void) mainGameLoop
{
	[self updateGame];
	[self render];
}

- (void)render
{
    if (_modelViewMatrix && self.object) {
		// Make sure that you are drawing to the current context
		[EAGLContext setCurrentContext:context];
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		glPushMatrix();
		glTranslatef(0.0f, -320.f, 0.0f);
		glRotatef(-90.f, 0.0, 0.0, 1.0);
		
		//Setup model view matrix
		glLoadIdentity();
		glLoadMatrixf(_modelViewMatrix);
		
		glScalef(self.object.scaleFactor * scale, 
				 self.object.scaleFactor * scale, 
				 self.object.scaleFactor * scale);
		
		//User defined rotation
		glRotatef(self.object.zRotation + spinZ, 0.0, 0.0, 1.0);
		glRotatef(self.object.yRotation, 0.0, 1.0, 0.0);
		glRotatef(self.object.xRotation, 1.0, 0.0, 0.0);
		glTranslatef(0.0, 0.0, self.object.zTranslation);
		//glRotatef(90.0f, 1.0, 0, 0);
		glTranslatef(0, 0.5, 0);
		//glTranslatef(move, 0.f, 0.f);
		glDrawArrays(GL_TRIANGLES, 0, self.object.numberOfVertices);
		glPopMatrix();
		
		
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
		[context presentRenderbuffer:GL_RENDERBUFFER_OES];	
	}
}

- (void) updateGame
{
	if (animating) {
		spinZ += 2.f;
		
		if (spinZ >= 360.f) {
			spinZ -= 360.f;
		}
	}
	
	move -= 0.2;
	if (move <= 4.f)
		move += 8.5f;
}

- (void) updateScale:(NSNumber*)newScale
{
	if(newScale) {
		int newScaleValue = [newScale floatValue];
		scale = newScaleValue;
	}
}

- (void)loadObject:(Object3D *)object {
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisable(GL_TEXTURE_2D);
	[self unloadTexture];
	
	self.object = object;
	/*configure arrays*/
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3 ,GL_FLOAT, 0, self.object.vertices);
	if (self.object.normals) {
		glEnableClientState(GL_NORMAL_ARRAY);
		glNormalPointer(GL_FLOAT, 0, self.object.normals);
	}
	
	if (self.object.textureCoordinates) {
		[self loadTexture];
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(2, GL_FLOAT, 0, self.object.textureCoordinates); 
	}
}

- (void) unloadTexture {
	glDeleteTextures(1, textures);
}

- (void) loadTexture {
	CGImageRef textureImage = [UIImage imageNamed:self.object.textureFileName].CGImage;
	if (textureImage == nil) {
		NSLog(@"The image for the texture has not been loaded");
		return;   
	}
	
	NSInteger textureWidth = CGImageGetWidth(textureImage);
	NSInteger textureHeight = CGImageGetHeight(textureImage);
	
	// un peu d'allocation dynamique de mémoire...
	GLubyte *textureData = (GLubyte *)malloc(textureWidth * textureHeight * 4); 
	// 4 car RVBA
	
	CGContextRef textureContext = CGBitmapContextCreate(
														textureData,
														textureWidth,
														textureHeight,
														8, textureWidth * 4,
														CGImageGetColorSpace(textureImage),
														kCGImageAlphaPremultipliedLast);
	
	CGContextDrawImage(textureContext,
					   CGRectMake(0.0, 0.0, (float)textureWidth, (float)textureHeight),
					   textureImage);
	
	CGContextRelease(textureContext);
	
	glGenTextures(1,&textures[0]);
	
	glBindTexture(GL_TEXTURE_2D, textures[0]);
	
	glTexImage2D(GL_TEXTURE_2D, 
				 0, 
				 GL_RGBA, 
				 textureWidth, 
				 textureHeight, 
				 0, 
				 GL_RGBA, 
				 GL_UNSIGNED_BYTE, 
				 textureData);
	
	free(textureData);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glEnable(GL_TEXTURE_2D);
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	[self layoutSubViews:layer];

    return YES;
}

- (void) layoutSubViews:(CAEAGLLayer*)layer
{
	BOOL done;
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	done = [self createFramebuffer:layer];
}

- (BOOL) createFramebuffer:(CAEAGLLayer*)layer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Memory management

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)startAnimating {
	animating = TRUE;
}

- (void)stopAnimating {
	animating = FALSE;
}

- (void)dealloc
{
    if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	
	free(_projectionMatrix);
	free(_modelViewMatrix);
	[context release];
	[self.object release];
	[super dealloc];
}

@end
