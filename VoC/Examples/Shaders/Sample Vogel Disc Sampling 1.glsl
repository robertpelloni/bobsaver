#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlsXzS

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Rotating Vogel disk with per-frame radius jittering. This sampling pattern
// provides good spatial coverage with only a few sampling points and can be
// used in combination with temporal anti-aliasing for, e.g., SSAO, shadow map
// filtering, DoF, etc. The plot shows the distribution of NUM_SAMPLES over
// NUM_FRAMES.
//
// References:
// - Spreading points on a disc and on a sphere, http://blog.marmakoide.org/?p=1
// - M. Gjoel and M. Svendsen, The rendering of INSIDE, GDC 2016, p. 43
//   https://www.gdcvault.com/play/1023002/Low-Complexity-High-Fidelity-INSIDE.
//
// Author: Johan Nysjö

#define NUM_SAMPLES 6
#define NUM_FRAMES 60
#define PI 3.14159265398

vec3 srgb2lin(vec3 color)
{
    return color * color;    
}

vec3 lin2srgb(vec3 color)
{
     return sqrt(color);   
}

float hash(float seed)
{
    return fract(sin(seed * 12.9899) * 43758.5453); 
}

vec2 vogel_disk(int i, int num_samples, float r_offset, float phi_offset)
{
    float r = sqrt((float(i) + r_offset) / float(num_samples));
    float golden_angle = 2.399963229728;
    float phi = float(i) * golden_angle + 2.0 * PI * phi_offset;
    float x = r * cos(phi);
    float y = r * sin(phi);

    return vec2(x, y);
}

float aastep(float edge, float x)
{
    float aawidth = 0.7 * fwidth(x);
    return smoothstep(edge - aawidth, edge + aawidth, x);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float aspect = resolution.x / resolution.y;
    vec2 p = (2.0 * uv - 1.0) * vec2(aspect, 1.0);

    vec3 background_color = srgb2lin(vec3(0.8, 0.8, 0.8));
    vec3 glyph_color = srgb2lin(vec3(0.7, 0.1, 0.1));
    float glyph_size = 0.03;

    // NOTE: the seed should be fetched from, e.g., a tiled blue noise texture
    // when the vogel disk is used as a filter kernel for postprocessing effects
    vec2 seed = vec2(0.0, 0.0);

    vec3 output_color = background_color;
    for (int i = 0; i < NUM_FRAMES; ++i) {
        float r_offset = hash(seed.x + float((frames + i) % 1000));
        float phi_offset = fract(seed.y + sqrt(3.0) * float((frames + i) % 1000));
        float glyph_alpha = float(i + 1) / float(NUM_FRAMES);
        for (int j = 0; j < NUM_SAMPLES; ++j) {
            vec2 q = vogel_disk(j, NUM_SAMPLES, r_offset, phi_offset);
            float dist = length(p - q);
            float alpha = glyph_alpha * (1.0 - aastep(glyph_size, dist));
            output_color = alpha * glyph_color + (1.0 - alpha) * output_color;
        }
    }
    output_color = lin2srgb(output_color);
    
    glFragColor = vec4(output_color, 1.0);
}
