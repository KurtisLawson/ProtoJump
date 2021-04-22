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
        // Initialize the obstacle and 4 hazards in array
        obs = [[Obstacle alloc]init];
        hazards = [[NSMutableArray alloc]init];
        [hazards addObject:[NSNull null]];
        [hazards addObject:[NSNull null]];
        [hazards addObject:[NSNull null]];
        [hazards addObject:[NSNull null]];
        [self randomizeHaz];
    }
    return self;
}

-(void)randomize{
    [obs randomize]; // Randomize Obstacle
    [self randomizeHaz]; // Randomize Hazards relative to obstacle
}

-(void)randomizeHaz {
    // Create Hazards and scale them based on obstacle
    int count = 0; // How many hazards have been created
    bool hazExists = [self rollForTrue:HAZ_CHANCE]; // Chance for hazard creation
    
    // For each slot, randomize hazard creation
    for (int i = 0; i < TOTAL_HAZ_SLOTS; i++) {
        // If under max hazards allowed, and hazard chance is true
        if(count < MAX_HAZ && hazExists){
            Hazard* hz = [[Hazard alloc]init];
            
            // Orient the hazard horizontally or vertically based on location on obstacle
            if(i%2 == 0){
                [hz vRandomize:obs.height / MIN_HAZ_RATIO
                              :obs.height / MAX_HAZ_RATIO];
            } else {
                [hz hRandomize:obs.width / MIN_HAZ_RATIO
                              :obs.width / MIN_HAZ_RATIO];
            }
            
            // Add new obstacle to array
            [hazards replaceObjectAtIndex:i withObject:hz];
            count++;
        } else [hazards replaceObjectAtIndex:i withObject:[NSNull null]];
        
        // reroll chance
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
    int randy = arc4random_uniform(100);
    return randy < percentage;
}

-(float)randomDec:(float)min :(float)max {
    float rand = (float) arc4random() / FLT_MAX * (max - min) + min;
    return rand;
}

-(void)dealloc {}

@end
