//
//  Hazard.h
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#ifndef Hazard_h
#define Hazard_h

#import <Foundation/Foundation.h>
#define HAZARD_MIN_Size    10.0f

#define HAZARD_POS_X         900
#define HAZARD_MAX_POS_Y     400
#define HAZARD_MIN_POS_Y     200
#define HAZARD_MAX_WIDTH     100.0f
#define HAZARD_MIN_WIDTH     50.0f
#define HAZARD_MAX_HEIGHT    350.0f
#define HAZARD_MIN_HEIGHT    100.0f
#define HAZARD_DISTANCE      900

@interface Hazard : NSObject {}

@property float R, G, B;
@property float width, height;

-(void)randomize:(float)maxSize;
-(void)dealloc;

@end

#endif /* Hazard_h */
