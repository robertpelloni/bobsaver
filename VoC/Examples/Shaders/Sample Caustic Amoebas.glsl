#version 420

// original https://www.shadertoy.com/view/wl2SzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Tweak of 'Flow of cells' (https://www.shadertoy.com/view/MlsGWX) - mipmap/2019
// Created by sofiane benchaa - sben/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#define FIELD 10.0
#define HEIGHT 0.7
#define ITERATION 2.0
#define TONE vec4(.2,.4,.8,0)
#define SPEED 0.5

float eq(vec2 p,float t){
    float x = sin( p.y-t +cos(t+p.x*.8) ) * cos(p.x-t);
    x *= acos(x);
    return - x * abs(x-.05) * p.x/p.y*4.9;
}

void main(void) {
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec4 X=O;
    vec2  p = FIELD*(U / resolution.xy  +.9);
    float t = time*SPEED,
          hs = FIELD*(HEIGHT+cos(t)*1.9),
          x = eq(p,t), 
          y = p.y-x*0.1;
    
    for(float i=0.; i<ITERATION; ++i)
        p.x *= 1.5,
        X = x + vec4(0, eq(p,t+i+1.), eq(p,t+i+2.) ,0),
        x = X.z += X.y,
        O += TONE / abs(y-X-hs);

    glFragColor = O;
}
