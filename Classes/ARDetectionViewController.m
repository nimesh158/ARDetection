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


#define ADMIN_MODE TRUE

#import <QuartzCore/QuartzCore.h>
#import "RecentCommandsController.h"
#import "GCConfig.h"
#import "ARDetectionViewController.h"
#import "EAGLView.h"
#import "Object3D.h"

#define CONSOLE_BAR_HEIGHT 44.0
#define degreesToRadian(x) (M_PI * (x) / 180.0)

/*!
 Private interface for the ARDetectionViewController class
 */
@interface ARDetectionViewController ()

/*!
	@brief The ARToolKitPlusWrapper instance the controller pass on video frames for marler detection

	The ARDetectionController is also the delegate of this wrapper.
*/
@property (nonatomic, retain) ARToolKitPlusWrapper *wrapper;

/*!
	@brief The capture session we use to capture video frames
 */	
@property (nonatomic, retain) AVCaptureSession *captureSession;

/*!
	@brief The layer displaying the frames from the camera
 */	
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;

/*!
	/n
 */	
@property (nonatomic, assign) BOOL detectionEnabled;

/*!
	@brief The markerID of the current marker detect (-1 if or marker is detected)
 */	
@property (nonatomic, assign) int currentMarkerID;

/*!
	@brief The NSDictionnary loaded from the models.plist file.
 
	This dictionnary uses as key the markerID and as value the corresponding xml description
	file to load. 
 */	
@property (nonatomic, retain) NSDictionary *models;

/*!
	@brief	This methods initialize the capture session.
 
	It sets up the AVCaptureDeviceInput instance, the AVCaptureVideoDataOutput instance and 
	create an AVCaptureSession
	which links the input and the output.\n 
	The format chosen for the capture is kCVPixelFormatType_32BGRA because for now 
	ARToolKitPlusWrapper want BGRA encoded frames.\n
	The queue used is not the main queue, so all the capture and detection
	process is done in a separate thread.
*/

- (void)initCapture;

@end


@implementation ARDetectionViewController

@synthesize wrapper = _wrapper;
@synthesize overlay = _overlay;
@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize detectionEnabled = _detectionEnabled;
@synthesize currentMarkerID = _currentMarkerID;
@synthesize models = _models;
@synthesize console;
@synthesize recentCommandsController;
@synthesize recentCommandsPopoverController;
@synthesize recentCommandsNavController;

#pragma mark -
#pragma mark Initialization

// The designated initializer.  Override if you create the controller programmatically and
//	want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		displayConsole = NO;
		deviceWidth = [UIScreen mainScreen].applicationFrame.size.width;
		deviceHeight = [UIScreen mainScreen].applicationFrame.size.height;
    }
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	/*We initialize some variables*/
	self.currentMarkerID = -1;
	/*We load the models dictionnarry to get the correspondance between markers and models*/
	self.models = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
															  pathForResource:@"models"
															  ofType:@"plist"]];
	/*We start the capture*/
	[self initCapture];
}

- (void)initCapture {
	/* We setup the devie*/
	AVCaptureDevice* device = [AVCaptureDevice 
							   defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	/* 
		To change device properties, we need to get a lockForConfiguration, 
		set the property and then get an unlock to the Configuration
	 */
	if( [device lockForConfiguration:nil] ) {		
		device.focusMode = AVCaptureFocusModeLocked;
		/*
			Check if the device supports exposure mode, if yes, 
			set it to auto exposure
		 */
		if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
			device.exposureMode = AVCaptureFocusModeContinuousAutoFocus;
		 
		}
		[device unlockForConfiguration];
	}
	
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:device 
										  error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	 
	/* 
		set the capture frame to 60 fps
	 */
	
	captureOutput.minFrameDuration = CMTimeMake(1, 30);
	/*
	 For now we use the main queue, it might be better to use a separate queue but 
	 it involves some work as drawing and other operations must be done in the main 
	 thread
	 */
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	/*Set the video output to store frame in BGRA (BGRA is supposed to be more performant)*/
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings]; 
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureSession.sessionPreset = AVCaptureSessionPresetLow;
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
	/*We add the previewLayer*/
	self.previewLayer = [AVCaptureVideoPreviewLayer 
						 layerWithSession: self.captureSession];
	self.previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
	self.previewLayer.frame = self.view.bounds;
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	self.previewLayer.zPosition = -5;
	[self.view.layer addSublayer:self.previewLayer];
}
	
- (void)viewWillAppear:(BOOL)animated {
	if (!self.detectionEnabled) {
		[self startDetection];
	}
}
#pragma mark -
#pragma mark start stop detection

- (void)startDetection {
	/*We start the capture*/
	[self.captureSession startRunning];
	[self.overlay setAnimationFrameInterval:60.0];
	/*We allow the detection*/
	[self.overlay startAnimation];
	self.detectionEnabled = TRUE;
}

- (void)stopDetection {
	/*We stop the capture*/
	[self.captureSession stopRunning];
	[self.overlay stopAnimation];
	/*We disable the detection*/
	self.detectionEnabled = FALSE;
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (self.detectionEnabled) {
		if (!self.wrapper) {
			self.wrapper = [[ARToolKitPlusWrapper alloc] init];
			self.wrapper.delegate = self;
			[self.wrapper setupWithImageBuffer:imageBuffer];
		}
		[self.wrapper detectMarkerInImageBuffer:imageBuffer];
	}
}

#pragma mark -
#pragma mark ARToolKitPlusWrapperDelegate
- (void)aRToolKitPlusWrapper:(ARToolKitPlusWrapper *)wrapper 
		didSetupWithProjectionMatrix:(NSArray *)projectionMatrix {
	[self.overlay performSelectorOnMainThread:@selector(setProjectionMatrix:)
									withObject:projectionMatrix 
									waitUntilDone:YES];
}

- (void)aRToolKitPlusWrapper:(ARToolKitPlusWrapper *)wrapper 
			 didDetectMarker:(int)markerID 
			  withConfidence:(float)confidence
				andComputeModelViewMatrix:(NSArray *)modelViewMatrix 
{	
	/*We create an auto release pool for this thread*/
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	/*We switch the markerID*/
	int previousMarkerID = self.overlay.markerID;
	self.overlay.markerID = markerID;
	
	/*If a marker has been detected*/
	if (markerID != -1) {
		
		/*
			If this ID is different from the previous one we load the 
			corresponding model
		 */
		if ( !self.overlay.objectLoaded ) {
			/*We load the object corresponding to the markerID*/
			NSString *objectFileName = (NSString *) [self.models 
													 objectForKey:[NSString stringWithFormat:@"%d",markerID]];
			object = [Object3D object3DFromFileNamed:objectFileName];
			[self.overlay performSelectorOnMainThread:@selector(loadObject:) 
										   withObject:object 
										waitUntilDone:YES];
			
			NSLog(@"Object loaded : \n%@", [object description]);
		}
		else {
			[self.overlay performSelectorOnMainThread:@selector(loadObject:) 
										   withObject:object 
										waitUntilDone:YES];
		}

		
		/*We set the modelViewMatrix (has as effect to redraw the view)*/
		[self.overlay performSelectorOnMainThread:@selector(setModelViewMatrix:) 
									   withObject:modelViewMatrix 
									waitUntilDone:YES];
		
		/*If the overlay is not displayed we display it*/
		if(!self.overlay.superview) {
			[self.view performSelectorOnMainThread:@selector(addSubview:) 
										withObject:self.overlay 
									 waitUntilDone:YES];
			[self.view performSelectorOnMainThread:@selector(sendSubviewToBack:) 
										withObject:self.overlay 
									 waitUntilDone:YES];
		}
	}
	else {
		
		if (markerID!=previousMarkerID) {		
			/*If the overlay is displayed we hide it*/
			if (self.overlay.superview) 
				[self.overlay performSelectorOnMainThread:@selector(removeFromSuperview) 
																   withObject:nil 
																	waitUntilDone:YES];
	}
	}

	/*We release the pool*/
	[pool drain];
	
}

#pragma mark -
#pragma mark Animation
- (IBAction)startStopAnimatingObject:(id)sender {
	UIButton *button = (UIButton *) sender;
	if (button.selected) {
		button.alpha = 0.5;
		[self.overlay stopAnimating];
	}
	else {
		button.alpha = 1.0;
		[self.overlay startAnimating];
	}
	button.selected = !button.selected;
}

- (void)executeCommand:(NSString *)commandString
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[recentCommandsPopoverController dismissPopoverAnimated:NO];		
	} else {
		[recentCommandsController.tableView removeFromSuperview];
	}
    [console resignFirstResponder];
	
	NSArray *array = [commandString componentsSeparatedByString: @"="];
	NSString *key = nil;
	NSString *value = nil;
	
	if (array.count == 2) {
		key = [array objectAtIndex:0];
		value = [array objectAtIndex:1];
	} else if (array.count == 1) {
		key = [array objectAtIndex:0];
		value = @"YES";		// commands are represented as "command=YES". 
		// We need a value for the key-value pair, but it really doesn't
		// matter what the value is
	}
	
	if (key && key.length && value && value.length) {
		
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *n = [f numberFromString: value];
		[f release];
		
		if (n != nil) {
			[[GCConfig sharedConfig] setValue: n
								   forCommand: key];
		} else {
			[[GCConfig sharedConfig] setValue: value
								   forCommand: key];			
		}
		
	}
}

- (void)toggleConsole
{
	CGFloat consoleBarWidth = 320.0;		// sensible defaults
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if ((orientation == UIDeviceOrientationLandscapeRight) || (orientation == UIDeviceOrientationLandscapeLeft)) {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.height;
	} else {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.width;
	}
	
	// also, make it a singleton instead of creating one per screen
	if (!console) {
		[self setConsole: [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, -CONSOLE_BAR_HEIGHT, consoleBarWidth, CONSOLE_BAR_HEIGHT)]];
		console.barStyle = UIBarStyleBlackTranslucent;
		console.keyboardType = UIKeyboardTypeASCIICapable;
		console.delegate = self;
		
		// Create and configure the recent searches controller.
		RecentCommandsController *aRecentsController = [[RecentCommandsController alloc] initWithStyle:UITableViewStylePlain];
		self.recentCommandsController = aRecentsController;
		recentCommandsController.delegate = self;
		[aRecentsController release];
		
		// Create a navigation controller to contain the recent searches controller, and create the popover controller to contain the navigation controller.
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:recentCommandsController];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
			self.recentCommandsPopoverController = popover;
			recentCommandsPopoverController.delegate = self;
			
			// Ensure the popover is not dismissed if the user taps in the search bar.
			popover.passthroughViews = [NSArray arrayWithObject:console];
			[popover release];
		} else {
			self.recentCommandsNavController = navigationController;
		}
		[navigationController release];
		
		// customize the keyboard
		for (UIView *searchBarSubview in [console subviews]) {
			
            if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
				
                @try {
                    [(UITextField *)searchBarSubview setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [(UITextField *)searchBarSubview setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [(UITextField *)searchBarSubview setReturnKeyType:UIReturnKeyGo];
                    [(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
                }
                @catch (NSException * e) {
					
                    // ignore exception
                }
            }
        }
		
		[self.view addSubview: console];
		
		[console release];
	}
	
	CGRect newFrame = console.frame;
	
	if (displayConsole) {
		newFrame.origin.y -= CONSOLE_BAR_HEIGHT;
		[console resignFirstResponder];
	} else {
		newFrame.origin.y = 0.0;
		[console becomeFirstResponder];
	}
	
	[console setFrame: newFrame];
	
	displayConsole = !displayConsole;
}

#pragma mark -
#pragma mark Search results controller delegate method

- (void)recentCommandsController:(RecentCommandsController *)controller didSelectString:(NSString *)commandString {
    
    /*
     The user selected a row in the recent searches list.
     Set the text in the search bar to the search string, and conduct the search.
     */
    console.text = commandString;
	//    [self executeCommand:commandString];
}

#pragma mark -
#pragma mark Search bar delegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect popoverRect = [console bounds];
		popoverRect.origin.y = CONSOLE_BAR_HEIGHT;
		popoverRect.origin.x = -console.bounds.size.width * 0.5;
		[recentCommandsPopoverController presentPopoverFromRect:popoverRect inView:console permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		CGRect tableViewRect = [console frame];
		tableViewRect.origin.y = CONSOLE_BAR_HEIGHT;
		tableViewRect.size.height *= 2;
		
		[recentCommandsController.tableView setFrame: tableViewRect];
		[self.view addSubview: recentCommandsController.tableView];
		[recentCommandsController.tableView scrollsToTop];
	}
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar {
    
    // If the user finishes editing text in the search bar by, for example tapping away rather than selecting
	// from the recents list, then just dismiss the popover.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[recentCommandsPopoverController dismissPopoverAnimated:NO];		
	} else {
		NSString *commandString = [console text];
		[recentCommandsController addToRecentSearches:commandString];
		[recentCommandsController.tableView removeFromSuperview];
	}
    [aSearchBar resignFirstResponder];
	[self toggleConsole];
}


- (void)console:(UISearchBar *)console textDidChange:(NSString *)searchText {
    
    // When the search string changes, filter the recents list accordingly.
    [recentCommandsController filterResultsUsingString:searchText];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    
    // When the search button is tapped, add the search term to recents and conduct the search.
    NSString *commandString = [console text];
    [recentCommandsController addToRecentSearches:commandString];
    [self executeCommand:commandString];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    // Remove focus from the search bar without committing the search.
    [console resignFirstResponder];
}

#pragma mark -
#pragma mark Housekeeping

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (displayConsole) {
		[self toggleConsole];		
	}
	else {
		NSLog(@"Trying gesture recognizer");
		UISwipeGestureRecognizer *Recognizer = [[[UISwipeGestureRecognizer alloc] 
												 initWithTarget:self 
												 action:@selector(toggleConsole)] 
												autorelease];
		Recognizer.direction = UISwipeGestureRecognizerDirectionUp;
		[self.view addGestureRecognizer:Recognizer];
	}
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
								duration:(NSTimeInterval)duration
{
	CGFloat consoleBarWidth = 320.0;		// sensible defaults
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if ((orientation == UIDeviceOrientationLandscapeRight) || 
		(orientation == UIDeviceOrientationLandscapeLeft)) {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.height;
	} else {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.width;
	}
	
	[console setFrame: CGRectMake(0.0, 0.0, consoleBarWidth, CONSOLE_BAR_HEIGHT)];
}

#pragma mark -
#pragma mark Memory management

- (void)viewWillDisappear:(BOOL)animated {
	[self stopDetection];
}

- (void)viewDidUnload {
	self.overlay = nil;
	self.previewLayer = nil;
	[super viewDidUnload];
}

- (void)dealloc {
	[self.captureSession release];
    [super dealloc];
}


@end
