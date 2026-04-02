#version 420

// original https://www.shadertoy.com/view/3ttfzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    random pixel sprites
    2021 stb
    also posted to http://glslsandbox.com/e#71376
    
    Update: I hopefully fixed most of the grid artifacts.
*/  

// changeables

// enable antialiasing (disable if shader is too slow)
#define aa

const float zoom        = 5.;  // zoom
const float animSpeed   = .1;  // speed of animation
const float mosaic      = 24.; // mosaic (even integers only)
const float spriteSize  = .271; // sprite size (0. to ~.5)
const float offsetSize  = .094;  // size of noise for mask and pattern offsets
const float patternSize = .213;  // size of noise for pattern
const float patternOffs = 2.17; // amount pattern can be perturbed
const float maskOffs    = .312;  // amount mask can be perturbed

// ~changeables

// hash without sine
// https://www.shadertoy.com/view/4djSRW
// Dave_Hoskins
#define MOD3 vec3(.1031, .11369, .13787) // int range
//#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}
vec2 hash23(vec3 p3) {
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

#define o vec3(-1., 0., 1.)

// smooth hash functions
vec2 sHash22(vec2 p) {
    return
        mix(
            mix(
                hash22(floor(p)),
                hash22(floor(p)-o.xy),
                smoothstep(0., 1., fract(p.x))
            ),
            mix(
                hash22(floor(p)-o.yx),
                hash22(floor(p)-o.xx),
                smoothstep(0., 1., fract(p.x))
            ),
            smoothstep(0., 1., fract(p.y))
        );
}
vec2 sHash23(vec3 p) {
    return
        mix(
            mix(
                hash23(floor(p)),
                hash23(floor(p)-o.xyy),
                smoothstep(0., 1., fract(p.x))
            ),
            mix(
                hash23(floor(p)-o.yxy),
                hash23(floor(p)-o.xxy),
                smoothstep(0., 1., fract(p.x))
            ),
            smoothstep(0., 1., fract(p.y))
        );
}

#define mask(o) step(1., 1. - (length(p-maskOffs*(.5-sHash23(vec3(p-o/mosaic, z)/offsetSize))-o/mosaic))+spriteSize)

// random procedural sprites
vec3 procSprites(in vec2 p) {
    
    // a different sprite for each cell
    float z = 53.7823 * hash12(13.3901*floor(p));
    
    // mosaic, repeat, mirror
    p = floor(p*mosaic) / mosaic;
    p = fract(p) - .5;
    p.x = abs(p.x);
    
    // pattern offset
    vec2 off = (.5-sHash22(p/offsetSize)) * patternOffs;
    
    // pattern
    vec3 col = hash33( vec3(floor(p/patternSize-off-z), z) );
    col = pow(col, vec3(.75));
    
    // build up a nice outline from adjacent mask cells
    float mask = mask(0.), outline = mask;
    for(float y=-1.; y<2.; y++)
        for(float x=-1.; x<2.; x++)
            outline = max(outline, mask(vec2(x, y)));
            
    // draw black outline
    if(mask<.5)
        col = vec3(0.);
    
    // draw white background
    if(outline<.5)
        col = vec3(1.);
    
    return col;
}

// blended procSprites
vec3 sProcSprites(in vec2 p, float pxs) {
    vec2 p2 = floor(p*mosaic-.5*mosaic)/mosaic+.5/mosaic;
    return
        mix(
            mix(
                procSprites(p2-o.yy/mosaic),
                procSprites(p2-o.xy/mosaic),
                smoothstep(.5-pxs, .5+pxs, fract(p.x*mosaic))
            ),
            mix(
                procSprites(p2-o.yx/mosaic),
                procSprites(p2-o.xx/mosaic),
                smoothstep(.5-pxs, .5+pxs, fract(p.x*mosaic))
            ),
            smoothstep(.5-pxs, .5+pxs, fract(p.y*mosaic))
        );
}

void main(void) {
    vec2 res = resolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    
    // scrolling
    p.y += animSpeed * time;
    p -= (mouse*resolution.xy.xy-res/2.) / res.y;
    
    // zoom
    p *= zoom;
    
    vec3 col = vec3(0.);
    
    // use antialiasing or not
    #ifdef aa
        col = sProcSprites(p, 1.*mosaic*zoom/res.y);
    #else
        col = procSprites(p);
    #endif
    
    // result
    glFragColor = vec4(col, 1.);
}
