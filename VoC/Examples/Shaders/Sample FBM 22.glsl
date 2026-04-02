#version 420

// original https://www.shadertoy.com/view/l3ScWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// colormap
vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.);
    vec3 d = vec3(0.563,0.416,0.457 + .2*sin(0.4*time));
    
    return a + b*cos( 6.28 * c * (t+d)); // A + B * cos ( 2pi * (Cx + D) )
}

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u); //sigmoid like function
    
    // bilinear interpolation
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

// used to rotate domain of noise function
const mat2 rot = mat2( 0.80,  0.60, -0.60,  0.80 );

// fast implementation of fBM
float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.500000*noise( p + 0.1 * sin(time ) + 0.2 * time); p = rot*p*2.02;
    f += 0.031250*noise( p  ); p = rot*p*2.01;
    f += 0.250000*noise( p ); p = rot*p*2.03;
    f += 0.125000*noise( p + 0.1 * sin(time) + 0.2 * time ); p = rot*p*2.01;
    f += 0.062500*noise( p + 0.3 * sin(time) ); p = rot*p*2.04;
    f += 0.015625*noise( p );
    return f/0.96875;
}

// nested fBM warping
float pattern( vec2 p ) {
    return fbm( p + fbm( p + fbm(p) ) );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    vec3 col = palette(pattern(uv));
    glFragColor = vec4(col,1.0);
}
