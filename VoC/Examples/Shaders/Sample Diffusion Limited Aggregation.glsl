#version 420

/*

    A type of diffusion-limited aggregation.
    2015 BeyondTheStatic
    There are two layers:
        1) solution (red)
        2) seed (green)
    
    The solution diffuses and is eaten up as the seed grows.
    Not quite physically-based, and some solution might get lost...

    Place mouse cursor in bottom left corner to reset layers.
    
    changes:
        - fixed brush not drawing in higher resolutions
        - added resetRad constant
*/

// change these settings
#define ToroidalMapping        // <- comment this to disable toroidal mapping
#define ApplyNoise    .35    // <- comment this to disable noise, or you can change the value
const float brushRad    = 1.0;    // <- brush radius in pixels
const float resetRad    = 24.0;    // <- reset zone radius in pixels
float solSub        = 0.75;    // <- amount to subtract from solution
float seedAdd        = 0.325;    // <- amount to add to seed (solid)

float rand(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233)))*43758.5453); }

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int KERNEL_SIZE = 9;
float kernel[KERNEL_SIZE];
vec2 offset[KERNEL_SIZE];

void main( void ) {
    vec2 res  = resolution.xy;
    vec2 uvfc = gl_FragCoord.xy;
    vec2 uv   = uvfc / res;
    vec2 mpos = mouse * res;
    
    // weights for each sample
    kernel [0] = 0.0625;    kernel [1] = 0.125;    kernel [2] = 0.0625;
    kernel [3] = 0.125;    kernel [4] = 0.25;    kernel [5] = 0.125;
    kernel [6] = 0.0625;    kernel [7] = 0.125;    kernel [8] = 0.0625;
    
    // offsets of each sample
    float step_w = 1.0/res.x, step_h = 1.0/res.y;
    offset[0] = vec2(-step_w, -step_h);    offset[1] = vec2(0.0, -step_h);    offset[2] = vec2(step_w, -step_h);
    offset[3] = vec2(-step_w, 0.0);        offset[4] = vec2(0.0, 0.0);    offset[5] = vec2(step_w, 0.0);
    offset[6] = vec2(-step_w, step_h);    offset[7] = vec2(0.0, step_h);    offset[8] = vec2(step_w, step_h);
    
    float R, G, B=0.;
    // init layers
    if(time<=1. || max(mpos.x, mpos.y)<resetRad) {
        R = 1.;
        G = 0.;
    }
    // run sim
    else {
        // unblurred seed layer
        G = texture2D(backbuffer, uv).g;
        
        // randomize a bit
        #ifdef ApplyNoise
            float rnd = ApplyNoise * rand(uv-mod(.1*time, 100.));
            solSub += rnd - .5 * ApplyNoise;
            seedAdd += rnd - .5 * ApplyNoise;
        #endif
        
        // create blurred versions of solution and seed
        float Sol=0.0, Seed=0.0;
        for(int i=0; i<KERNEL_SIZE; i++) {
            vec2 sample;
            #ifdef ToroidalMapping
                sample = kernel[i] * texture2D(backbuffer, fract(uv-offset[i])).rg;
            #else
                sample = kernel[i] * texture2D(backbuffer, uv-offset[i]).rg;
            #endif
            Sol += sample.r;
            Seed += sample.g;
        }
        
        // R is now the blurred solution
        R = Sol;
        
        // remove solution based on amount in seed layer
        R -= solSub * G;
        
        // grow seed based on amount of solution
        G += seedAdd * Seed * Sol;
        
        // draw a dot under mouse pos
        G += clamp(1.0-length(uvfc-mpos)/brushRad, 0., 1.);
    }
    
    // show reset box
    if(max(uvfc.x, uvfc.y)<resetRad){ B=1.; }
    
    // result
    glFragColor = vec4(R, G, B, 1.);
}
