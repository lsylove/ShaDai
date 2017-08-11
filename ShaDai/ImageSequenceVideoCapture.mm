//
//  ImageSequenceVideoCapture.mm
//  ShaDai
//
//  Created by lsylove on 2017. 8. 11..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#import <vector>
#import <CoreGraphics/CoreGraphics.h>
#import <opencv2/core.hpp>
#import <opencv2/videoio.hpp>
#import <opencv2/video/video.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import "ImageSequenceVideoCapture.h"
#import "OpenCVFunctionality.h"

using namespace std;
using namespace cv;

@implementation ImageSequenceVideoCapture

bool active = false;

vector<Mat> imageSequence;
void(^registeredCallback)(CGImageRef);

Mat fgmask, dst;
Ptr<BackgroundSubtractorMOG2> model = createBackgroundSubtractorMOG2();

OpenCVFunctionality* openCVFunc = [[OpenCVFunctionality alloc] init];

- (void) appendImage: (CGImageRef) image width: (CGFloat) width height: (CGFloat) height {
    Mat cvMat = [openCVFunc imageToMat: image width: width height: height];
    imageSequence.push_back(cvMat);
}

- (void) registerCallback: (void(^)(CGImageRef)) callback {
    registeredCallback = callback;
}

- (void) startWorking: (void(^)()) callback {
    if (active || imageSequence.empty()) {
        return;
    }
    active = true;
    
    cvtColor(imageSequence[0], dst, COLOR_BGRA2RGB);
    
    for (auto ip = imageSequence.begin(); ip != imageSequence.end(); ip++) {
        
        model->apply(*ip, fgmask, -1);
        
        GaussianBlur(fgmask, fgmask, cv::Size(7, 7), 2.5, 2.5);
        threshold(fgmask, fgmask, 10, 255, THRESH_BINARY);
        
        dst = Scalar::all(0);
        ip->copyTo(dst, fgmask);
        
        if (registeredCallback != nullptr) {
            auto image = [openCVFunc matToImage: dst];
            registeredCallback(image);
        }
    }
    
    callback();
}

@end
