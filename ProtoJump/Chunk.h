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

#define CHUNK_POS_X     900

typedef enum {
    chunk_single = 1,
    chunk_multi
} Type;

typedef enum {
    chunk_left = 0,
    chunk_top,
    chunk_right,
    chunk_bottom
} Side;

@interface Chunk : NSObject {}

@property float distance;
@property NSMutableArray* obstacles;
@property NSMutableArray* hazards;
@property int chunkType;

-(void)create:(int)chunkType;
-(void)randomize;
-(void)dealloc;

@end
#endif /* Chunk_h */
