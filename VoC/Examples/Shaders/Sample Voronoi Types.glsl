#version 420

// original https://www.shadertoy.com/view/stBGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Controls (Play with these)
//////////////////////////////////////////////////////////////////

// Increase PROXIMITY_CHECK if you see grid lines
#define PROXIMITY_CHECK 2
#define GRID_SIZE 25.

#define ANIMATE
#define ANIMATION_SPEED 2.

#define RANDOMNESS 1. 

//#define COLORIZE

float N21(vec2 c) {
    return fract(sin(c.x*38.+c.y*367.) * 43891.1791);
}
vec2 N22(vec2 c) {
    return vec2(N21(c-5.), N21(c+5.));
}

void main(void)
{
    // Make UVs Aspect Ratio independant and center at (0,0)
    vec2 uv  = (gl_FragCoord.xy - resolution.xy * .5)/resolution.x;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * GRID_SIZE) - .5;
    vec2 gid = floor(uv * GRID_SIZE);
 
    vec3 col = vec3(0);
    
    float md1 = 1e3;
    float md2 = 2e3;
    float md3 = 3e3;
    float md4 = 4e3;
    
    // Check neighboring Grid cells
    for (int x = -PROXIMITY_CHECK; x <= PROXIMITY_CHECK; x++) {
        for (int y = -PROXIMITY_CHECK; y <= PROXIMITY_CHECK; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id         = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relativeUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p          = N22(id) - .5;
            
            #ifdef ANIMATE
                p = vec2(sin(time * p.x * ANIMATION_SPEED), cos(time * p.y * ANIMATION_SPEED)) * .5;
            #endif
            
            p *= RANDOMNESS;
            
            // Calculate Distance bewtween point and relative UVs)
            float d         = distance(p, relativeUV);
            
            
            if (md1 > d) {
                md4 = md3;
                md3 = md2;
                md2 = md1;
                md1 = d;
            } else if (md2 > d) {
                md4 = md3;
                md3 = md2;
                md2 = d;
            } else if (md3 > d) {
                md4 = md3;
                md3 = d;
            } else if (md4 > d) {
                md4 = d;
            }
            
        
        }
    }
    
    vec2 screenUV = (gl_FragCoord.xy / resolution.xy) - .5;
    if (uv.x < 0. && uv.y > 0.) {
    
        // Normal Voronoi Noise
        col = vec3(md1 / 1.225);
        
        #ifdef COLORIZE
            col = vec3(sin(col.x - .5), sin(col.x), sin(col.x + 1.1));
        #endif
        
    } else if (screenUV.x > 0. && screenUV.y > 0.) {
    
        // Difference between closest and second-closest point
        col = vec3(md2 - md1);
        
        #ifdef COLORIZE
            col = vec3(sin(col.x + .3), sin(col.x + .05), sin(col.x - .3));
        #endif
        
    } else if (screenUV.x < 0. && screenUV.y < 0.) {
        
        // Worley Noise (2nd)
        col = vec3(md2 / 1.414);
        
        #ifdef COLORIZE
            col = vec3(sin(col.x + .24), sin(col.x + .2), sin(col.x + .1));
        #endif
    
    } else if (screenUV.x > 0. && screenUV.y < 0.) {
        
        // Worley Noise (4th)
        col = vec3(md4 / 1.732);
        
        #ifdef COLORIZE
            col = vec3(sin(col.x - .3), sin(col.x + .2), sin(col.x + .6));
        #endif
    
    }
    
    glFragColor = vec4(col,1.0);
}
