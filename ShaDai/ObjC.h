//
//  ObjC.h
//  ShaDai
//
//  Created by lsylove on 2017. 8. 2..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

#ifndef ObjC_h
#define ObjC_h

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end

#endif /* ObjC_h */
