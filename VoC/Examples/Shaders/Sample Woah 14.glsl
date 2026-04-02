#version 420

// original https://www.shadertoy.com/view/Xs33Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// a variant of jt's https://www.shadertoy.com/view/Mdd3R7

#define mirror(v) abs(2. * fract(v / 2.) - 1.)
vec2 pos;

float a = .6;  // * (sqrt(5.)-1.)*2.;

vec2 invtrans(vec2 v) {
     v.x = ceil(v.y)-sqrt(v.x/a);
     v.y -= v.x;
     return v.y*sin(6.283*v.x+vec2(1.57,0));
}

vec4 circ(vec2 v) {
    float s = 1.-smoothstep(.0, .1, abs(fract(v.y)-.5));
    v = pos-invtrans(floor(v+.5)-vec2(0,.5));
    return smoothstep(.4,.5,length(v)) - .3*vec4(0,1,1,0)*s;
}

void main(void)
{
    vec2 R = resolution.xy; 
    vec2 I = gl_FragCoord.xy;
    pos = I = 18.* (I+I-R)/R.y;

    a = (.5+.5*cos(.1*time))*2.47;
    
    I = vec2(0, length(I)) + atan(I.y, I.x) / 6.283;
    I.x = ceil(I.y) - I.x;
    I.x *= I.x *a; // * (sqrt(5.)-1.)*2.;

    glFragColor = circ(I);
}
