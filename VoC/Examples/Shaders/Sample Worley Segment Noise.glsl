#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ls3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Comparing normal Worley noise with "segment Worley noise"
// A little bit of something old, something new, and something borrowed.

// XY range of the display.
#define DISP_SCALE 6.0 

// rescaling function

float rescale(float x, vec2 range)
{
      float a = range.x, b = range.y;
      return (x - a)/(b - a);
}

// modified MATLAB hot colormap

vec3 hot( float t )
{
     return clamp(vec3(3.0, 3.0, 4.0) * t - vec3(0.0, 1.0, 3.0), 0.0, 1.0);
}

// simple LCG

#define LCG(k) k = (65 * k) % 1021
#define lr(k) float(k)/1021.

// permutation polynomial

int permp (int i1, int i2)
{
      int t = (i1 + i2) & 255;
        
      return ((112 * t + 153) * t + 151) & 255;
}

// normal (Euclidean) Worley noise
// return the two closest distances

vec2 worley(vec2 p)
{
    vec2 dl = vec2(20.0);
    ivec2 iv = ivec2(floor(p));
    vec2 fv = fract(p);
    
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++)
        {
            int s = permp(permp(0, iv.y + j), iv.x + i); LCG(s); // seeding
            
            for (int m = 0; m < 2; m++) // two points per cell
            {
                LCG(s); float sy = lr(s);
                LCG(s); float sx = lr(s);
                
                vec2 tp = vec2(i, j) + vec2(sx, sy) - fv;
                float c = dot(tp, tp);
                
                float m1 = min(c, dl.x), m2 = max(c, dl.x); // ranked distances
                dl = vec2(min(m1, dl.y), max(m1, min(m2, dl.y)));
            }
        }
        
      return sqrt(dl);
}

// Worley variant using point-segment distance.
// instead of "feature points", "feature segments" are generated per cell
// everything else is the same

vec2 worleyseg(vec2 p)
{
    vec2 dl = vec2(20.0);
    ivec2 iv = ivec2(floor(p));
    vec2 fv = fract(p);
    
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++)
        {
            int s = permp(permp(0, iv.y + j), iv.x + i); LCG(s); // seeding
            
            for (int m = 0; m < 2; m++) // two segments per cell
            {
                LCG(s); float sy2 = lr(s); // generate line segment joining (sx1, sy1), (sx2, sy2)
                LCG(s); float sy1 = lr(s);
                LCG(s); float sx1 = lr(s);
                LCG(s); float sx2 = lr(s);
                
                vec2 sv = fv - vec2(i, j) - vec2(sx1, sy1);
                vec2 sp = vec2(sx2 - sx1, sy2 - sy1);
                vec2 tp = sp * clamp(dot(sp, sv)/dot(sp, sp), 0.0, 1.0) - sv; // point-segment distance
                float c = dot(tp, tp);
                
                float m1 = min(c, dl.x), m2 = max(c, dl.x); // ranked distances
                dl = vec2(min(m1, dl.y), max(m1, min(m2, dl.y)));
            }
        }
        
      return sqrt(dl);
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
    
        // transition between normal and segment noise

        vec2 w = mix(worley(uv + time), worleyseg(uv + time), smoothstep(-0.5, 0.5, cos(0.2 * time)));

        // split image adapted from Inigo Quilez; https://www.shadertoy.com/view/ll2GD3

        float ry = gl_FragCoord.y / resolution.y;
        vec3                  col = hot(rescale(w.x, vec2(0.0, 1.0)));
        if ( ry > (1.0/3.0) ) col = hot(rescale(0.5 * (w.y + w.x)/length(w) - w.x, vec2(0.0, 1.0)));
        if ( ry > (2.0/3.0) ) col = hot(rescale((2.0 * w.y * w.x)/(w.y + w.x) - w.x, vec2(0.0, 0.2)));

        // borders
        col *= smoothstep( 0.5, 0.48, abs(fract(3.0 * ry) - 0.5) );

        glFragColor = vec4( vec3(col), 1.0 );
}
