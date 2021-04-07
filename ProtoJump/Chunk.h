//
//  Chunk.h
//  ProtoJump
//
//  Created by socas on 2021-04-06.
//

#ifndef Chunk_h
#define Chunk_h

#import <Foundation/Foundation.h>
#include <stdlib.h>

#include "Obstacle.h"
#include "Hazard.h"


#define TOTAL_HAZ_SLOTS 4
#define MAX_HAZ         3
#define HAZ_CHANCE      25
#define MIN_HAZ_RATIO   5.0
#define MAX_HAZ_RATIO   2.0

typedef enum {
    haz_left = 0,
    haz_top,
    haz_right,
    haz_bottom
} Side;

@interface Chunk : NSObject {}

@property Obstacle* obs;
@property NSMutableArray* hazards;

-(void)randomize;
-(float)toPixel:(float)dec :(float)pix;
-(float)toDec:(float)curr :(float)pix;
-(void)dealloc;

@end
#endif /* Chunk_h */
