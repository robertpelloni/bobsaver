#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7dlSz2

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TUNNEL

const int img[64] = int[](
        4,0,0,0,0,0,0,4,
        4,4,0,0,0,0,4,4,
        4,4,4,0,0,4,4,4,
        4,1,4,4,4,4,2,4,
        4,4,4,3,3,4,4,4,
        4,4,4,4,4,4,3,4,
        4,4,3,3,3,3,4,4,
        0,4,4,4,4,4,4,0
    );

// random hash by IQ: https://www.shadertoy.com/view/llGSzw
float hash1(uint n)
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

void main(void)
{
    // Normalize pixel coordinates (y = -0.5..0.5, x = -xres/yres/2..xres/yres/2)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ar = resolution.x/resolution.y;
    uv -= 0.5;
    uv.x *= ar;
    
    // Rotate and zoom (uvr) for image
    float a = sin(time*2.5)/1.25, sa = sin(a), ca = cos(a);
    vec2 uvr = (uv + vec2(sin(time*3.5)/8.*ar, cos(time*2.5)/8.)) * mat2(ca, -sa, sa, ca) * (sin(time*4.)/6.+1.);
    
    // Transform background
#ifdef TUNNEL
    float l = length(uv) * (sin(time*2.)+3.);
    a = atan(uv.y, uv.x) + pow(sin(uv.x*5. + time*1.5)*.5, 2.) - time*.5;
#else
    uv += vec2(sin(uv.y*(abs(mod(time*0.5,2.)-1.)*30.+5.))/30., sin(uv.x*(abs(mod(time*0.3,2.)-1.)*30.+5.))/30.);
#endif

    // Convert coords to integer for background
    float cnt = 30.;
    ivec2 iuv = ivec2(floor(uv.x*cnt), floor(-uv.y*cnt));
    
    // Convert coords to integer for image
    ivec2 ii = ivec2(floor(uvr.x*cnt), floor(-uvr.y*cnt)) + 4;
    
    // Draw
    vec3 col;
    int n = img[ii.x + ii.y*8];
    if (all(greaterThanEqual(ii, ivec2(0, 0))) && all(lessThan(ii, ivec2(8, 8))) && n != 0) {
      if (n == 4) {  // image
        col = vec3(sin((time+uv.y*5.)*5.)/4.+.74, 0., 0.);
      } else {
        float i = sin(time*6.)/2. + 0.5;
        i = i * float(int(n)&1) + (1.-i) * float((int(n)&2)>>1);
        col = vec3(i, i, 0.);
      }
    } else {
#ifdef TUNNEL
      float i = (((int(sqrt(sqrt(l))*cnt*1.5)^int(floor(a*cnt/3.1416))) & 1) == 0 ? 0.7 : 0.3);
#else
      float i = (((iuv.x^iuv.y) & 1) == 0 ? 0.7 : 0.3);
#endif
      i *= (1. + sin(time*4.)/4.);
      i += hash1(uint(gl_FragCoord.xy.x) + uint(gl_FragCoord.xy.y)*1920U + uint(frames)*1920U*1080U)*.5 - .25;
#ifdef TUNNEL
      i *= (l-0.25)/2.;
#endif
      col = vec3(i*.2, i*.5, i);  // chessboard
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
