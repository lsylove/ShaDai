//
//  OpenCVWrapper.m
//  ShaDai
//
//  Created by chicpark7 on 03/08/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>

#import "OpenCVWrapper.h"
#import <iostream>
#import <stdio.h>
#import <AVKit/AVKit.h>

using namespace cv;

@implementation OpenCVWrapper

+ (UIImage*)detectFace:(UIImage*)image {
    NSString* cascadePath = [[NSBundle mainBundle]
                             pathForResource:@"haarcascade_frontalface_alt"
                             ofType:@"xml"];
    cv::CascadeClassifier faceDetector;
    faceDetector.load([cascadePath UTF8String]);
    
    
    cv::Mat faceImage;
    UIImageToMat(image, faceImage);

    cv::Mat gray;
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    std::vector<cv::Rect>faces;
    faceDetector.detectMultiScale(gray, faces,1.1,2,0|CV_HAAR_SCALE_IMAGE,cv::Size(30,30));

    for(unsigned int i= 0;i < faces.size();i++)
    {
        const cv::Rect& face = faces[i];
        cv::Point tl(face.x,face.y);
        cv::Point br = tl + cv::Point(face.width,face.height);
        
        // 四方形的画法
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
    }
    
    return MatToUIImage(faceImage);
}

+ (UIImage*)detactSkeleton:(UIImage*)image {
    
    cv::Mat img;
    UIImageToMat(image, img);
    
    cv::threshold(img, img, 127, 255, cv::THRESH_BINARY);
    cv::Mat skel(img.size(), CV_8UC1, cv::Scalar(0));
    cv::Mat temp(img.size(), CV_8UC1);
    cv::Mat eroded;
    
    cv::Mat element = cv::getStructuringElement(cv::MORPH_CROSS, cv::Size(3, 3));
    
    bool done;
    do
    {
        cv::morphologyEx(img, temp, cv::MORPH_OPEN, element);
        cv::bitwise_not(temp, temp);
        cv::bitwise_and(img, temp, temp);
        cv::bitwise_or(skel, temp, skel);
        cv::erode(img, img, element);
        
        double max;
        cv::minMaxLoc(img, 0, &max);
        done = (max == 0);
    } while (!done);
    
    return MatToUIImage(img);
    
}

@end
