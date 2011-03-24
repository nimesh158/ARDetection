//
//  ESRenderer.h
//  ARDetection
//
//  Created by NIMESH DESAI on 10/19/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@class Object3D;

//Think interface of Java or Pure Virtual Function of C++
@protocol ESRenderer <NSObject>
- (void) mainGameLoop;
- (void) updateGame;
- (void) render;

@optional

- (void) layoutSubViews:(CAEAGLLayer*)layer;
- (void) setupView:(float)viewportWidth height:(float)viewportHeight;
- (void) startAnimating;
- (void) stopAnimating;
- (void) loadObject:(Object3D*)object;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) setModelViewMatrix:(NSArray *)matrix;
- (void) setProjectionMatrix:(NSArray *)matrix;
- (BOOL) createFramebuffer:(CAEAGLLayer*)layer;
- (void) destroyFramebuffer;
- (void) updateScale:(NSNumber*)newScale;
@end
