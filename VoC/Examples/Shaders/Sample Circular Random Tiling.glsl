#version 420

// original https://www.shadertoy.com/view/csVXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
// le random
float rand(vec2 uv){
    return fract(sin(dot(uv,vec2(12.9898,78.233)))*43758.5453123);
}
// le rotate
vec2 rot(vec2 uv, float a){
    return vec2(uv.x*cos(a) - uv.y*sin(a), uv.y*cos(a) + uv.x*sin(a));
}

// 4 different tiles, selected by the choose variable
float tile(vec2 xy, int choose){
    float x = xy.x;
    float y = xy.y;
    
    float tile = 
      choose == 0 
    ? abs(sqrt((pow(abs(x+y)-2.,2.) + pow(x-y,2.))*.5)-1.)
    : choose == 1
    ? abs(sqrt((pow(abs(x-y)-2.,2.) + pow(x+y,2.))*.5)-1.)
    : choose == 2
    ? min(max(abs(x),.75-abs(y)),abs(y))
    : min(max(abs(y),.75-abs(x)),abs(x));
    
    return max(tile, max(abs(.23*x),abs(.23*y)));
}

float f(float x, float y, int choose, float time){
    return tile(
        rot(mod(vec2(x,y)-1.,2.)-1., 
        .25*(PI + PI*tanh(15.*sin(time)))),
        choose) < .25
        ? 1.
        : 0.;
}

vec3 f(vec3 x, vec3 y, int choose, float time){
    return vec3(
        f(x.x,y.x, choose, time),
        f(x.y,y.y, choose, time),
        f(x.z,y.z, choose, time));
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    uv *= 8.;
    
    float x = log2(length(uv)) - time*.25;
    float y = atan(uv.y, uv.x)/PI;
    x *= 5.;
    y *= 24.;
    y += 1.;
    float temp = rand(round(vec2(x,y)*.5));
    float time = time*.5 + 2.*PI*temp;
    int random = int(4.*temp);

    vec3 col = vec3(0.);
    vec3 offset;
    for(float i=0.; i<10.; ++i){
        offset = i+vec3(-5, 0, 5);
        col += .1*f(x-offset*.007, vec3(y), random, time + i*.002);
    }
    col += exp(.1-length(uv));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
