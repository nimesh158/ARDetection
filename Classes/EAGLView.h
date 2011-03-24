//
//  EAGLView.h
//  ARDetection
//
//  Created by NIMESH DESAI on 10/19/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ESRenderer.h"

@class Object3D;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha
// channel.
@interface EAGLView : UIView
{    
@private
    id <ESRenderer> renderer;

    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    /* 
	 Use of the CADisplayLink class is the preferred method for controlling your animation
	 timing. CADisplayLink will link to the main display and fire every vsync when added
	 to a given run-loop.
     The NSTimer class is used only as fallback when running on a pre 3.1 device where
	 CADisplayLink isn't available.
	 */
    id displayLink;
    NSTimer *animationTimer;
	
	//The current marker ID
	int _markerID;
	
	//Object loaded once or not!
	BOOL _objectLoaded;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, assign) int markerID;
@property (nonatomic, assign) BOOL objectLoaded;

/*!
 @brief	Custom setter for the modelViewMatrix, it has as additional effect to redraw
 the view
 */
- (void)setModelViewMatrix:(NSArray *)matrix;
/*!
 @brief	Custom setter for the projectionMatrix, it has as additional effect to setup
 and redraw the view
 */
- (void) setProjectionMatrix:(NSArray *)matrix;
- (void) startAnimating;
- (void) stopAnimating;
- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView;

@end
