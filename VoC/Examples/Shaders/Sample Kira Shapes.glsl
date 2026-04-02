#version 420

// original https://www.shadertoy.com/view/WsVyR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb(float h, float s, float v) {
    vec3 a = fract(h + vec3(0.0, 2.0, 1.0)/3.0) * 6.0 - 3.0;
    a = clamp(abs(a) - 1.0, 0.0, 1.0) - 1.0;
    a = a*s + 1.0;
    return a*v;
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    vec2 resolution = resolution.xy;
    float time = time;
    float m = 0.5 * abs(sin(time));
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv *= 5.;

    float xp = -uv.x + time;
    float yp = uv.y + time;

    vec2 pos = vec2(floor(xp), floor(yp));

    uv = vec2(fract(xp) * 2.0 - 1.0, fract(yp) * 2.0 - 1.0);

    float theta = atan(uv.y, uv.x) - time;
    float threshold = (1.0 - 0.5) * sin(floor(rand(pos) * 15.) * theta) + 0.5;

    vec4 col = vec4(hsv2rgb(sin(time * .5 * rand(pos)), 1.0, 1.0), 1.0);
    
    if(step(length(uv), threshold) == 1.0) {
        glFragColor = col;
    } else {
        glFragColor = vec4(0.7,0.7,0.7,1.);
    }
}
