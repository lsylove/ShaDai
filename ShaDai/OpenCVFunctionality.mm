//
//  OpenCVFunctionality.m
//  ShaDai
//
//  Created by lsylove on 2017. 8. 11..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <opencv2/videoio.hpp>
#import "OpenCVFunctionality.h"

using namespace cv;

@implementation OpenCVFunctionality

- (cv::Mat) imageToMat: (CGImageRef) image width: (CGFloat) cols height: (CGFloat) rows {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (CGImageRef) matToImage: (cv::Mat) cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return imageRef;
}

@end
