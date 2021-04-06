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

-(instancetype)init{
    self = [super init];
    if(self){
        obstacles = [[NSMutableArray alloc]init];
        hazards = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)create:(int)chunkType{
    self.chunkType = chunkType;
    if(chunkType == chunk_single) {
        Obstacle* obs = [[Obstacle alloc]init];
        [obstacles addObject:obs];
        [self randomizeHaz];
    }
}

-(void)randomize{
    if(chunkType == chunk_single) {
        [obstacles[0] randomize];
        [self randomizeHaz];
    }
}

-(void)randomizeHaz {
    int count = 0;
    bool hazExists = [self rollForTrue:HAZ_CHANCE];
    Obstacle* obs = [obstacles objectAtIndex:0];
    
    for (int i = 0; i < TOTAL_HAZ_NUM; i++) {
        if(count < MAX_HAZ_AMOUNT && hazExists){
            Hazard* hz = [[Hazard alloc]init];
            
            if(i%2 == 0){
                hz.isVertical = true;
                [hz randomize:obs.height/2];
            } else {
                hz.isVertical = false;
                [hz randomize:obs.width/2];
            }
            
            [hazards addObject:hz];
            count++;
            hazExists = [self rollForTrue:HAZ_CHANCE];
        } else [hazards addObject:[NSNull null]];
    }
}

-(bool)rollForTrue:(int)percentage{
    return arc4random_uniform(100) < percentage;
}

-(void)dealloc {}

@end
