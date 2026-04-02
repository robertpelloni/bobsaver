#version 420

// original https://www.shadertoy.com/view/3tlXWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FALLOFF_START 1.0
#define DECAY_START 0.1
#define DECAY 1.0

#define GRIDW 0.02

#define GRID_R 0.672443156957688
#define GRID_G 0.0103298230296269
#define GRID_B 0.246201326707835
#define FALLOFF_GRID 0.75

//#define GRID_R 0.0544802764424424
//#define GRID_G 0.0
//#define GRID_B 0.0761853814813079

float sRGB(float x) {
    if (x <= 0.00031308)
        return 12.92 * x;
    else
        return 1.055*pow(x,(1.0 / 2.4) ) - 0.055;
}

float saw(float t) {
     return t - floor(t);   
}

float tri(float t) {
    return 2.0 * abs(t - floor(t + 0.5));
}

float grid(vec2 pix, float t) {
    
    float d = t + (pix.y / 30.0) + sin(pix.x * 500.0);
    
    float distortion = (sin(d * 400.0) + (sin(d * 600.0) / 2.0) + (sin(d * 800.0) / 3.0)) / 4.0;
    
    //float w = max(0.0, tri((pix.x + distortion) / 8.0) - (1.0 - GRIDW)) / GRIDW;
    //float h = max(0.0, tri((pix.y + distortion) / 8.0) - (1.0 - GRIDW)) / GRIDW;
    
    float w = tri((pix.x + distortion) / 50.0);
    float h = tri((pix.y + distortion) / 50.0);
    
    
    float power = 1.0 + 0.25 * tri(pix.y / 50.0 + t / 6.0);
    
    float falloff = power * FALLOFF_GRID;
    
    float dist = min(w, h) * 25.0;
    
    
    
    //return min(power, max(w, h)
    return min(power, power * (falloff * falloff) / (dist * dist));

    
    //return w;
}

float electron_beam(vec2 pix, float t) {

    
    float beam_x = (cos(t * 1.0) * 250.0 + 1.0) / 2.0;
    float beam_y = (sin(t * 10.0 / 9.0) * 200.0 + 1.0) / 2.0;

    float dist = distance(pix, vec2(beam_x, beam_y));
    
    float power = 1.0 - (min(time - t, DECAY) / DECAY);
    
    float falloff = power * FALLOFF_START;
    
    return min(power, power * (falloff * falloff) / (dist * dist));
}

void main(void)
{
   
    
    
    vec2 center = resolution.xy / 2.0;
    
    float scale = 512.0 / resolution.x;
    
    vec2 uv = (gl_FragCoord.xy - center) * scale;
    
    
        
    float beam = 0.0;
    
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        beam += electron_beam(uv, time - t);
        t += 0.01;
    }
    
    vec2 uv_r = uv - vec2(sin(time / 5.0 + uv.y / 100.0) * 2.0, sin(uv.x / 75.0 + time / 8.0));
    vec2 uv_g = uv;
    vec2 uv_b = uv + vec2(sin(time / 4.0 + uv.y / 100.0) * 2.0, cos(uv.x / 50.0 + time / 4.0));
    
    float grid_r = grid(uv_r, time) * GRID_R;
    float grid_g = grid(uv_g, time - 0.1) * GRID_G;
    float grid_b = grid(uv_b, time + 0.1) * GRID_B;
    
    vec3 grid_col = vec3(sRGB(grid_r), sRGB(grid_g), sRGB(grid_b));
    vec3 beam_col = vec3(sRGB(beam * 0.25), sRGB(beam), sRGB(beam));
    
    glFragColor = vec4(grid_col + beam_col, 1.0);
}
