#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D buf;

out vec4 glFragColor;

const int sweeps = 64;

const int blurs = 2;
const float radius = float(blurs);
float brightness = .075 / radius;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * normalize(mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y));
}

void main(void)
{
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 uv = surfacePos * 2.5;
    float t = (1024.0 + time) * 0.1;
    vec2 a = vec2(0.0);
    vec2 b = a;
    float c = 1.0;
    float p = 0.0;
    float ap = 0.0;
    float bp = 0.0;
    for (int i = 16; i <= sweeps + 16; i++)
    {
        a = vec2(sin(t * fract(cos(float(i)) * 234.1342)), cos(t * 0.02 * float(i)));
        b = vec2(sin(t * fract(sin(float(i)) * 397.6848)), cos(t * 0.01 * float(i)));
        c = abs(c - smoothstep(0.0, 1.0, dot(uv - 0.5 * (a + b), a - b)));
        // visualize gradient control points and fade length/direction
        ap += 0.005/distance(uv,a);
        bp += 0.005/distance(uv,b);
        vec2 ua = uv-a, ba = b-a;
        float k = clamp(dot(ua,ba)/dot(ba,ba),0.0,1.0);
        p += 0.002/length(ua-ba*k);
    }

    glFragColor = vec4(2.5 * hsv2rgb(vec3(time * 0.02, 0.75, pow(c, 3.0))) + mouse.x*pow(vec3(ap,0.0,bp)+p,vec3(2.0)), 1.0);
}
