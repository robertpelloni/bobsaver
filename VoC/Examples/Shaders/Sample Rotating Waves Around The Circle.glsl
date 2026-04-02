#version 420

// original https://www.shadertoy.com/view/3lGSR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI      3.14159265
#define TWO_PI  6.28318530
#define HALF_PI 1.57079633

vec3 circle(vec2 uv, float rad, float i){
    float d  = length(uv);
    float a  = atan(uv.y, uv.x);
    vec3 c = vec3(0.);
    float r = rad; //const
    vec3 colmult;

    if(i == 0.) colmult = vec3(1., 0., 0.);
    if(i == 1.) colmult = vec3(0., 1., 0.);
    if(i == 2.) colmult = vec3(0., 0., 1.);
    
    rad += 0.055*cos(4.*a - i*HALF_PI + time)*pow((1. + cos(a - time))/2., 4.);
    c += smoothstep(rad-0.02, rad+0.05, d);

    rad *= 0.93;
    c -= smoothstep(rad-0.01, rad+0.008, d);
    
    c *= colmult;
    rad = r;
    
    return c;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 col = vec3(1.);
    float rad = 0.35;
        
    col += circle(uv, rad, 0.);
    col += circle(uv, rad, 1.);
    col += circle(uv, rad, 2.);
        
    
    glFragColor = vec4(col, 1.0);
}
