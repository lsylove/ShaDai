//
//  ImageSequenceVideoCapture.h
//  ShaDai
//
//  Created by lsylove on 2017. 8. 11..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#ifndef ImageSequenceVideoCapture_h
#define ImageSequenceVideoCapture_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface ImageSequenceVideoCapture : NSObject

- (void) appendImage: (CGImageRef) image width: (CGFloat) width height: (CGFloat) height;

- (void) registerCallback: (void(^)(CGImageRef)) callback;

- (void) startWorking: (void(^)()) callback;

@end

#endif /* ImageSequenceVideoCapture_h */
