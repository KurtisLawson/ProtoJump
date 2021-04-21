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

// Include player objs
#include "RWTBaseEffect.h"
#include "RWT_LeapUp.h"

// Debug flag to dump ball/brick updated coordinates to console
//#define LOG_TO_CONSOLE

// small struct to hold object-specific information
struct RenderObject
{
    GLuint vao, ibo;    // VAO and index buffer object IDs

    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
};

// uniform variables for shaders
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_LIGHT_SPECULAR_POSITION,
    UNIFORM_LIGHT_DIFFUSE_POSITION,
    UNIFORM_LIGHT_DIFFUSE_COMPONENT,
    UNIFORM_LIGHT_SHININESS,
    UNIFORM_LIGHT_SPECULAR_COMPONENT,
    UNIFORM_LIGHT_AMBIENT_COMPONENT,
    UNIFORM_USE_FOG,
    UNIFORM_USE_TEXTURE,
    UNIFORM_LIGHT_OBJECT,
    UNIFORM_FLASHLIGHT,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_COL,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
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
    int numLeftWallVerts, numBallVerts, numObstacleVerts, numGroundVerts, numRoofVerts, steps;
    
    // textures
    GLuint floorTexture;
    GLuint energyTexture;
    GLuint obstacleTexture;
    GLuint characterTexture;
    
    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;

    GLKMatrix4 modelViewProjectionMatrix;   // model-view-projection matrix
    
    // Player setup
    RWTBaseEffect *_shader;
    RWT_LeapUp *obj_LeapUp;
    
    
    // Environment setup
    RenderObject player;
    RenderObject staticObjects[10];
    
    // Environment animation parameters
    float screenOffset;
    float scrollRate;
    
    float obstacleOffset;
    float obstacleScrollRate;
}

@end

@implementation Renderer

@synthesize box2d;
@synthesize totalElapsedTime;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void) loadPlayerModel {
    
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    
    // Setup player models
    _shader = [[RWTBaseEffect alloc] initWithProgramHandle:programObject];
//    _shader = [[RWTBaseEffect alloc] initWithVertexShader:@"RWTSimpleVertex.glsl" fragmentShader:@"RWTSimpleFragment.glsl"];
    obj_LeapUp = [[RWT_LeapUp alloc] initWithShader:_shader];
    _shader.projectionMatrix = GLKMatrix4MakePerspective(50.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    
}

- (void)loadModels
{
    NSLog(@"Loading Models");
    
    
    [self loadPlayerModel];
    
    // Wall and ceilings:
    for (int i = 0; i < 10; ++i) {
//        [self loadRenderObject:staticObjects[i]];
        // Object vao
        glGenVertexArrays(1, &staticObjects[i].vao);
        glGenBuffers(1, &staticObjects[i].ibo);

        // get crate data
        staticObjects[i].numIndices = glesRenderer.GenCube(1.0f, &staticObjects[i].vertices, &staticObjects[i].normals, &staticObjects[i].texCoords, &staticObjects[i].indices);
        
        // set up VBOs (one per attribute)
        glBindVertexArray(staticObjects[i].vao);
        GLuint vbo[4];
        glGenBuffers(4, vbo);

        // pass on position data
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), staticObjects[i].vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // pass on color data
        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        GLfloat vertCol[24*3];
        for (int k = 0; k<24*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 1.0f;
        }
        
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on normals
        glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), staticObjects[i].normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_NORMAL);
        glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on texture coordinates
        glBindBuffer(GL_ARRAY_BUFFER, vbo[3]);
        glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), staticObjects[i].texCoords, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_TEXTURE);
        glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // bind the ibo's
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, staticObjects[i].ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(staticObjects[i].indices[0]) * staticObjects[i].numIndices, staticObjects[i].indices, GL_STATIC_DRAW);

        // deselect the VAOs just to be clean
        glBindVertexArray(0);
    }
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
    
    // Bind Crate texture
    floorTexture = [self setupTexture:@"steelTemp.jpg"];
    obstacleTexture = [self setupTexture:@"steelAlt.jpg"];
    energyTexture = [self setupTexture:@"blueEnergy.jpg"];
    characterTexture = [self setupTexture:@"ProtoTexture.png"];
    
    // set up lighting values
    specularComponent = GLKVector4Make(0.5f, 0.5f, 0.5f, 1.0f);
    specularLightPosition = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    shininess = 1000.0f;
    ambientComponent = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
    
    staticObjects[0].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    staticObjects[0].diffuseComponent = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);

    // Initialize timer
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
    // Initialize Box2D
    box2d = [[CBox2D alloc] init];
    
    // Init scrolling parameters
    screenOffset = 0;
    scrollRate = 0.06;
    
    obstacleOffset = 0;
    obstacleScrollRate = 0.05;
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
    
    //>>>>>>-------

     //Projection Matrices
        float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
        GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(50.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);    // note bounding box matches Box2D world
    //>>>>>>-------

        // Create lighting components
        glClearColor ( 35.0f/255, 37.0f/255, 40.0f/255, 0.0f );
        specularComponent = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
        ambientComponent = GLKVector4Make(0.4, 0.4, 0.4, 1.0);
//        specularLightPosition = GLKVector4Make(-5, 0.0f, -3, 1.0f);   // make specular light move with camera
    
    // Get the ball and brick objects from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *theObstacle = (((*objPosList).find("obstacle") == (*objPosList).end()) ? nullptr : &(*objPosList)["obstacle"]);
    
    // ******************************************************************
    // initialize MVP matrix for both objects to set the "camera"
    staticObjects[0].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);
    
    screenOffset -= scrollRate * box2d.slowFactor;
    if (screenOffset < -10) {
//        float overflow = screenOffset + 10;
        screenOffset = 0 + 0.1;
    }
    
    obstacleOffset -= obstacleScrollRate * box2d.slowFactor;
    if (obstacleOffset < -9) {
//        float overflow = floorOffset;
        obstacleOffset = 0;
    }
    
//    NSLog(@"Floor offset is %f", screenOffset);
    
    // ******** GROUND 1 **********
    // apply transformations to the ground
    staticObjects[0].mvm = staticObjects[0].mvp = GLKMatrix4Translate(staticObjects[0].mvp, screenOffset, -3, -1.0);
    staticObjects[0].mvm = staticObjects[0].mvp = GLKMatrix4Rotate(staticObjects[0].mvp, 0.0, 1.0, 0.0, 1.0 );
    staticObjects[0].mvm = staticObjects[0].mvp = GLKMatrix4Scale(staticObjects[0].mvp, 10, 1, 3 );
              
    staticObjects[0].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(staticObjects[0].mvp), NULL);
    staticObjects[0].mvp = GLKMatrix4Multiply(perspectiveMatrix, staticObjects[0].mvp);
    
    // initialize MVP matrix for both objects to set the "camera"
    staticObjects[1].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);
    
    // ******** GROUND 2 **********
    // apply transformations to the ground
    staticObjects[1].mvm = staticObjects[1].mvp = GLKMatrix4Translate(staticObjects[1].mvp, 10 + screenOffset, -3, -1.0);
    staticObjects[1].mvm = staticObjects[1].mvp = GLKMatrix4Rotate(staticObjects[1].mvp, 0.0, 1.0, 0.0, 1.0 );
    staticObjects[1].mvm = staticObjects[1].mvp = GLKMatrix4Scale(staticObjects[1].mvp, 11, 1, 3 );
              
    staticObjects[1].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(staticObjects[1].mvp), NULL);
    staticObjects[1].mvp = GLKMatrix4Multiply(perspectiveMatrix, staticObjects[1].mvp);
        
    // ******** LEFT WALL **********
    
    // initialize MVP matrix for both objects to set the "camera"
    staticObjects[2].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);

    // apply transformations to the ground
    staticObjects[2].mvm = staticObjects[2].mvp = GLKMatrix4Translate(staticObjects[2].mvp, -5, 0, -1.0);
    staticObjects[2].mvm = staticObjects[2].mvp = GLKMatrix4Rotate(staticObjects[2].mvp, 0.0, 1.0, 0.0, 1.0 );
    staticObjects[2].mvm = staticObjects[2].mvp = GLKMatrix4Scale(staticObjects[2].mvp, 1, 11, 1 );
              
    staticObjects[2].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(staticObjects[2].mvp), NULL);
    staticObjects[2].mvp = GLKMatrix4Multiply(perspectiveMatrix, staticObjects[2].mvp);
          
    
    // ******** OBSTACLE **********
    if (theObstacle) {
        // initialize MVP matrix for both objects to set the "camera"
        staticObjects[5].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.9);

        // apply transformations to the ground
        staticObjects[5].mvm = staticObjects[5].mvp = GLKMatrix4Translate(staticObjects[5].mvp, (box2d.chunk.obs.posX-0.5) * 10 +0.5, (box2d.chunk.obs.posY-0.5) * 6, 0.0);
        staticObjects[5].mvm = staticObjects[5].mvp = GLKMatrix4Rotate(staticObjects[5].mvp, 0.0, 1.0, 0.0, 1.0 );
        staticObjects[5].mvm = staticObjects[5].mvp = GLKMatrix4Scale(staticObjects[5].mvp, box2d.chunk.obs.width*10,box2d.chunk.obs.height*5, 1 );
                  
        staticObjects[5].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(staticObjects[5].mvp), NULL);
        staticObjects[5].mvp = GLKMatrix4Multiply(perspectiveMatrix, staticObjects[5].mvp);
          //    NSLog(@"Object MVP ");
    }
//
//    if (theObstacle)
//    {
//        Obstacle* obs = box2d.chunk.obs;
//
//        // Set up VAO/VBO for obstacle
//        glGenVertexArrays(1, &obstacleVertexArray);
//        glBindVertexArray(obstacleVertexArray);
//        GLuint vertexBuffers[2];
//        glGenBuffers(2, vertexBuffers);
//
//
//        // VBO for vertex positions
//        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
//        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
//        int k = 0;
//        numObstacleVerts = 0;
//        vertPos[k++] = theObstacle->x - (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y + (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;  // z-value is always set to same value since 2D
//        numObstacleVerts++;
//        vertPos[k++] = theObstacle->x + (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y + (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;
//        numObstacleVerts++;
//        vertPos[k++] = theObstacle->x + (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y - (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;
//        numObstacleVerts++;
//        vertPos[k++] = theObstacle->x - (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y + (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;
//        numObstacleVerts++;
//        vertPos[k++] = theObstacle->x + (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y - (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;
//        numObstacleVerts++;
//        vertPos[k++] = theObstacle->x - (obs.width * SCREEN_BOUNDS_X)/2;
//        vertPos[k++] = theObstacle->y - (obs.height * SCREEN_BOUNDS_Y)/2;
//        vertPos[k++] = 10;
//        numObstacleVerts++;
//        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
//        glEnableVertexAttribArray(ATTRIB_POSITION);
//        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
//
//        // VBO for vertex colours
//        GLfloat vertCol[numObstacleVerts*3];
//        for (k=0; k<numObstacleVerts*3; k+=3)
//        {
//            vertCol[k] = obs.R;
//            vertCol[k+1] = obs.G;
//            vertCol[k+2] = obs.B;
//        }
//        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
//        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
//        glEnableVertexAttribArray(ATTRIB_COL);
//        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
//
//        glBindVertexArray(0);
//    }
    
//    viewMatrix = GLKMatrix4Rotate(viewMatrix, GLKMathDegreesToRadians(20), 1, 0, 0);
    
    // ******** PLAYER **********
    player.mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);
              
//    player.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(player.mvp), NULL);
//    player.mvp = GLKMatrix4Multiply(perspectiveMatrix, player.mvp);
    
    
    
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
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
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
    
    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, steps, 0, 0);
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
    steps -= GAME_SPEED * box2d.slowFactor;
}

- (void)draw:(CGRect)drawRect;
{
    // pass on global lighting, fog and texture values
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_POSITION], 1, specularLightPosition.v);
    glUniform1i(uniforms[UNIFORM_LIGHT_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT], 1, ambientComponent.v);
    
    // Set up GL for draw calls
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    // *************** DRAW ENERGY OBJECTS *****************
    
    // Bind the objects in the staticObject collection
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, energyTexture);
    
    
    for (int i = 0; i < 3; ++i) {
        [self drawRenderObject:staticObjects[i]];
    }
    
    // *************** DRAW STEEL OBJECTS *****************
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, obstacleTexture);
    
    [self drawRenderObject:staticObjects[5]];

    // Pass along updated MVP matrix
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, modelViewProjectionMatrix.m);

    // Retrieve brick and ball positions from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *theObstacle = (((*objPosList).find("obstacle") == (*objPosList).end()) ? nullptr : &(*objPosList)["obstacle"]);
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t", theBall->x, theBall->y);
    if (theLeftWall)
        printf("Brick: (%5.3f,%5.3f)", theLeftWall->x, theLeftWall->y);
    printf("\n");
#endif
    
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 0);
    
    glBindVertexArray(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    
    glBindVertexArray(obstacleVertexArray);
    if(theObstacle && numObstacleVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numObstacleVerts);
    
    // *************** PLAYER *****************
    
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, player.diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, player.diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)player.mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)player.mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, player.normalMatrix.m);
    
    glBindVertexArray(player.vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, player.ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)player.numIndices, GL_UNSIGNED_INT, 0);
    
    [obj_LeapUp renderWithParentModelViewMatrix:player.mvp];
    
//    NSLog
    
}

-(void)drawRenderObject:(RenderObject) obj {
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, obj.diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, obj.diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)obj.mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)obj.mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, obj.normalMatrix.m);
    
    glBindVertexArray(obj.vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)obj.numIndices, GL_UNSIGNED_INT, 0);
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
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(programObject, "modelViewMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    uniforms[UNIFORM_LIGHT_SPECULAR_POSITION] = glGetUniformLocation(programObject, "specularLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION] = glGetUniformLocation(programObject, "diffuseLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT] = glGetUniformLocation(programObject, "diffuseComponent");
    uniforms[UNIFORM_LIGHT_SHININESS] = glGetUniformLocation(programObject, "shininess");
    uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT] = glGetUniformLocation(programObject, "specularComponent");
    uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT] = glGetUniformLocation(programObject, "ambientComponent");
    uniforms[UNIFORM_USE_FOG] = glGetUniformLocation(programObject, "useFog");
    uniforms[UNIFORM_FLASHLIGHT] = glGetUniformLocation(programObject, "useFlashlight");
    uniforms[UNIFORM_USE_TEXTURE] = glGetUniformLocation(programObject, "useTexture");
//    uniforms[UNIFORM_LIGHT_OBJECT] = glGetUniformLocation(programObject, "lit");

    return true;
}

// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

@end

