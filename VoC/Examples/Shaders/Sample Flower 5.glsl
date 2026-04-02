#version 420

// original https://www.shadertoy.com/view/wtdcR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415926

float s(float v0, float d, float x) {
    return smoothstep(v0, v0+d, x);
}

vec2 c2p(vec2 uv) {
    return vec2(atan(uv.x, uv.y), length(uv));
}

vec4 flower(
    vec2 uv,
    vec4 color,
    float size,
    float rpetals,
    float npetals,
    float speed
) {

    uv = c2p(uv);        
    uv.x += time * speed + uv.y;
    
    float m = (fract(uv.x / pi / 2. * npetals) - 0.5) * rpetals;
    m = min(m, -m);
    
    float c = s(size, -0.01, uv.y + m);
    
    return mix(vec4(0.), color, c);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec4 f;
    vec4 c = vec4(0.7, 0.3, 0., 1.);
    
    f = flower(uv, vec4(1., 0., 0., 1.), 0.3, 0.3, 7., 0.1);
    c = mix(c, f, f.a);
    
    f = flower(uv, vec4(0., 1., 0., .5), 0.27, 0.27, 7., 0.2);
    c = mix(c, f, f.a);
    
    f = flower(uv, vec4(0., 0., 1., .5), 0.25, 0.25, 7., 0.3);
    c = mix(c, f, f.a);
    
    f = flower(uv, vec4(1., 1., 0., .5), 0.23, 0.23, 7., 0.35);
    c = mix(c, f, f.a);
    
    f = flower(uv, vec4(0., 1., 1., .5), 0.21, 0.21, 7., 0.4);
    c = mix(c, f, f.a);
    
    f = flower(uv, vec4(1., 1., 1., .5), 0.19, 0.19, 7., 0.45);
    c = mix(c, f, f.a);
    
    
    glFragColor = c;
}
