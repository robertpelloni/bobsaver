#version 420

// original https://www.shadertoy.com/view/tsXBDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define octaves 32

// Random Number Generator
float rand(float n){return fract(sin(n) * 43758.5453123);}

// Noise Generator
float noise(float p){
    float fl = floor(p);
  float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

// FBM Noise Generator
float fbm(float x) {
    float v = 0.0;
    float a = 0.5;
    float shift = float(100);
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// Draw Main Image
void main(void)
{
    // Normalized Pixel Coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // FBM Noise Translated to Colors
    vec3 col = vec3(uv.xyy * (fbm(time + ((((uv.x * 8.0) * time)) / time) * fbm(time + ((((uv.y * 8.0) * time)) / time)))));

    // Output to Screen
    glFragColor = vec4(col,1.0);
}
