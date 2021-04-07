//
//  Copyright © Borna Noureddin. All rights reserved.
//

//#version 300 es
//
//layout(location = 0) in vec4 position;
//layout(location = 1) in vec4 color;
//out vec4 v_color;
//
//uniform mat4 modelViewProjectionMatrix;
//
//void main()
//{
//    // Simple passthrough shader
//    v_color = color;
//    gl_Position = modelViewProjectionMatrix * position;
//}

#version 300 es

// vertex attributes
layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec2 texCoordIn;
out vec4 v_color;

// output of vertex shader (these will be interpolated for each call to the fragment shader)
out vec3 eyeNormal;
out vec4 eyePos;
out vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

void main()
{
    // Calculate normal vector in eye coordinates
    eyeNormal = (normalMatrix * normal);
    
    // Calculate vertex position in view coordinates
    eyePos = modelViewMatrix * position;
    
    // Pass through texture coordinate
    texCoordOut = texCoordIn;
    
    // Pass through the color
    v_color = color;

    // Set gl_Position with transformed vertex position
    gl_Position = modelViewProjectionMatrix * position;
}

