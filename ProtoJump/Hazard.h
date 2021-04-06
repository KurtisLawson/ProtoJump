//
//  Hazard.h
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#ifndef Hazard_h
#define Hazard_h

#import <Foundation/Foundation.h>
#define HAZARD_MIN_SIZE    10.0f

@interface Hazard : NSObject {}

@property float R, G, B;
@property float width, height;
@property bool isVertical;

-(void)randomize:(float)maxSize;
-(void)dealloc;

@end

#endif /* Hazard_h */
