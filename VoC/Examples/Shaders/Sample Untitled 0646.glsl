#version 420

// original https://www.shadertoy.com/view/NsB3Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float deg) {
    float s = sin(deg);
    float c = cos(deg);
    return mat2(c, -s, s, c);
}

vec3 pal(vec3 off) {
    return 0.5 + 0.5*cos(off+vec3(0,2,4));
}

float nsin(float deg) {
    return sin(deg) * 0.5 + 0.5;
}

float rand(vec2 seed) {
    return fract(sin(dot(seed,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    const float scale = 20.;
    vec2 uv = gl_FragCoord.xy/resolution.x * scale;
    vec2 offset = vec2(time * 0.1);
    vec2 guv = fract(uv + offset) * 2. - 1.;
    vec2 gid = floor(uv + offset) * 2.;

    vec3 col = vec3(1.);
    
    float dScale = 0.3;
    float dSpeed = 2.;
    float diag = 1.- max(nsin((gid.x-gid.y - time*dSpeed) * dScale), nsin((gid.x+gid.y + time*dSpeed) * dScale));
    col *= smoothstep(1., .8, length(guv) + smoothstep(0., .5, diag));
    if (rand(gid) < rand(gid.yx)) {
        col *= pal(vec3(rand(gid)*100.));
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
