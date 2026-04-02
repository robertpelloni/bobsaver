#version 420

// original https://www.shadertoy.com/view/mt2fW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(in vec2 p) {
    return fract(sin(dot(p,
        vec2(16.12327, 27.4725))) *
        29322.1543424);
}

float noise(in vec2 p) {

    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = random(i);
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));
    
    vec2 u = smoothstep(0., 1., f);
    
    return mix(a, b, u.x) +
        (c - a) * u.y * (1.0-u.x) +
        (d - b) * u.x * u.y;

}

#define OCTAVES 6

float fbm(in vec2 p) {

/*
    mat2 rot = mat2(
        4./5., -3./5.,
        3./5., 4./5.
    );
*/

    float t = time / 8.;
    mat2 rot = mat2(
        cos(t), -sin(t),
        sin(t), cos(t)
    );
    
    float shift = time/2.;

    float value = 0.;
    float amp = .5;
    float freq = 0.;
    
    for (int i = 0; i < OCTAVES; i++) {
    
        value += amp * noise(p * rot + shift);
        p *= 2.;
        amp *= .5;
    
    }
    
    return value;
}

float repFbm(in vec2 p, int l) {
    
    float o = 0.;
    
    for (int i = 0; i < l; i++) {
    
        o = fbm(vec2(p+o));
    
    }
    
    return o;
    
}

const vec3 col1 = vec3(0.278,1.000,1.000),
           col2 = vec3(0.424,0.431,0.855),
           col3 = vec3(0.192,0.212,0.267);

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y;

    float v = repFbm(uv, 3);

    vec3 col = mix(
        col1,
        col2,
        clamp(v/3.,0.,.5));
        
    col = mix(
        col,
        col3,
        mix(v*3.,.2,.66));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
