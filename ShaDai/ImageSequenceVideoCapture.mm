//
//  ImageSequenceVideoCapture.mm
//  ShaDai
//
//  Created by lsylove on 2017. 8. 11..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>

#import <opencv2/core.hpp>
#import <opencv2/videoio.hpp>
#import <opencv2/video/video.hpp>
#import <opencv2/imgproc/imgproc.hpp>

#import "ImageSequenceProcessor.hpp"
#import "ImageSequenceVideoCapture.h"
#import "OpenCVFunctionality.h"

using namespace cv;

@implementation ImageSequenceVideoCapture

void internalProCallback(Mat& mat) {
    if (registeredCallback != nullptr) {
        auto image = [openCVFunc matToImage: mat];
        registeredCallback(image);
    }
}

void internalFinCallback() {
    if (finishCallback != nullptr) {
        finishCallback();
    }
}

bool active = false;
void(^registeredCallback)(CGImageRef);
void(^finishCallback)();

ImageSequenceProcessor processor;
OpenCVFunctionality* openCVFunc = [[OpenCVFunctionality alloc] init];

- (void) appendImage: (CGImageRef) image width: (CGFloat) width height: (CGFloat) height {
    Mat cvMat = [openCVFunc imageToMat: image width: width height: height];
    processor.add(cvMat);
}

- (void) registerCallback: (void(^)(CGImageRef)) callback {
    registeredCallback = callback;
}

- (void) startSession {
    processor.progressCallback = internalProCallback;
    processor.finishCallback = internalFinCallback;
}

- (void) endSession: (void(^)()) callback {
    finishCallback = callback;
    
    processor.endSession();
}

@end
