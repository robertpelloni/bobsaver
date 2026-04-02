#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/llBBWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// tiling space by this many cells
#define WIDTH 6
#define HEIGHT 6

// look up tables
// -1 is invisible
// numbers 0,1,2,3 define rotation angle (steps of 90 degrees, clockwise)
// 4 is mirrored arcs (tiles 0 and 2 added together), 5 is the 90 degree rotated version of that
int LUT[WIDTH*HEIGHT] = int[](
-1, 2, 1, 2, 1, -1,
 2, 4, 5, 4, 5,  1,
 3, 4, 4, 4, 4,  0,
 2, 4, 5, 5, 0, -1,
 3, 4, 4, 5, 1, -1,
-1, 3, 0, 3, 0, -1
);
// to be able to move through the generated path we need to know the order of the tiles & arcs
// this look up table tells us what tile we're on
int OFFSET[WIDTH*HEIGHT] = int[](
0,1,44,41,40,0,
3,2,7,42,31,38,
4,5,8,29,32,37,
11,10,15,26,35,0,
12,13,16,21,24,0,
0,18,19,22,23,0
);
// this look up table is a fallback for mirrored tiles so the two arcs have their own offset
int MIRROR_OFFSET[WIDTH*HEIGHT] = int[](
0,0,0,0,0,0,
0,6,43,30,39,0,
0,9,28,33,36,0,
0,14,27,34,0,0,
0,17,20,25,0,0,
0,0,0,0,0,0
);
// flip animation direction
bool FLIP[WIDTH*HEIGHT] = bool[](
    false,false,false,false,false,false,
    false, true, true, true, true,false,
    false,false, true,false, true,false,
    false, true, true,false,false,false,
    false,false, true, true,false,false,
    false,false,false,false,false,false
);
// used for looping
const int MAX_OFFSET = 44;

void main(void)
{
    // get zoomed out UVs
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    uv *= 2.5;
    
    vec2 gUv = uv; // cache unaltered uvs
    
    // compute bounding box of the tiled region
    float bounds = max(abs(uv.x)-float(WIDTH/2),abs(uv.y)-float(HEIGHT/2));
    
    // divide UVs into cells
    vec2 cell = floor(uv);
    cell = clamp(cell, vec2(-WIDTH/2, -HEIGHT/2), vec2(WIDTH/2 - 1, HEIGHT/2 - 1));
    uv -= cell;
    // offset UVs so 0,0 is in the center of each cell
    uv -= 0.5;
    
    // get look up table index from cell
    int idx = clamp(int(cell.x)+WIDTH/2+WIDTH*(int(cell.y)+HEIGHT/2), 0, 48);
    // which tile?
    int state = LUT[idx];
    // arc color (colorized to visualize the offset lookup tables)
    vec3 cl=vec3(0);
    // resulting distance
    float d;
    if(state<0) // -1 tiles are empty
    {
        d = max(bounds,0.75-max(abs(uv.x),abs(uv.y)));
    }
    else
    {
        // track offset for coloring
           int offset = OFFSET[idx] - 1;
        
        // decompose tile state to mirror and rotation
        bool mirror = (state & 4) != 0;
        bool flip = FLIP[idx];
        int rotate = state & ~4;
        if(rotate==1) // rotate 90
            uv = vec2(-uv.y, uv.x);
        else if(rotate==2) // rotate 180
            uv = -uv;
        else if(rotate==3) // rotate 270
            uv = vec2(uv.y, -uv.x);
        if(mirror)
        {
            if(uv.x>-uv.y) // mirror tile along diagonal
            {
                uv = -uv;
                offset = MIRROR_OFFSET[idx] - 1; // update offset
            }
        }
        
        // put arc in corner
        uv += 0.5;
        // circle distance field
        // d=abs(abs(length(uv)-0.5))-0.07;
            
        // warp the space
        float parameter = atan(uv.x, uv.y) / (3.14159265359 * 0.5);
        if(flip)
            parameter = 1.0 - parameter;
        float radius = length(uv) - 0.5;
        uv = vec2(radius * 1.3, (parameter + float(offset)));
        uv.y = mod(uv.y, float(MAX_OFFSET));
        
        d = abs(uv.x) - 0.04;
        
        // colorize by offset
        cl = fract(vec3(0.2, 0.05, 0.01) * float(offset));
        
        // slide a dot over the curve
        float r = length(uv - vec2(0.0, mod(time * 4.0, float(MAX_OFFSET)))) - 0.06;
        if(r < 0.06)
        {
            cl = vec3(1.0, 0.0, 0.0);
            d = r;
        }
        
        d /= 1.3;
    }
    
    float a = smoothstep(0.0, 0.04, d);
    glFragColor = mix(vec4(cl, 1.0), 
                    0.2 * vec4(fract(d * 0.2) * 0.4 + fract(d * 0.5) * 0.3 + fract(d) * 0.2 + fract(d * 3.0) * 0.1), 
                    a);
}
