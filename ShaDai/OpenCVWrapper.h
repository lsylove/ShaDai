//
//  OpenCVWrapper.h
//  ShaDai
//
//  Created by chicpark7 on 03/08/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpenCVWrapper : NSObject

+ (UIImage*)detectFace:(UIImage*)image;
+ (UIImage*)detactSkeleton:(UIImage*)image;

@end
