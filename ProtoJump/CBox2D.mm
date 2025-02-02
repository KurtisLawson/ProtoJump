//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = REFRESH_RATE;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;

class UserData{
public:
    CBox2D* box2D;
    NSString* objectName;
    UserData(CBox2D* box, NSString* name){
        box2D = box;
        objectName = name;
    }
};

#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            
            //first check if the bodys userdata is not null
            if(bodyA->GetUserData() != NULL){
                
                //body data currently contains
                UserData* bodyData = (UserData*)(bodyA->GetUserData());
                CBox2D *parentObj = bodyData->box2D;
                // Call RegisterHit (assume CBox2D object is in user data)
                if([bodyData->objectName isEqualToString:@"Obstacle"]){
                    [parentObj RegisterHit:@"Obstacle"];    // assumes RegisterHit is a callback function to register collision
                }
                if([bodyData->objectName isEqualToString:@"LeftWall"]){
                    [parentObj RegisterHit:@"Hazard"];    // call registerhit to signal that left wall was hit
                }
                if([bodyData->objectName isEqualToString:@"Ground"]){
                    [parentObj RegisterHit:@"Hazard"];    // call registerhit to signal that left wall was hit
                }
                if([bodyData->objectName isEqualToString:@"Hazard"]){
                    [parentObj RegisterHit:@"Hazard"];
                    // call registerhit to signal that hazard was hit
                }
            }
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};

#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;

    b2Body *theLeftWall, *theGround, *thePlayer, *theRoof, *theObstacle, *theLHazard, *theTHazard, *theRHazard, *theBHazard;
    
    UserData *playerData, *wallData, *obstacleData, *groundData, *hazardData;
    
    CContactListener *contactListener;
    CGFloat width, height;
    float totalElapsedTime;
    float step;
    // You will also need some extra variables here for the logic
    bool ballHitLeftWall;
    bool ballHitObstacle;
    bool ballLaunched;
    bool obstacleHitCleaner;
}
@end

@implementation CBox2D

@synthesize xDir, yDir;
@synthesize dead;
@synthesize slowFactor;
@synthesize player;
@synthesize chunk;
//@synthesize _targetVector;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, GRAVITY);
        world = new b2World(*gravity);
        
        b2BodyDef gdBodyDef;
        gdBodyDef.type = b2_staticBody;
        gdBodyDef.position.Set(GROUND_ROOF_POS_X, GROUND_ROOF_PADDING);//width, height of the ground
        theGround = world->CreateBody(&gdBodyDef);
        
        //ground counts as obstacle, since obstacles are non-harmful objects which the ground can be a part of
        groundData = new UserData(self,@"Ground");
        theGround->SetUserData((void*) groundData);
        

        b2PolygonShape gdBox;
        gdBox.SetAsBox(GROUND_ROOF_WIDTH, GROUND_ROOF_HEIGHT);
        theGround->CreateFixture(&gdBox, 0.0f);
        
        b2BodyDef rfBodyDef;
        rfBodyDef.type = b2_staticBody;
        rfBodyDef.position.Set(GROUND_ROOF_POS_X, SCREEN_BOUNDS_Y - GROUND_ROOF_PADDING);
        theRoof = world->CreateBody(&rfBodyDef);
        b2PolygonShape rfBox;
        rfBox.SetAsBox(GROUND_ROOF_WIDTH, GROUND_ROOF_HEIGHT);// physical box
        theRoof->CreateFixture(&rfBox, 0.0f);

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the objects for Box2D
        // Left wall definition
        b2BodyDef leftwallBodyDef;
        leftwallBodyDef.type = b2_kinematicBody;
        leftwallBodyDef.position.Set(Left_Wall_POS_X, Left_Wall_POS_Y);
        theLeftWall = world->CreateBody(&leftwallBodyDef);
        
        wallData = new UserData(self,@"LeftWall");
        
        if (theLeftWall)
        {
            theLeftWall->SetUserData((void *)wallData);
            theLeftWall->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(Left_Wall_WIDTH/2, Left_Wall_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 0.0f;
            theLeftWall->CreateFixture(&fixtureDef);
        }
        
        //player definition
        player = [[Player alloc]init];
        player.initialJump = false;
        player.jumpTimer = 0;
        player.jumpCount = 0;
        player.maxJump = 2;
        b2BodyDef playerBodyDef;
        playerBodyDef.type = b2_dynamicBody;
        playerBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
        thePlayer = world->CreateBody(&playerBodyDef);
        
        playerData = new UserData(self, @"Player");
        
        if (thePlayer)
        {
            
            thePlayer->SetUserData((void *)playerData);
            thePlayer->SetAwake(false);
            b2CircleShape circle;
            circle.m_p.Set(0, 0);
            circle.m_radius = BALL_RADIUS;
            b2FixtureDef circleFixtureDef;
            circleFixtureDef.shape = &circle;
            circleFixtureDef.density = 0.1f;
            circleFixtureDef.friction = 0.3f;
            circleFixtureDef.restitution = 0.0f;
            thePlayer->CreateFixture(&circleFixtureDef);
        }

        //Chunk creation
        chunk = [[Chunk alloc]init];
        
        //Obstacle definition
        b2BodyDef obstacleBodyDef;
        obstacleBodyDef.type = b2_staticBody;
        float posX = [chunk toPixel:chunk.obs.posX :SCREEN_BOUNDS_X + SCREEN_OFFSET]; // Create to the right of the screen
        float posY = [chunk toPixel:chunk.obs.posY :SCREEN_BOUNDS_Y]; // Create based on random position
        obstacleBodyDef.position.Set(posX, posY);
        theObstacle = world->CreateBody(&obstacleBodyDef);
        obstacleData = new UserData(self, @"Obstacle");
        
        if(chunk){
            if (theObstacle)
            {
                float width = [chunk toPixel:chunk.obs.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:chunk.obs.height :SCREEN_BOUNDS_Y];
                theObstacle->SetUserData((void *)obstacleData);
                theObstacle->SetAwake(false);
                b2PolygonShape staticBox;
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theObstacle->CreateFixture(&fixtureDef);
            }
        }
        
        // Hazard Definitions
        // Left Hazard definition
        if(![[chunk.hazards objectAtIndex:haz_left]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_left];
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            float posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X + SCREEN_OFFSET];
            float posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            hazardBodyDef.position.Set(posX, posY);
            theLHazard = world->CreateBody(&hazardBodyDef);
            hazardData = new UserData(self, @"Hazard");
            
            if (theLHazard){
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                theLHazard->SetUserData((void *) hazardData);
                theLHazard->SetAwake(false);
                b2PolygonShape staticBox;
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theLHazard->CreateFixture(&fixtureDef);
            }
        }
        
        //Top Hazard definition
        if(![[chunk.hazards objectAtIndex:haz_top]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_top];
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            float posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X + SCREEN_OFFSET];
            float posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            hazardBodyDef.position.Set(posX, posY);
            theTHazard = world->CreateBody(&hazardBodyDef);
            
            if (theTHazard){
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X + SCREEN_OFFSET];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                theTHazard->SetUserData((void *) hazardData);
                theTHazard->SetAwake(false);
                b2PolygonShape staticBox;
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theTHazard->CreateFixture(&fixtureDef);
            }
        }
        
        //Right Hazard definition
        if(![[chunk.hazards objectAtIndex:haz_right]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_right];
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            float posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X + SCREEN_OFFSET];
            float posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            hazardBodyDef.position.Set(posX, posY);
            theRHazard = world->CreateBody(&hazardBodyDef);
            
            if (theRHazard){
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X + SCREEN_OFFSET];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                theRHazard->SetUserData((void *) hazardData);
                theRHazard->SetAwake(false);
                b2PolygonShape staticBox;
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theRHazard->CreateFixture(&fixtureDef);
            }
        }
        
        //Bottom Hazard definition
        if(![[chunk.hazards objectAtIndex:haz_bottom]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_bottom];
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            float posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X + SCREEN_OFFSET];
            float posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            hazardBodyDef.position.Set(posX, posY);
            theBHazard = world->CreateBody(&hazardBodyDef);
            
            if (theBHazard){
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X + SCREEN_OFFSET];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                theBHazard->SetUserData((void *) hazardData);
                theBHazard->SetAwake(false);
                b2PolygonShape staticBox;
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theBHazard->CreateFixture(&fixtureDef);
            }
        }
        
        totalElapsedTime = 0;
        slowFactor = 1;
        ballHitLeftWall = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        if(player->state == grounded || player->state == leftCollision || player->state == rightCollision){
            player->state = airborne;
            player.jumpCount++;
            thePlayer->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), thePlayer->GetPosition(), true);
            thePlayer->SetLinearVelocity(b2Vec2(xDir * JUMP_MAGNITUDE, yDir * JUMP_MAGNITUDE));
            thePlayer->SetActive(true);
        } else {
            //if the timer is 0, it means they haven't used their double jump yet
            if(player.jumpCount > player.maxJump){
                //if player touches a non hazardous obstacle,reset jump
                if(player->state == grounded || player->state == leftCollision || player->state == rightCollision){
                    player.jumpCount = 0;
                }
            }
            else{
                player.jumpCount++;
                player.jumpTimer = totalElapsedTime;
                thePlayer->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), thePlayer->GetPosition(), true);
                thePlayer->SetLinearVelocity(b2Vec2(xDir * JUMP_MAGNITUDE, yDir * JUMP_MAGNITUDE));
                thePlayer->SetActive(true);
            }
        }
        ballLaunched = false;
    }
    
    //in case the player is already dead, therefore dont update playerposition
    if(!dead){
        [player updatePos:thePlayer->GetPosition().x :thePlayer->GetPosition().y];
        
        //if the ball hit either sides of the wall, apply upward force to negate gravity
        if(player->state == leftCollision||player->state == rightCollision){
            thePlayer->SetGravityScale(0.2);
        } else {
            thePlayer->SetGravityScale(1);
        }
    }

    
    totalElapsedTime += elapsedTime;
    
    if(ballHitLeftWall){
        world->DestroyBody(thePlayer);
        thePlayer = NULL;
        ballHitLeftWall = false;
        dead = true;
    }
    
    if (ballHitObstacle)
    {
        ballHitObstacle = false;
    }


    //Makes the ground and roof in sync of viewport
    if (theGround){
        theGround->SetTransform(b2Vec2(400 + step/SCREEN_BOUNDS_X - step,0), theGround->GetAngle());
    }
    
    if (theRoof){
        theRoof->SetTransform(b2Vec2(400 + step/SCREEN_BOUNDS_X - step,SCREEN_BOUNDS_Y), theGround->GetAngle());
    }
    
    if(theLeftWall){
        theLeftWall->SetTransform(b2Vec2(0 + step/SCREEN_BOUNDS_X - step,SCREEN_BOUNDS_Y/2), theLeftWall->GetAngle());
    }

    // Updating Chunk
    // If chunk has reached the end of the screen create new one
    if((int)theGround->GetPosition().x - SCREEN_BOUNDS_X/2 >= theObstacle->GetPosition().x) {
        // Randomize for new chunk
        [chunk randomize];
        
        // Obstacle update
        // Place to the right of the screen
        float posY = [chunk toPixel:chunk.obs.posY :SCREEN_BOUNDS_Y];
        float posX = theGround->GetPosition().x + SCREEN_BOUNDS_X/2 + SCREEN_OFFSET;
        b2BodyDef obstacleBodyDef;
        obstacleBodyDef.type = b2_staticBody;
        obstacleBodyDef.position.Set(posX, posY);
        theObstacle = world->CreateBody(&obstacleBodyDef);
        
        if (theObstacle)
        {
            theObstacle->SetUserData((void*) obstacleData);
            theObstacle->SetAwake(false);
            b2PolygonShape staticBox;
            float width = [chunk toPixel:chunk.obs.width :SCREEN_BOUNDS_X];
            float height = [chunk toPixel:chunk.obs.height :SCREEN_BOUNDS_Y];
            staticBox.SetAsBox(width/2, height/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 0.0f;
            theObstacle->CreateFixture(&fixtureDef);
        }
        
        // Hazards Update
        // If a Hazard exists on the side being checked, create a body for it.
        // Left Hazard Definition
        if(![[chunk.hazards objectAtIndex:haz_left]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_left];
            posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X] + theGround->GetPosition().x - SCREEN_BOUNDS_X/2 + SCREEN_OFFSET;
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            hazardBodyDef.position.Set(posX, posY);
            theLHazard = world->CreateBody(&hazardBodyDef);
            
            if(theLHazard){
                theLHazard->SetUserData((void*) hazardData);
                theLHazard->SetAwake(false);
                b2PolygonShape staticBox;
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theLHazard->CreateFixture(&fixtureDef);
            }
        }
        // Top Hazard Definition
        if(![[chunk.hazards objectAtIndex:haz_top]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_top];
            posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X] + theGround->GetPosition().x - SCREEN_BOUNDS_X/2 + SCREEN_OFFSET;
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            hazardBodyDef.position.Set(posX, posY);
            theTHazard = world->CreateBody(&hazardBodyDef);
            
            if(theTHazard){
                theTHazard->SetUserData((void*) hazardData);
                theTHazard->SetAwake(false);
                b2PolygonShape staticBox;
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theTHazard->CreateFixture(&fixtureDef);
            }
        }
        // Right Hazard Defitnition
        if(![[chunk.hazards objectAtIndex:haz_right]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_right];
            posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X] + theGround->GetPosition().x - SCREEN_BOUNDS_X/2 + SCREEN_OFFSET;
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            hazardBodyDef.position.Set(posX, posY);
            theRHazard = world->CreateBody(&hazardBodyDef);
            
            if(theRHazard){
                theRHazard->SetUserData((void*) hazardData);
                theRHazard->SetAwake(false);
                b2PolygonShape staticBox;
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theRHazard->CreateFixture(&fixtureDef);
            }
        }
        // Bottom Hazard Definition
        if(![[chunk.hazards objectAtIndex:haz_bottom]  isEqual:[NSNull null]]){
            Hazard* hz = [chunk.hazards objectAtIndex:haz_bottom];
            posY = [chunk toPixel:hz.posY :SCREEN_BOUNDS_Y];
            posX = [chunk toPixel:hz.posX :SCREEN_BOUNDS_X] + theGround->GetPosition().x - SCREEN_BOUNDS_X/2 + SCREEN_OFFSET;
            b2BodyDef hazardBodyDef;
            hazardBodyDef.type = b2_staticBody;
            hazardBodyDef.position.Set(posX, posY);
            theBHazard = world->CreateBody(&hazardBodyDef);
            
            if(theBHazard){
                theBHazard->SetUserData((void*) hazardData);
                theBHazard->SetAwake(false);
                b2PolygonShape staticBox;
                float width = [chunk toPixel:hz.width :SCREEN_BOUNDS_X];
                float height = [chunk toPixel:hz.height :SCREEN_BOUNDS_Y];
                staticBox.SetAsBox(width/2, height/2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &staticBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 0.0f;
                theBHazard->CreateFixture(&fixtureDef);
            }
        }
        
    } else {
        // Update the position in obstacle for Renderer.
        float pixelPos = theObstacle->GetPosition().x - (theGround->GetPosition().x - SCREEN_BOUNDS_X/2);
        chunk.obs.posX = [chunk toDec:pixelPos :SCREEN_BOUNDS_X + SCREEN_OFFSET];
        
        // Update position for each hazard if it exists for Renderer.
        if(![[chunk.hazards objectAtIndex:haz_left]  isEqual:[NSNull null]]) {
            Hazard* hz = [chunk.hazards objectAtIndex:haz_left];
            pixelPos = theLHazard->GetPosition().x -(theGround->GetPosition().x - SCREEN_BOUNDS_X/2);
            hz.posX = [chunk toDec:pixelPos :SCREEN_BOUNDS_X + SCREEN_OFFSET];
        }
        if(![[chunk.hazards objectAtIndex:haz_top]  isEqual:[NSNull null]]) {
            Hazard* hz = [chunk.hazards objectAtIndex:haz_top];
            pixelPos = theTHazard->GetPosition().x -(theGround->GetPosition().x - SCREEN_BOUNDS_X/2);
            hz.posX = [chunk toDec:pixelPos :SCREEN_BOUNDS_X + SCREEN_OFFSET];
        }
        if(![[chunk.hazards objectAtIndex:haz_right]  isEqual:[NSNull null]]) {
            Hazard* hz = [chunk.hazards objectAtIndex:haz_right];
            pixelPos = theRHazard->GetPosition().x -(theGround->GetPosition().x - SCREEN_BOUNDS_X/2);
            hz.posX = [chunk toDec:pixelPos :SCREEN_BOUNDS_X + SCREEN_OFFSET];
        }
        if(![[chunk.hazards objectAtIndex:haz_bottom]  isEqual:[NSNull null]]) {
            Hazard* hz = [chunk.hazards objectAtIndex:haz_bottom];
            pixelPos = theBHazard->GetPosition().x -(theGround->GetPosition().x - SCREEN_BOUNDS_X/2);
            hz.posX = [chunk toDec:pixelPos :SCREEN_BOUNDS_X + SCREEN_OFFSET];
        }
    }
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
    
    //Gravity and the viewport translate speed is slowed
    step -= GAME_SPEED * slowFactor;
    gravity->y = GRAVITY * slowFactor;
    world->SetGravity(*gravity);
}

//Check the name of the object when the player collides with that object
-(void)RegisterHit:(NSString *) objectName
{
    // Set player collision state based on face collided with.
    // Reset jump counter.
    if([objectName  isEqual: @"Obstacle"]){
        [player checkCollision:theObstacle->GetPosition().x :theObstacle->GetPosition().y :chunk.obs.width :chunk.obs.height];
        ballHitObstacle = true;
    }
    
    // Player death on contact with Left Wall, Ground, or Hazards
    if([objectName isEqual:@"Hazard"])
    {
        ballHitLeftWall = true;
    }
}

-(void) SetTargetVector:(float)posX :(float)posY
{
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = thePlayer->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step)/ SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    xDir = posX - currentBallPos.x;
    yDir =  currentBallPos.y - posY;
    
}

// Halt current velocity, set initial target position
-(void)InitiateNewJump:(float)posX :(float)posY
{
    thePlayer->SetLinearVelocity(b2Vec2(0, 0));
    
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = thePlayer->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step) / SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    xDir = posX - currentBallPos.x;
    yDir =  currentBallPos.y - posY;
    
    // Normalize the values
    float vectorMagnitude = sqrt((pow(xDir, 2) + pow(yDir, 2)));
    xDir = xDir / vectorMagnitude;
    yDir = yDir / vectorMagnitude;
}

// Update current position vector
-(void)UpdateJumpTarget:(float)posX :(float)posY
{
    
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = thePlayer->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step)/ SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    xDir = posX - currentBallPos.x;
    yDir = currentBallPos.y - posY;
    
    // Normalize the values
    float vectorMagnitude = sqrt((pow(xDir, 2) + pow(yDir, 2)));
    xDir = xDir / vectorMagnitude;
    yDir = yDir / vectorMagnitude;
}

//
-(void)LaunchJump
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

// Update object position list
-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (thePlayer)
        (*objPosList)["ball"] = thePlayer->GetPosition();
    if (theLeftWall)
        (*objPosList)["leftwall"] = theLeftWall->GetPosition();
    if (theObstacle)
        (*objPosList)["obstacle"] = theObstacle->GetPosition();
    if (theGround)
        (*objPosList)["ground"] = theGround->GetPosition();
    if (theRoof)
        (*objPosList)["roof"] = theRoof->GetPosition();
    if (theLHazard)
        (*objPosList)["HazardLeft"] = theLHazard->GetPosition();
    if (theTHazard)
        (*objPosList)["HazardTop"] = theTHazard->GetPosition();
    if (theRHazard)
        (*objPosList)["HazardRight"] = theRHazard->GetPosition();
    if (theBHazard)
        (*objPosList)["HazardBot"] = theBHazard->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}

@end
