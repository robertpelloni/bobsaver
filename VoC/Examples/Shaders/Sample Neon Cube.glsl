#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlf3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Hazel Quantock 2019
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/

const int numCubes = 16;
const float twistStep = .12;
const float scaleStep = 1.03;
const float zoom = 3.;
const float lineThickness = 6.;

// input in range [-1,1] to span resolution.y pixels
float RenderLine( vec2 a, vec2 b )
{
    a = (resolution.y*a + resolution.xy)*.5;
    b = (resolution.y*b + resolution.xy)*.5;
    
    float halfThickness = lineThickness*resolution.y/750.; 

    float halfAASoftening = halfThickness; //.7; // in pixels (don't change this much)
    
    float t = dot(gl_FragCoord.xy-a,b-a);
    t /= dot(b-a,b-a);
    t = clamp( t, 0., 1. );
    return smoothstep( halfThickness-halfAASoftening, halfThickness+halfAASoftening, length(gl_FragCoord.xy - mix(a,b,t)) );
}

    
float RenderLine3D( vec3 a, vec3 b )
{
    vec3 camPos = vec3(0,0,-8);
    
    a -= camPos;
    b -= camPos;
    
    // todo: transform by camera matrix

    a.z /= zoom;
    b.z /= zoom;
    
    // perspective projection
    return RenderLine( a.xy/a.z, b.xy/b.z );
}

// combine 2 anti-aliased values
float BlendAA( float a, float b )
{
    // a and b values represent what proportion of the pixel is covered by each line,
    // but they don't contain enough information to accurately combine them!
    // if both lines are covering the same part of the pixel the result should be min(a,b)
    // if they cover non-overlapping parts of the pixel the result is a-(1-b)
    // a*b assumes the proportion of overlap is the same in the solid and clear regions
    // this is the safest assumption given the lack of any other info

    // but, tune it until it looks good
    return mix( min(a,b), a*b, .5 );
}

void main(void) //WARNING - variables void ( out vec4 fragColour, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_FragCoord
{
    vec4 fragColour = glFragColor;    

    fragColour.rgb = vec3(.8);
  
    float t = time;

    // bendy!
    //t += 3.*dot(gl_FragCoord.xy/resolution.xy,vec2(.8,.5));
    
    vec3 a = vec3(twistStep*cos(t*5./vec3(11,13,17)+1.5));
    mat3 stepTransform =
        scaleStep *
        mat3( cos(a.z), sin(a.z), 0,
             -sin(a.z), cos(a.z), 0,
              0, 0, 1 ) *
        mat3( cos(a.y), 0, sin(a.y),
             0, 1, 0,
             -sin(a.y), 0, cos(a.y) ) *
        mat3( 1, 0, 0,
              0, cos(a.x), sin(a.x),
              0,-sin(a.x), cos(a.x) );

    vec3 b = vec3(.7+t/6.,.7-t/6.,.6);
    mat3 transform = //mat3(1,0,0,0,1,0,0,0,1); // identity
        mat3( cos(b.z), sin(b.z), 0,
             -sin(b.z), cos(b.z), 0,
              0, 0, 1 ) *
        mat3( cos(b.y), 0, sin(b.y),
             0, 1, 0,
             -sin(b.y), 0, cos(b.y) ) *
        mat3( 1, 0, 0,
              0, cos(b.x), sin(b.x),
              0,-sin(b.x), cos(b.x) );

    #define DrawLine(a,b) line = BlendAA( line, RenderLine3D(a,b) );
    
    fragColour.rgb = vec3(.0);
    
    for ( int cube=0; cube < numCubes; cube++ )
    {
        vec3 vertices[8];
        for ( int i=0; i < 8; i++ )
        {
            vertices[i] = transform*(vec3(i>>2,(i>>1)&1,i&1)*2.-1.);
        }
        
        float line = 1.;
        
        DrawLine( vertices[0], vertices[1] );
        DrawLine( vertices[2], vertices[3] );
        DrawLine( vertices[4], vertices[5] );
        DrawLine( vertices[6], vertices[7] );
        DrawLine( vertices[0], vertices[2] );
        DrawLine( vertices[1], vertices[3] );
        DrawLine( vertices[4], vertices[6] );
        DrawLine( vertices[5], vertices[7] );
        DrawLine( vertices[0], vertices[4] );
        DrawLine( vertices[1], vertices[5] );
        DrawLine( vertices[2], vertices[6] );
        DrawLine( vertices[3], vertices[7] );
        
        float f = float(cube)/float(numCubes-1);
        vec3 col = f*smoothstep(-.5,.7,cos(6.283*(f+vec3(0,1,2)/3.)));
        fragColour.rgb += col*(1.f-line);//mix( col, fragColour.rgb, line );
    
        transform *= stepTransform;
    }
    
    fragColour.rgb = pow(fragColour.rgb,vec3(1./2.2));
    fragColour.a = 1.;

    glFragColor = fragColour;
}
