#version 420

// original https://www.shadertoy.com/view/fsVSDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f*f*(3.0-2.0*f);
    
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y ;
    vec3 col = mix(vec3(1.0, 0.7, 0.0), vec3(0.2, .3, 1.0), noise(uv * 2.0 + time));
    
    uv.x += sin(noise(uv * 2. + time)) -  .5;
    uv.y += cos(noise(uv * 2. + time)) - 1.;
    
    float d = smoothstep(.6, .2, length(uv)) -1. + smoothstep(.1,.4, length(uv));
    
    d *= noise(uv * 5. + time) * 4.0;
    glFragColor = vec4(d * col ,1.0);
}
