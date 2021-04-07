//
//  Chunk.m
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#include "Chunk.h"

@implementation Chunk

@synthesize obs;
@synthesize hazards;

-(instancetype)init{
    self = [super init];
    if(self){
        obs = [[Obstacle alloc]init];
        hazards = [[NSMutableArray alloc]init];
        [self randomizeHaz];
    }
    return self;
}

-(void)randomize{
    [obs randomize];
    [self randomizeHaz];
}

-(void)randomizeHaz {
    //Create Hazards and scale them
    int count = 0;
    bool hazExists = [self rollForTrue:HAZ_CHANCE];
    
    for (int i = 0; i < TOTAL_HAZ_SLOTS; i++) {
        if(count < MAX_HAZ && hazExists){
            Hazard* hz = [[Hazard alloc]init];
            
            if(i%2 == 0){
                [hz vRandomize:obs.height / MIN_HAZ_RATIO
                              :obs.height / MAX_HAZ_RATIO];
            } else {
                [hz hRandomize:obs.width / MIN_HAZ_RATIO
                              :obs.width / MIN_HAZ_RATIO];
            }
            
            [hazards addObject:hz];
            count++;
        } else [hazards addObject:[NSNull null]];
        
        hazExists = [self rollForTrue:HAZ_CHANCE];
    }
    
    //Position Hazards relative to obs
    Hazard* tmp = [hazards objectAtIndex:haz_left];
    if(![tmp isEqual:[NSNull null]]){
        tmp.posX = obs.posX - obs.width / 2;
        tmp.posY = [self randomDec:obs.posY - obs.height / 4                              :obs.posY + obs.height / 4];
    }
    
    tmp = [hazards objectAtIndex:haz_top];
    if(![tmp isEqual:[NSNull null]]){
        tmp.posY = obs.posY + obs.height / 2;
        tmp.posX = [self randomDec:obs.posX - obs.width / 4                              :obs.posX + obs.width / 4];
    }
    
    tmp = [hazards objectAtIndex:haz_right];
    if(![tmp isEqual:[NSNull null]]){
        tmp.posX = obs.posX + obs.width / 2;
        tmp.posY = [self randomDec:obs.posY - obs.height / 4                              :obs.posY + obs.height / 4];
    }
    
    tmp = [hazards objectAtIndex:haz_bottom];
    if(![tmp isEqual:[NSNull null]]){
        tmp.posY = obs.posY - obs.height / 2;
        tmp.posX = [self randomDec:obs.posX - obs.width / 4                              :obs.posX + obs.width / 4];
    }
}

-(float)toPixel:(float)dec :(float)pix{
    return dec * pix;
}

-(float)toDec:(float)curr :(float)pix{
    return curr / pix;
}

-(bool)rollForTrue:(int)percentage{
    return arc4random_uniform(100) < percentage;
}

-(float)randomDec:(float)min :(float)max {
    return (float)arc4random() / UINT32_MAX * (max - min) + min;
}

-(void)dealloc {}

@end
