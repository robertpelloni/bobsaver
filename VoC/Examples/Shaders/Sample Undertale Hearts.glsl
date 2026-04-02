#version 420

// original https://www.shadertoy.com/view/wsXBz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RED vec4(1.0,0.3,0.3,0.0)
#define CYAN vec4(0.380, 0.937, 0.941,0.0)
#define GREEN vec4(0.180, 0.694, 0.329,0.0)
#define YELLOW vec4(0.964, 0.917, 0.047,0.0)
#define GOLD vec4(0.909, 0.639, 0.129,0.0)
#define PURPLE vec4(0.631, 0.309, 0.631,0.0)
#define BLUE vec4(0.176, 0.431, 0.925,0.0)
#define M_PI 3.14159265
#define PIXEL_SIZE 10.0

vec2 pixelSnap(vec2 coord)
{
    float pixelation = resolution.y / PIXEL_SIZE;
    return floor(coord * pixelation) / pixelation;
}

float getHeart(vec2 uv,vec2 offset)
{
    vec2 circleMovement = vec2(sin(time+offset.x),cos(time+offset.y))* 0.7;
    circleMovement = pixelSnap(circleMovement);
    uv += circleMovement;
    uv.y *=1.2;
    uv.y -= sqrt(clamp(abs(uv.x)+0.01,0.01,0.1) )*0.4;
    float pixelSize = fwidth(uv.x);
    float radius = 0.2 + pow(sin(2.0+uv.y *1.0) *0.2+0.2,2.0)*-0.1;
    float circle = 1.0 - step(radius,length(uv)); 
    return circle;
}

float getHeart(vec2 uv)
{
    uv.y *=1.2;
    uv.y -= sqrt(clamp(abs(uv.x)+0.01,0.0,0.1) )*0.4;
    float pixelSize = fwidth(uv.x);
    float radius = 0.2 + pow(sin(2.0+uv.y *1.0) *0.2+0.2,2.0)*-0.1;
    float circle = 1.0 - step(radius,length(uv)); 
    return circle;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy)/resolution.y;
    uv = pixelSnap(uv);
    float circut = 2.0 * 3.14;

    vec4 heart1 = getHeart(uv)* RED;
    vec4 heart2 = getHeart(uv,vec2(circut/6.0))* CYAN;
    vec4 heart3 = getHeart(uv,vec2(2.*circut/6.))* GREEN;
    vec4 heart4 = getHeart(uv,vec2(3.*circut/6.))* YELLOW;
    vec4 heart5 = getHeart(uv,vec2(4.*circut/6.))* GOLD;
    vec4 heart6 = getHeart(uv,vec2(5.*circut/6.))* PURPLE;
    vec4 heart7 = getHeart(uv,vec2(6.*circut/6.))* BLUE;

    
    // Time varying pixel color
    // Output to screen
    glFragColor = (heart1 + heart2 + heart3 + heart4 + heart5 + heart6+heart7);
}
