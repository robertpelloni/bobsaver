#version 420

// original https://www.shadertoy.com/view/XlKcD1

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

float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = 0.5;
    //
    // Loop of octaves
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    uv *= 4.0;
    //uv.x += time;
    
    float fbm1 = fbm(uv);
    vec2 q = vec2(0.0, 0.0);
    q.x = fbm(uv + 0.3*time);
    q.y = fbm(uv + 0.05*time);
    float fbm2 = fbm(uv + q);
    float fbm3 = fbm(vec2(fbm1, fbm2));
    
    vec3 c = vec3(0.0);
    c += fbm3;
    
    // Output to screen
    glFragColor = vec4(c, 1.0);
}
