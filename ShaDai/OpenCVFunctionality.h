//
//  OpenCVFunctionality.h
//  ShaDai
//
//  Created by lsylove on 2017. 8. 11..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#ifndef OpenCVFunctionality_h
#define OpenCVFunctionality_h

#import <Foundation/Foundation.h>
#import <opencv2/videoio.hpp>

@interface OpenCVFunctionality : NSObject

- (cv::Mat) imageToMat: (CGImageRef) image width: (CGFloat) cols height: (CGFloat) rows;

- (CGImageRef) matToImage: (cv::Mat) cvMat;

@end

#endif /* OpenCVFunctionality_h */
