//
//  Hazard.h
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#ifndef Hazard_h
#define Hazard_h

#import <Foundation/Foundation.h>

// Hazard constraints
#define HAZ_MIN_V_SIZE  0.02f
#define HAZ_MIN_H_SIZE  0.03f

@interface Hazard : NSObject {}

@property float width, height;
@property float posX, posY;

-(void)vRandomize:(float)minSize :(float)maxSize;
-(void)hRandomize:(float)minSize :(float)maxSize;
-(void)dealloc;

@end

#endif /* Hazard_h */
