#version 420

// original https://www.shadertoy.com/view/wdsczl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

#define sat(x) clamp(x, 0., 1.)
#define PI 3.14159265359

float remap(float a, float b, float c, float d, float t)
{
    return sat((t-a)/(b-a)) * (d-c) + c;
}

float snoise(vec2 v) {

    // Precompute values for skewed triangular grid
    const vec4 C = vec4(0.211324865405187,
                        // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,
                        // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,
                        // -1.0 + 2.0 * C.x
                        0.024390243902439);
                        // 1.0 / 41.0

    // First corner (x0)
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other two corners (x1, x2)
    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;

    // Do some permutations to avoid
    // truncation effects in permutation
    i = mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(
                        dot(x0,x0),
                        dot(x1,x1),
                        dot(x2,x2)
                        ), 0.0);

    m = m*m ;
    m = m*m ;

    // Gradients:
    //  41 pts uniformly over a line, mapped onto a diamond
    //  The ring size 17*17 = 289 is close to a multiple
    //      of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt(a0*a0 + h*h);
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

    // Compute final noise value at P
    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    return 130.0 * dot(m, g);
}
vec2 translate(vec2 uv, float shiftX, float shiftY, float factor)
{
    vec2 translate = vec2(shiftX, shiftY);
    uv += translate*factor;
    return uv;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    uv *= 10.;
   
    vec3 col = vec3(0.);

    vec2 uv_i = floor(uv);
    vec2 uv_f = fract(uv);

    float minDist = 100.;
    int neighbourLoc = 4;
    
    for(int y=-neighbourLoc; y < neighbourLoc; y++) {
        for(int x=-neighbourLoc; x < neighbourLoc; x++){
            
            vec2 neighbour = vec2(float(x), float(y));
            vec2 point = random2(uv_i + neighbour);
            point = 0.5 + ( remap( -1., 1., -0.5, 0.5, sin(time)) )*sin(time + 6.2831* point)*snoise(uv)*1.8;
            vec2 diff = neighbour + point - uv_f;  
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    
    col += minDist;
    col += 1.-smoothstep(.2, 0.55, minDist)*1.7;
    //col += 1. - step(.02, minDist);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
