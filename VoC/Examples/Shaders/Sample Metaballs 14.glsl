#version 420

// original https://www.shadertoy.com/view/wllSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BALL_COUNT 40.
#define TWO_PI 6.2831853

#define COLORIZED

//conversion helper
float f(float n, vec3 hsl){
    float k = mod(n+hsl.x*12., 12.);
    float a = hsl.y*min(hsl.z, 1.-hsl.z);
    return hsl.z-a*max(min(k-3., min(9.-k, 1.)),-1.);
}
// hsl in range <0, 1>^3
vec3 hsl2rgb(vec3 hsl){
    return vec3(f(0.,hsl), f(8.,hsl), f(4.,hsl));
}

vec3 hue2rgb(float hue){
    return hsl2rgb(vec3(hue, 1., .5));
}

//returns vec4 of pseudo-random numbers
vec4 N14(float t){
    vec4 v1 = vec4(123.1, 1024.2, 3456.3, 9564.4);
    vec4 v2 = vec4(248.5, 4861.6, 545.7, 1643.8);
    vec4 v3 = vec4(6547.9, 368.1, 1258.2, 3366.3);
    return fract(sin(t*v1+v2)*v3);
}

//returns inverse of sum of distances from point p to metaballs on screen
float metaBalls(vec2 p, vec2 screen){
    float t = time*.5;
    float s = 0.;
    
    for(float i = 0.; i < BALL_COUNT; i+=1.){
        vec4 rnd = N14(i+1.);
        //random velocity on unit circle
        vec2 vel = vec2(cos(rnd.x*TWO_PI), sin(rnd.x*TWO_PI));
        //calculate position in real world
        vec2 ball = t*vel + rnd.yz*screen;
        
        //map it into the screen so it seems like the balls bounce
        //constrain it in twice the distace to walls
        ball = mod(ball, 2.*screen);
        //the abs makes the bouncing effect
        ball = abs(ball-screen);
        //calclate dist from point p to ball
        float d = length(p-ball);
        //radius in range <4, 8>
        float radius = rnd.w*4.+4.;
        s += .001*radius/d;
    }
    
    return 1./s;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy; //<0, 1>
    float aspect = resolution.x/resolution.y;
    uv.x *= aspect; //correct sizing
    vec2 screen = vec2(aspect, 1.);
    
    vec3 col = vec3(0.);
    
    float d = metaBalls(uv, screen);
    #ifdef COLORIZED
        col = hue2rgb(d);
    #else
        d = clamp(d, 0., 1.);
        col = vec3(d);
    #endif

    glFragColor = vec4(col,1.0);
}
