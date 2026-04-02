#version 420

// original https://www.shadertoy.com/view/4t3cRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 4
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 1.5;
        amplitude *= .5;
    }
    return value;
}
// From FabriceNeyret2
#define step(a,x) smoothstep(0.,1.5/resolution.y,x-a)
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy/resolution.y;

    vec3 col = vec3(0.9);
    float t = time/4.;
    
    float p = 0.1*fbm(uv+t);
    float q = fbm(uv+5.*p+t);
    float r = fbm(uv+10.*q+t);
    
    r = r*.5-.5;
    
    uv = uv - (0.1+0.2*t)*r;
    
    col = mix(col, vec3(.7,.1,.1), step(0.6, uv.y) * (1. - step(0.4, uv.x)) );
    col = mix(col, vec3(.95,.75,0), step(0.6, uv.y) * step(1.6, uv.x) );
    col = mix(col, vec3(.2,.4,.9), (1.-step(0.2, uv.y)) * step(1.4, uv.x) );
    
    col = mix(col, vec3(.15), step(0.78, uv.y) - step(0.82, uv.y));
    col = mix(col, vec3(.15), step(0.58, uv.y) - step(0.62, uv.y));
    col = mix(col, vec3(.15), step(0.38, uv.x) - step(0.42, uv.x));
    col = mix(col, vec3(.15), (step(0.18, uv.x) - step(0.22, uv.x))*step(0.58, uv.y));
    col = mix(col, vec3(.15), step(1.58, uv.x) - step(1.62, uv.x));
    col = mix(col, vec3(.15), step(1.38, uv.x) - step(1.42, uv.x));
    col = mix(col, vec3(.15), (step(0.18, uv.y) - step(0.22, uv.y)) * step(0.38, uv.x) );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
