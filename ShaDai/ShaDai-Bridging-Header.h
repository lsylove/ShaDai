//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Availability.h>

#ifndef __IPHONE_5_0
#warning "This project uses features only available in iOS SDK 5.0 and later."
#endif

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif

#ifdef __cplusplus

#endif

#import "ObjC.h"
#import "OpenCVWrapper.h"
#import "ImageSequenceVideoCapture.h"
