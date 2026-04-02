#version 420

// original https://www.shadertoy.com/view/msj3D1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define num 11.
#define Y   time*0.25
#define v1  1.
#define v2  1.
#define v3  1.

#define PI 3.1415926535

//function found here : https://www.shadertoy.com/view/ssByDw
vec2 foldRotate(vec2 p, float s, float offset) {
    
    float t = PI / s;
    float a = PI * 0.5 + t - atan(p.x, p.y) + offset;
    a = mod(a, t*2.) - t ;
    //a = abs(a);
    
    return vec2(cos(a), sin(a)) * length(p);
}

float sdDots( in vec2 p ) {

    p = foldRotate(p,num,0.);

    float sa = sin(PI / num)*v1;
    float n2 = 2./(sa + v3) - 1.; 
    
    float val = pow(n2, floor( log(p.x) / log(n2) + Y) - Y );
            
    float t = length(p-vec2(val,   0.)) - val*sa*v2     ;
    t = min(t,length(p-vec2(val*n2,0.)) - val*sa*n2*v2 );
    
    return t;
}

void main(void) {

    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 m = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;

    float d = sdDots(p);
    
    // coloring (from IQ's shaders)
    vec3 col = vec3(1.0) - sign(d)*vec3(0.1,0.4,0.7);
    col *= 1.0 - exp(-3.0*abs(d));
    col *= 0.8 + 0.2*cos(150.0*d);
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.01,abs(d)) );

    //if( mouse*resolution.xy.z>0.001 ) {
    //    d = sdDots(m);
    //    col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, abs(length(p-m)-abs(d))-0.0025));
    //    col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, length(p-m)-0.015));
    //}

    glFragColor = vec4(col,1.0);
}
