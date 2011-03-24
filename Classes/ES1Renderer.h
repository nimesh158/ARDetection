//
//  ES1Renderer.h
//  ARDetection
//
//  Created by NIMESH DESAI on 10/19/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class Object3D;

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    /*OpenGL names for the renderbuffer and framebuffers used to render to this view*/
	GLuint viewRenderbuffer, viewFramebuffer;
	
	/*
	 OpenGL name for the depth buffer that is attached to viewFramebuffer, 
	 if it exists (0 if it does not exist)
	 */
	GLuint depthRenderbuffer;
	
	/*The 3DObject that we draw on the view and the current markerID*/
	Object3D *_object;
	
	GLuint textures[1];
	
	float *_projectionMatrix;
	float *_modelViewMatrix;
	
	BOOL animating;
	
	GLfloat scale;
}

/*!
 @brief The Object3D instance displayed
 */
@property (nonatomic, retain) Object3D *object;

/*!
 @brief	Custom setter for the modelViewMatrix, it has as additional effect to redraw the view
 */
- (void)setModelViewMatrix:(NSArray *)matrix;
/*!
 @brief	Custom setter for the projectionMatrix, it has as additional effect to setup and redraw the view
 */
- (void)setProjectionMatrix:(NSArray *)matrix;

- (void) layoutSubViews:(CAEAGLLayer*)layer;
- (void) setupView:(float)viewportWidth height:(float)viewportHeight;
- (void) mainGameLoop;
- (void) startAnimating;
- (void) stopAnimating;
- (void) updateGame;
- (void) render;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (BOOL) createFramebuffer:(CAEAGLLayer*)layer;
- (void) destroyFramebuffer;

- (void) updateScale:(NSNumber*)newScale;

@end
