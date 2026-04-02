#version 420

// original https://www.shadertoy.com/view/XcjcDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb(vec3 c) { // https://gist.github.com/983/e170a24ae8eba2cd174f
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec2 res = resolution.xy;
    vec2 c = (2.0 * gl_FragCoord.xy - res) / res.y;
    vec2 nc = normalize(c);
    float r = length(c);
    float t = 0.7 * time;
    
    vec4 fColor = vec4(0.0);
    const float ray_count = 17.0;
    const float PI = 3.14159265359;
    for (float i=0.0; i<ray_count; i++) {
        float angle = sign(mod(i, 2.0) - 0.5) * ((1.0 + 0.2*i) * sin((1.0 + 0.1*i)*(1.0 * r - 0.25*t + i)) + (1.529153*i + 0.1*t) * 2.0 * PI / ray_count);
        vec2 dir = vec2(cos(angle), sin(angle));
        float intensity = dot(nc, dir);
        float graded_intensity = 0.3 * smoothstep(0.85-0.1*(r*r*r + 0.5*i), 1.0, intensity);
        float hue = 0.5 * (1.0 + sin(3.42*i + 0.25*t + 0.05*r));
        fColor = (1.0-graded_intensity) * fColor +
            graded_intensity * vec4(hsv2rgb(vec3(hue, 0.5, 1.0)), 0.0);
    }
    glFragColor = fColor;
}