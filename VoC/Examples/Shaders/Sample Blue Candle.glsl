#version 420

// original https://www.shadertoy.com/view/lcBGDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T .4*time
#define PULSE .005*sin(1.2*time)
#define FLAME vec3(.5,.4,.9)

float rand(vec2 c){
     return fract(sin(dot(c ,vec2(2.141,131.234))) * 723.225);   
}

float rect(vec2 p, float a, float b){
    p = abs(p);
    return max(p.x - a, p.y -b);
}

float wall(vec2 p){
    vec2 dim = vec2(1.,2.);
    p -= 2.13;
    p *= .8*dim;
    p.x += 2.5 * floor(p.y);
    
    p = abs(fract(p)) - 1. + .05*dim *1.1*rand(p);
    return step(0., -max(p.x , p.y));
}

float sdCircle(vec2 p, float r){
    return length(p) - r - .06*rand(p) - .7*PULSE;
}

float sdFire(vec2 p){
    float r = .19 + PULSE;
    float x = p.x/r + T + .5*cos(2.5*p.y);
    float d = 2. + sin(10.*x) + .7*cos(40.*x) + .3*sin(.3*x);
        
    p.y -= max(p.y, 0.)*.85*d*r;
    p.x *= 1.15;
    
    return length(p) - r;
}

float sdWax(vec2 p){
    float r = .2;
    
    float x = p.x/r ;    
    float d = 1. + sin(9.*x +0.1);
    
    p.y += .27;
    p.y *= 2.7;
    p.y -= min(p.y, 0.)*1.6*d*r;
    
    return length(p) - r;
}

float transition(float x, float s){
    return clamp(floor(s*x)/s, 0., 1.);
}

vec2  transition(vec2 x, float s){
    return floor(s*x)/s;
}

void main(void)
{ 
    vec2 uv = (2.*gl_FragCoord.xy -resolution.xy)/resolution.y;
    
    uv *= .9;
    uv = transition(uv, 50.);
    
    vec3 col;
    float d;
    
    d = max(.6, wall(uv)) * transition(-sdCircle(uv, .9),6.5);
    col = d * FLAME/2.;
    
    d = step(0., -rect(uv + vec2(0., 1.3), .16, 1.));
    if(d > 0.) 
        col = FLAME * transition(-sdCircle(uv, 1.),6.5);
   
    d = -sdWax(uv);
    if(d > 0.) 
        col = .9*FLAME;
    
    d = step(0., -rect(uv + vec2(0., 0.15), .01, .1));
    if(d > 0.) 
        col = vec3(0.);
    
    d = transition(-8.*sdFire(uv), 3.);
    col = mix(col, mix( FLAME, vec3(.7),d), d);
       
    glFragColor = vec4(col,1.0);
}
