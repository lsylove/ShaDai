//
//  ImageSequenceProcessor.cpp
//  ShaDai
//
//  Created by lsylove on 2017. 8. 16..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#include "ImageSequenceProcessor.hpp"
#include <opencv2/video/video.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace std;
using namespace cv;

void ImageSequenceProcessor::backgroundRoutine() {
    Mat fgmask, dst;
    Ptr<BackgroundSubtractorMOG2> model = createBackgroundSubtractorMOG2();
    
    while (true) {
        if (!sequence.empty()) {
            goto process;
        }
        {
            unique_lock<mutex> guard(lock);
            cv.wait(guard, [&]{ return !sequence.empty() || complete; });
        }
        if (complete) {
            break;
        }
        
    process:
        
        Mat src = sequence.front();
        sequence.pop();
        
        cvtColor(src, dst, COLOR_BGRA2RGB);
            
        model->apply(src, fgmask, -1);
        
        GaussianBlur(fgmask, fgmask, cv::Size(7, 7), 2.5, 2.5);
        threshold(fgmask, fgmask, 10, 255, THRESH_BINARY);
        
        dst = Scalar::all(0);
        src.copyTo(dst, fgmask);
        
        if (progressCallback != nullptr) {
            progressCallback(dst);
        }
    }
    
    if (finishCallback != nullptr) {
        finishCallback();
    }
}

void ImageSequenceProcessor::endSession() {
    complete = true;
    cv.notify_one();
}

void ImageSequenceProcessor::add(Mat& mat) {
    {
        lock_guard<mutex> guard(lock);
        sequence.push(mat);
    }
    cv.notify_one();
}
