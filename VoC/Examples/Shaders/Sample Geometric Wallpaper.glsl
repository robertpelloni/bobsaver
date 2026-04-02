#version 420

// original https://www.shadertoy.com/view/MsK3Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define VIGNETTE
#define DITHER
//#define ROTATE
#define GRID_MIN 20.
#define GRID_MAX 200.
#define GRID_SEED 1237.
#define COLOUR_MIN 2.
#define COLOUR_MAX 6.
#define COLOUR_SEED 2356.
#define ORIENTATION_SEED 3456.

// http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float hash(vec2 co) {
float a = 12.9898;
float b = 78.233;
float c = 43758.5453;
float dt= dot(co.xy ,vec2(a,b));
float sn= mod(dt,3.14);
return fract(sin(sn) * c);
}

// http://glslsandbox.com/e#18922.0
vec2 rotate(vec2 p, float a) {
    return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

void calcValue() {
    int frame = int(time);
    float gridSize = floor((GRID_MAX - GRID_MIN + 1.) * hash(vec2(frame, GRID_SEED)) + GRID_MIN); 
    float numColours = floor((COLOUR_MAX - COLOUR_MIN + 1.) * hash(vec2(frame, COLOUR_SEED)) + COLOUR_MIN);
    vec2 square = floor(gl_FragCoord.xy / gridSize); 
    int orientation = int(2. * hash(square + ORIENTATION_SEED + float(frame)));
    vec2 innerCoord = mod(gl_FragCoord.xy, gridSize);
    if(orientation == 1) {innerCoord.y = gridSize - innerCoord.y;}
    vec2 triangle = square * vec2(1.,2.);
    if(innerCoord.x > innerCoord.y) {triangle.y += 1.;}
    float colorIndex = floor(hash(triangle + COLOUR_SEED) * numColours);
    glFragColor.r = hash(vec2(colorIndex + COLOUR_SEED, frame));
    glFragColor.g = hash(vec2(colorIndex + COLOUR_SEED, frame + 1000));
    glFragColor.b = hash(vec2(colorIndex + COLOUR_SEED, frame + 2000));
    //glFragColor.a = 1.;
}

void main(void) {
    
    vec2 coord = gl_FragCoord.xy;
    
    #ifdef ROTATE
        coord = rotate(coord, float(FRAME_CALC));
    #endif
    
    calcValue();

    #ifdef VIGNETTE
        float vignette = 1. - .85 * length(resolution.xy / 2. - gl_FragCoord.xy) / length(resolution.xy / 2.);
        glFragColor.rgb *= pow(vignette,.4);
    #endif

    #ifdef DITHER
        float ditherOffset = mod(mod(gl_FragCoord.x,2.)+mod(gl_FragCoord.y,2.)*2.+2.,4.)/4.-.375;
        vec3 scaledColour = glFragColor.xyz * 256.;
        glFragColor.xyz = floor(scaledColour+ditherOffset)/(vec3(255));
    #endif
}
