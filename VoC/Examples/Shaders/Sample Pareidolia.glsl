#version 420

// p A r E i D o L i A

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
//#define MOD3 vec3(.1031, .11369, .13787) // int range
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
/*float hash13(vec3 p3) {
    p3  = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}*/

#define pi 3.14159265
#define tx(o) texture(iChannel0, uv-o)

#define T 1.*time

float rStripes(vec2 p, vec2 o, float freq) {
    float ang = 2. * pi * hash12(floor(p)-o);
    vec2 dir = vec2(sin(ang), cos(ang));
    
    float f;
    
    float v = fract(hash12(floor(p)-o+4.)*8.15);
    
    f = .5 + .5 * cos(T+freq*pi*dot(p, dir));
    f *= pow(v, 3.);
    
    //f = 2. * abs(fract(dot(p, dir)+iTime)-.5);
    //f = fract(dot(p, dir)+iTime);
    
    return f;
}

float rStripesLin(vec2 p, float freq) {
    vec3 o = vec3(-1., 0., 1.); 
    return
        mix(
            mix(
                rStripes(p, o.zy, freq),
                rStripes(p, o.yy, freq),
                //fract(p.x)
                smoothstep(0., 1., fract(p.x))
            ),
            mix(
                rStripes(p, o.zx, freq),
                rStripes(p, o.yx, freq),
                //fract(p.x)
                smoothstep(0., 1., fract(p.x))
            ),
            //fract(p.y)
            smoothstep(0., 1., fract(p.y))
        );
}

float map(vec2 p) {
    float f = 0.;
    const float I = 16.;
    for(float i=1.; i<=I; i++) {
        float pw = pow(1.35, i);
        f += rStripesLin(p*pw+i*10., 2.) / pw;
    }
    return f;
}

void main( void ) {
    vec2 res = resolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    
    p *= 4.;
    
    
    
    
    float f = map(vec2(abs(p.x)-.03*T, p.y));
    f -= smoothstep(0., 1., abs(p.x)*.5)-.2;
    
    vec3 RGB1 = .2 - .2*vec3(sin(T), cos(.817*T), sin(.314*T));
    vec3 RGB2 = 1. - .2*vec3(cos(.3*T), sin(.271*T), cos(.1789*T));
    
    glFragColor = vec4(mix(RGB1, RGB2, f), 1.);
}

