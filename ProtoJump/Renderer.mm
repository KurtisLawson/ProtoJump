//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"
#include <Box2D/Box2D.h>
#include <map>

// Debug flag to dump ball/brick updated coordinates to console
//#define LOG_TO_CONSOLE

// Simple 2D rendering, so only need MVP matrix
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Two vertex attribute
enum
{
    ATTRIB_POS,
    ATTRIB_COL,
    NUM_ATTRIBUTES
};

// Used to make the VBO code more readable
#define BUFFER_OFFSET(i) ((char *)NULL + (i))


@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;    // used to calculated elapsed time

    GLuint brickVertexArray, ballVertexArray, groundVertexArray, roofVertexArray, obstacleVertexArray;   // vertex arrays for brick and ball
    int numLeftWallVerts, numBallVerts, numObstacleVerts, numGroundVerts, numRoofVerts;
    float step;
    GLKMatrix4 modelViewProjectionMatrix;   // model-view-projection matrix
}

@end

@implementation Renderer

@synthesize box2d;
@synthesize totalElapsedTime;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    
}

- (void)setup:(GLKView *)view
{
    // Set up OpenGL ES
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    
    // Load shaders
    if (![self setupShaders])
        return;

    // Set background colours and initialize timer
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
    // Initialize Box2D
    box2d = [[CBox2D alloc] init];
}

- (void)update
{
    // Calculate elapsed time and update Box2D
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    [box2d Update:elapsedTime/1000.0f];
    if(!box2d.dead){
        totalElapsedTime += (elapsedTime/1000.0f) * box2d.slowFactor;
    }
    // Get the ball and brick objects from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *theLeftWall = (((*objPosList).find("leftwall") == (*objPosList).end()) ? nullptr : &(*objPosList)["leftwall"]);
    b2Vec2 *theObstacle = (((*objPosList).find("obstacle") == (*objPosList).end()) ? nullptr : &(*objPosList)["obstacle"]);
    b2Vec2 *theGround = (((*objPosList).find("ground") == (*objPosList).end()) ? nullptr : &(*objPosList)["ground"]);
    b2Vec2 *theRoof = (((*objPosList).find("roof") == (*objPosList).end()) ? nullptr : &(*objPosList)["roof"]);

    if (theLeftWall)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &brickVertexArray);
        glBindVertexArray(brickVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numLeftWallVerts = 0;
        vertPos[k++] = theLeftWall->x - Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y + Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numLeftWallVerts++;
        vertPos[k++] = theLeftWall->x + Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y + Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;
        numLeftWallVerts++;
        vertPos[k++] = theLeftWall->x + Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y - Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;
        numLeftWallVerts++;
        vertPos[k++] = theLeftWall->x - Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y + Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;
        numLeftWallVerts++;
        vertPos[k++] = theLeftWall->x + Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y - Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;
        numLeftWallVerts++;
        vertPos[k++] = theLeftWall->x - Left_Wall_WIDTH/2;
        vertPos[k++] = theLeftWall->y - Left_Wall_HEIGHT/2;
        vertPos[k++] = 10;
        numLeftWallVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numLeftWallVerts*3];
        for (k=0; k<numLeftWallVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }


    if (theBall)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &ballVertexArray);
        glBindVertexArray(ballVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex colours
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];    // triangle fan, so need 3 coords for each vertex; need to close the sphere; and need the center of the sphere
        int k = 0;
        // Center of the sphere
        vertPos[k++] = theBall->x;
        vertPos[k++] = theBall->y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            vertPos[k++] = theBall->x + sin(t)*BALL_RADIUS;
            vertPos[k++] = theBall->y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (theObstacle)
    {
        // Set up VAO/VBO for obstacle
        glGenVertexArrays(1, &obstacleVertexArray);
        glBindVertexArray(obstacleVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numObstacleVerts = 0;
        vertPos[k++] = theObstacle->x - box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y + box2d.obstacle.height/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numObstacleVerts++;
        vertPos[k++] = theObstacle->x + box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y + box2d.obstacle.height/2;
        vertPos[k++] = 10;
        numObstacleVerts++;
        vertPos[k++] = theObstacle->x + box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y - box2d.obstacle.height/2;
        vertPos[k++] = 10;
        numObstacleVerts++;
        vertPos[k++] = theObstacle->x - box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y + box2d.obstacle.height/2;
        vertPos[k++] = 10;
        numObstacleVerts++;
        vertPos[k++] = theObstacle->x + box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y - box2d.obstacle.height/2;
        vertPos[k++] = 10;
        numObstacleVerts++;
        vertPos[k++] = theObstacle->x - box2d.obstacle.width/2;
        vertPos[k++] = theObstacle->y - box2d.obstacle.height/2;
        vertPos[k++] = 10;
        numObstacleVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numObstacleVerts*3];
        for (k=0; k<numObstacleVerts*3; k+=3)
        {
            vertCol[k] = box2d.obstacle.R;
            vertCol[k+1] = box2d.obstacle.G;
            vertCol[k+2] = box2d.obstacle.B;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }

    if (theGround)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &groundVertexArray);
        glBindVertexArray(groundVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numGroundVerts = 0;
        vertPos[k++] = theGround->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numGroundVerts++;
        vertPos[k++] = theGround->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numGroundVerts++;
        vertPos[k++] = theGround->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numGroundVerts++;
        vertPos[k++] = theGround->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numGroundVerts++;
        vertPos[k++] = theGround->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numGroundVerts++;
        vertPos[k++] = theGround->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theGround->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numGroundVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numGroundVerts*3];
        for (k=0; k<numGroundVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 1.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }

    if (theRoof)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &roofVertexArray);
        glBindVertexArray(roofVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numRoofVerts = 0;
        vertPos[k++] = theRoof->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numRoofVerts++;
        vertPos[k++] = theRoof->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numRoofVerts++;
        vertPos[k++] = theRoof->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numRoofVerts++;
        vertPos[k++] = theRoof->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y + GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numRoofVerts++;
        vertPos[k++] = theRoof->x + GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numRoofVerts++;
        vertPos[k++] = theRoof->x - GROUND_ROOF_WIDTH/2;
        vertPos[k++] = theRoof->y - GROUND_ROOF_HEIGHT/2;
        vertPos[k++] = 10;
        numRoofVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numRoofVerts*3];
        for (k=0; k<numRoofVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 1.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);    // note bounding box matches Box2D world
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, step, 0, 0);
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    step -= GAME_SPEED * box2d.slowFactor;
}

- (void)draw:(CGRect)drawRect;
{
    // Set up GL for draw calls
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    // Pass along updated MVP matrix
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, modelViewProjectionMatrix.m);

    // Retrieve brick and ball positions from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *theLeftWall = (((*objPosList).find("leftwall") == (*objPosList).end()) ? nullptr : &(*objPosList)["leftwall"]);
    b2Vec2 *theObstacle = (((*objPosList).find("obstacle") == (*objPosList).end()) ? nullptr : &(*objPosList)["obstacle"]);
    b2Vec2 *theGround = (((*objPosList).find("ground") == (*objPosList).end()) ? nullptr : &(*objPosList)["ground"]);
    b2Vec2 *theRoof = (((*objPosList).find("roof") == (*objPosList).end()) ? nullptr : &(*objPosList)["roof"]);
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t", theBall->x, theBall->y);
    if (theLeftWall)
        printf("Brick: (%5.3f,%5.3f)", theLeftWall->x, theLeftWall->y);
    printf("\n");
#endif

    // Bind each vertex array and call glDrawArrays for each of the ball and brick
    glBindVertexArray(brickVertexArray);
    if (theLeftWall && numLeftWallVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numLeftWallVerts);

    glBindVertexArray(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    
    glBindVertexArray(obstacleVertexArray);
    if(theObstacle && numObstacleVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numObstacleVerts);
    glBindVertexArray(groundVertexArray);
    if (theGround && numGroundVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numGroundVerts);
    
    glBindVertexArray(roofVertexArray);
    if (theRoof && numRoofVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numRoofVerts);
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");

    return true;
}

@end

