#version 420

// original https://www.shadertoy.com/view/fddyRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on tutorial https://www.youtube.com/watch?v=cQXAbndD5CQ

// Radius range of circles (0 <= r <= 1.5)
#define MIN_RAD 0.2
#define MAX_RAD 1.5

// comment out for black and white
#define COLOR

float Xor(float a, float b)
{
    return a*(1.-b) + b*(1.-a);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;

    vec3 col = vec3(0);
    
    // roate & scale uv
    float a = 0.1 * time;
    float s = sin(a);
    float c = cos(a);
    uv *= mat2(c, -s, s, c);
    uv *= 15.;
    
 
    
    // grid uv. Give each box an id
    vec2 gv = fract(uv+0.5) - 0.5;
    vec2 id = floor(uv+0.5);
    
    // draw circle in each gridbox
    // m will accumulate brightness of all circles overlapping current pixel
    // m essentially keeps track of if the number of circle overlaps is even or odd
    float m = 0.;
    float t = time * 2.;

    
    // need to evaluate all 8 circles around the current one so that
    // they can interact
    for(float y=-1.; y<=1.; y++)
    {
        for(float x=-1.; x<=1.; x++)
        {
            // vec that points from current cell to neighbour cell
            vec2 offs = vec2(x, y);
            
            // get d for each cell and add to m
            float d = length(gv - offs);
            // get distance of each box to screen center (uv center)
            float dist = length(id + offs)*.3;
            
            // radius
            float r = mix(MIN_RAD, MAX_RAD, sin(dist - t)*.5 + .5);
            
            // check if circle overlaps are even or odd
            m = Xor(m, smoothstep(r, r*.95, d));
        }
    }
    //col.rg = gv;
    
    #ifdef COLOR
    col += 0.5 + 0.5*vec3(cos(m + time), sin(m + time), sin(m + time));
    #else
    col += m;
    #endif

    glFragColor = vec4(col,1.0);
}
