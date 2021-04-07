//
//  AnimatedModel.m
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-02.
//

#import "AnimatedModel.h"
#include <OpenGLES/ES3/gl.h>

// macro to hep with GL calls
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_COL,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES
};

@interface AnimatedModel() {
    
    GLuint vao, ibo;    // VAO and index buffer object IDs
    GLuint texture;

    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
    
    // Skeleton data
    Joint *rootJoint;
    int jointCount;
    GLKMatrix4 jointTransforms[50];
    // Animator *animator
}
@end

@implementation AnimatedModel

//@synthesize jointTransforms;

-(id) init:(GLuint)model :(GLuint)tex :(Joint *)root:(int) numJoints {
    self = [super init];
    if (self) {
        NSLog(@"New Animated Model has been initialized");
        // Init matrices
        vao = model;
        texture = tex;
        rootJoint = root;
        jointCount = numJoints;
        for (int i = 0; i < numJoints; ++i) {
            jointTransforms[i] = GLKMatrix4Identity;
        }

        // animator = [[Animator alloc] init]
        [rootJoint calcInverseBindTransform:GLKMatrix4Identity];
    }
    
    return self;
}

-(void) setupVAO {
//    printf("Setting up VAO for imported model... ");
    // First cube (centre, textured)
    glGenVertexArrays(1, &self->vao);
    glGenBuffers(1, &self->ibo);

    // get crate data datas
//    numIndices = glesRenderer.GenCube(1.0f, &self->vertices, &objects[0].normals, &objects[0].texCoords, &objects[0].indices);
    
    // set up VBOs (one per attribute)
    glBindVertexArray(self->vao);
    GLuint vbo[4];
    glGenBuffers(4, vbo);

    // pass on position data
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), self->vertices, GL_STATIC_DRAW);
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
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), self->normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    // pass on texture coordinates
    glBindBuffer(GL_ARRAY_BUFFER, vbo[3]);
    glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), self->texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));
    
    // bind the ibo's
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self->ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(self->indices[0]) * self->numIndices, self->indices, GL_STATIC_DRAW);

    // deselect the VAOs just to be clean
    glBindVertexArray(0);
}

- (void)dealloc
{
    
}

// Returns the VAO containing mesh data for this entity
-(GLuint) getModel {
    return vao;
}

-(GLuint) getTexture {
    return texture;
}

-(Joint *) getRootJoint {
    return rootJoint;
}

//-(void) doAnimation(Animation animation) {
//    [animator doAnimation:animation];
//}

-(void) update {
    // [animator update];
}

-(GLKMatrix4 *) getJointTransforms {
    // 1. Calculate the current state of joint transforms
    [self setJointTransforms:rootJoint];
    
    return jointTransforms;
}

-(void) setJointTransforms:(Joint *) headJoint {
    jointTransforms[headJoint.index] = headJoint.getAnimatedTransform;
    for(Joint *child in headJoint.children) {
        [self setJointTransforms:child];
    }
}



@end
