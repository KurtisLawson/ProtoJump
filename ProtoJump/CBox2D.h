//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "Player.h"
#import "Chunk.h"
#import "Obstacle.h"
#import "Hazard.h"

// Screen bounds and offset for chunks
#define SCREEN_BOUNDS_X        800
#define SCREEN_BOUNDS_Y        600
#define SCREEN_OFFSET          100

// Physics & Game-Speed Parameters
#define JUMP_MAGNITUDE         400
#define GRAVITY                -350
#define REFRESH_RATE           0.05/60
#define GAME_SPEED             5

// Left Wall Parameters
#define Left_Wall_POS_X        0
#define Left_Wall_POS_Y        300
#define Left_Wall_WIDTH        100.0f
#define Left_Wall_HEIGHT       600.0f

// Player Paramters
#define BALL_POS_X             400
#define BALL_POS_Y             300
#define BALL_RADIUS            50.0f
#define BALL_VELOCITY          100000.0f
#define BALL_SPHERE_SEGS       128

// Ground & Roof Parameters
#define GROUND_ROOF_PADDING    10.0f
#define GROUND_ROOF_POS_X      400
#define GROUND_ROOF_WIDTH      800.0f
#define GROUND_ROOF_HEIGHT     10.0f


@interface CBox2D : NSObject

@property float xDir;
@property float yDir;
@property bool dead;
@property float slowFactor;
@property Chunk * chunk;
@property Player * player;

-(void) SetTargetVector:(float)posX :(float)posY; // Set target for player body

-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit:(NSString *) objectName;// Register when the player hits objects
-(void *)GetObjectPositions;        // Get the positions of the player, walls, and chunk objects

-(void) InitiateNewJump:(float) posX :(float) posY;
-(void) UpdateJumpTarget:(float) posX :(float) posY;
-(void) LaunchJump;

@end

#endif
