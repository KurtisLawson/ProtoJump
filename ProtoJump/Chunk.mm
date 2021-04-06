//
//  Chunk.m
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#include "Chunk.h"

@implementation Chunk

@synthesize obstacles, hazards;
@synthesize chunkType;

-(void)create:(int)chunkType{
    obstacles = [[NSMutableArray alloc]init];
    hazards = [[NSMutableArray alloc]init];
    
    if(chunkType == chunk_single) {
        Obstacle* obs = [[Obstacle alloc]init];
        [obstacles addObject:obs];
    }
}

-(void)randomize {
    if(chunkType == chunk_single) {
        [obstacles[0] randomize];
    }
}

-(void)dealloc {}

@end
