#version 420

// original https://www.shadertoy.com/view/tddfWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718

//2D gradient noise from https://www.shadertoy.com/view/XdXGW8
vec2 hash( vec2 x ) {
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

//returns 0 <-> 1
float noise2dgrad( in vec2 p ){
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    float n = mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
    
    return (n * 0.5) + 0.5; //normalize
}

//n: output loops over 0-1 input
//scale: higher for more variation over 0-1 range
//seed: arbitary value to generate different loop
//returns 0 <-> 1
float loopNoise1d(in float n, in float scale, in float seed){
    float x = cos(n * TWO_PI) + seed;
    float y = sin(n * TWO_PI) + seed;
    return noise2dgrad(vec2(x,y) * scale);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    //looping 1d noise every 2 seconds
    float nloop = loopNoise1d(uv.x + time / 5., 1.8, 1.2);
    vec3 col = vec3(step(nloop,uv.y));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
