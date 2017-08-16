//
//  ImageSequenceProcessor.hpp
//  ShaDai
//
//  Created by lsylove on 2017. 8. 16..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#ifndef ImageSequenceProcessor_hpp
#define ImageSequenceProcessor_hpp

#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <opencv2/core.hpp>

using namespace std;
using namespace cv;

class ImageSequenceProcessor {
private:
    queue<Mat> sequence;
    thread background;
    mutex lock;
    condition_variable cv;
    bool complete = false;
    
    void backgroundRoutine();
public:
    ImageSequenceProcessor() : background(&ImageSequenceProcessor::backgroundRoutine, this) {}
    
    void (*progressCallback)(Mat&);
    void (*finishCallback)();
    
    void endSession();
    void add(Mat& mat);
};

#endif /* ImageSequenceProcessor_hpp */
