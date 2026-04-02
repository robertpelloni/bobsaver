#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D buf;

out vec4 glFragColor;

const int sweeps = 64;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 ps = 1./resolution;
    vec2 uva = uv+ps*.5;
    vec2 f = fract(uva*resolution);
    vec2 texel = uv-f*ps;
#define bcfilt(a) (a<2.?a<1.?((3.*a-6.)*a*a+4.)/6.:(((6.-a)*a-12.)*a+8.)/6.:0.) 
    vec4 fxs = vec4(bcfilt(abs(1.+f.x)), bcfilt(abs(f.x)),
            bcfilt(abs(1.-f.x)), bcfilt(abs(2.-f.x)));
    vec4 fys = vec4(bcfilt(abs(1.+f.y)), bcfilt(abs(f.y)),
            bcfilt(abs(1.-f.y)), bcfilt(abs(2.-f.y)));
#undef bcfilt
    vec4 result = vec4(0);
    for (int r = -1; r <= 2; ++r)
    {
        vec4 tmp = vec4(0);
        for (int t = -1; t <= 2; ++t)
            tmp += texture2D(tex, texel+vec2(t,r)*ps) * fxs[t+1];
        result += tmp * fys[r+1];
    }
    return result;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution-0.5) * vec2(1.0, resolution.x/resolution.y) * 10.0;
    float t = (1024.0 + time) * 0.1;
    vec2 a = vec2(0.0);
    vec2 b = a;
    float c = 1.0;
    for (int i = 16; i <= sweeps + 16; i++)
    {
        a = vec2(sin(t * 0.01 * fract(cos(float(i)) * 236.1342)), cos(t * 0.021 * float(i)));
        b = vec2(sin(t * 0.03 * fract(sin(float(i)) * 397.6348)), cos(t * 0.012 * float(i)));
        c = abs(c - smoothstep(0.0, 1.0, dot(uv - 0.5 * (a + b), a - b)));
    }

    vec3 d = texture2D_bicubic(buf, (gl_FragCoord.xy / resolution-0.5)*(0.9+0.09*mouse.x)+0.5).xyz;

    glFragColor = vec4(hsv2rgb(vec3(time*0.02+0.3*c, 0.75, c)) + d*(0.7+0.2*mouse.y), 1.0);
}
