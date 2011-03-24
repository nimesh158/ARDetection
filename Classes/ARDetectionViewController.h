/*
 Copyright 2010 Benjamin Loulier <http://www.benjaminloulier.com> <benlodotcom@gmail.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 */


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ARToolKitPlusWrapper.h"

@class EAGLView;
@class Object3D;
@class RecentCommandsController;

@protocol RecentCommandsDelegate
// Sent when the user selects a row in the recent searches list.
- (void) recentCommandsController:(RecentCommandsController *)controller 
				  didSelectString:(NSString *)commandString;
@end


/*!
 @author Benjamin Loulier
 
 @brief This class is the core of the Application. 
 
 It initializes the capture of frames from the camera, send them to the ARToolKitPlusWrapper, 
 receives the result of the marker detection and pass on those results to the EAGLView.
 */

@interface ARDetectionViewController : UIViewController 
										<AVCaptureVideoDataOutputSampleBufferDelegate,
										ARToolKitPlusWrapperDelegate,
										UISearchBarDelegate,
										UIPopoverControllerDelegate,
										RecentCommandsDelegate> {
@private
	ARToolKitPlusWrapper		*_wrapper;
	EAGLView					*_overlay;
	AVCaptureSession			*_captureSession;
	AVCaptureVideoPreviewLayer	*_previewLayer;
	BOOL						_detectionEnabled;
	int							_currentMarkerID;
	NSDictionary				*_models;
	Object3D*					object;
	UISearchBar					*console;
	RecentCommandsController	*recentCommandsController;
	UIPopoverController			*recentCommandsPopoverController;
	UINavigationController		*recentCommandsNavController;
	BOOL						displayConsole;
	CGFloat						deviceWidth;
	CGFloat						deviceHeight;
}

@property (nonatomic, retain) UISearchBar *console;
@property (nonatomic, retain) RecentCommandsController *recentCommandsController;
@property (nonatomic, retain) UIPopoverController *recentCommandsPopoverController;
@property (nonatomic, retain) UINavigationController *recentCommandsNavController;

- (void)toggleConsole;

/*!
	@brief	The view where the 3D object is shown, this view is overlayed over 
	the ARDetectionViewController's view.
*/
@property (nonatomic, retain) IBOutlet EAGLView *overlay;

/*!
	@brief	This method start the detection of markers in frames from the camera.
*/
- (void)startDetection;

/*!
	@brief	This method stop the detection of markers in frames from the camera.
 */
- (void)stopDetection;

/*!
	@brief	This method tell the EAGLView to animate the 3D Objects displayed
 */
- (IBAction)startStopAnimatingObject:(id)sender;

@end
