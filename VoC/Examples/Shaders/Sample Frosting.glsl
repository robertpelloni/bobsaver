#version 420

// original https://www.shadertoy.com/view/wllcD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

=== VARIATION OF
    https://www.shadertoy.com/view/WtsyW2 ===

Main references and functions from https://thebookofshaders.com/13/ and https://www.iquilezles.org/www/articles/warp/warp.htm

Code structure from Low Pattern(https://www.shadertoy.com/view/WlsyWj)

*/

//2D Random and Noise functions

float rand(in vec2 sd) {
    
    return fract( sin( dot( sd.xy, vec2(9.128, 3.256) * 293699.963 ) ) );
}

float n2D(in vec2 sd) {
    
    vec2 iComp = floor(sd);
                            //integer and fractional components
    vec2 fComp = fract(sd);
    
    
    float a = rand(iComp + vec2(0.0, 0.0));    //
    float b = rand(iComp + vec2(1.0, 0.0));    // interpolation points
    float c = rand(iComp + vec2(0.0, 1.0));    // (4 corners)
    float d = rand(iComp + vec2(1.0, 1.0));    //
    
    vec2 fac = smoothstep(0.0, 1.0, fComp);    //interpolation factor
    
    //Quad corners interpolation
    return
        mix(a, b, fac.x) +
        
            (c - a) * fac.y * (1.0 - fac.x) +
        
                (d - b) * fac.x * fac.y ;
}

//fractal Brownian Motion and Motion Pattern

#define OCTAVES 6

float fBM(in vec2 sd) {
    
    //init values
    float val = 0.0;
    float freq = 1.0;
    float amp = 0.5;
    
    float lacunarity = 2.0;
    float gain = 0.5;
    
    //Octaves iterations
    for(int i = 0; i < OCTAVES; i++) {
        
        val += amp * n2D(sd * freq);
        
        freq *= lacunarity;
        amp *= gain;
    }
    
    return val;
}

float mp(in vec2 p) {
    
    float qx = fBM(p + vec2(0.0, 0.0));
    float qy = fBM(p + vec2(6.8, 2.4));
    
    vec2 q = vec2(qy,qx);
    
    float tm = 0.008 * time * 1.3;    //time factor
    
    float rx = fBM(p + (1.1 * tm*1.2) * q + vec2(9.5, 9.3) * tm);
    float ry = fBM(p + (18.5 * tm/1.3) * q + vec2(7.2, 1.5) * -(tm + 0.002));
    
    vec2 r = vec2(rx, ry);
    
    return fBM(p + (2.0 * r));
}

//From https://www.shadertoy.com/view/XlKSDR
vec3 Tonemap_ACES(const vec3 t) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (t * (a * t + b)) / (t * (c * t + d) + e);
}

//========================================================================

//main()

void main(void)
{
    //Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    
    
    vec3 col = vec3(0.0);
    //col += fBM(uv*3.0);
    
    vec3 mask = vec3(0.0);//texture(iChannel0, uv).rgb;
    
    float wFac = mp(uv*3.0); //warping factor
   
    col = mix(vec3(0.101961, 0.29608, 0.26567), vec3(0.66667,0.45667,0.89839), clamp(pow(wFac, 2.5), 0.0, 1.0));
    col = mix(col, vec3(0.24467,0.00567,0.19809), clamp(pow(wFac, 0.4), 0.0, 1.0));
    col = mix(col, vec3(0.32467,0.22567,0.31809), clamp(wFac * wFac, 0.0, 1.0));
    col = mix(col, vec3(0.64467,0.32567,0.13809), clamp(smoothstep(0.0, 1.0, wFac), 0.0, 1.0));
    
    vec3 bg = mix(col, vec3(0.00467,0.32567,0.93809), clamp(smoothstep(0.0, 1.0, wFac), 0.0, 1.0));
    bg = mix(bg, vec3(0.12467,0.92567,0.61809), clamp(wFac * wFac, 0.0, 1.0)) * 1.4;
    
    
    col = mix(bg, col, mask);
    //col = Tonemap_ACES(col);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
