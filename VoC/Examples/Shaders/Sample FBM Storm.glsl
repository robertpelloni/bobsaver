#version 420

// original https://www.shadertoy.com/view/wd3BRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LACUNARITY 1.98
#define GAIN 0.45
#define OCTAVES 8

float hash21(vec2 p) {
    float rnd = sin(dot(p,vec2(213., 653.)));

    return fract(rnd * 1234.);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    f = f*f*(3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1., 0.));
    float c = hash21(i + vec2(0., 1.));
    float d = hash21(i + vec2(1., 1.));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
    float value = 0.;
    float amp = 1.;
    float freq = 4.;
    float divisor = 0.;
    
    for(int i = 0; i < OCTAVES; i++) {
     value += noise(uv * freq) * amp;
     divisor += amp;  
     freq *= LACUNARITY;
     amp *= GAIN;
    }
    
    return value / divisor;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = vec3(0.0);
    
    uv -= 0.5;
    
    uv.x *= resolution.x / resolution.y;
    
    float d = 0.1/length(uv);
    col += smoothstep(0.1, 1., pow(d, 2.)) * 0.25;
    
    col += sin(
        fbm(uv + fbm(uv + fbm(uv)*0.02) * 0.08 + time * 0.1) - 0.01/(cos(time)*0.5 + 0.5)
    );

    
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
