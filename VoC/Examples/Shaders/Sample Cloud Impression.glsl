#version 420

// original https://www.shadertoy.com/view/WltSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (C) Kristian Sivonen 2020

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(1.21, 1.0092)) * (p.x * .87 - p.y + 31.43)) * 2.331);
}

const vec2 o = vec2(1.,0.);

float noise(vec2 p)
{
    vec2 pi = floor(p);
    vec2 pf = smoothstep(0., 1., p - pi);
    return mix(
        mix(hash(pi),        hash(pi+o), pf.x), 
        mix(hash(pi+o.yx), hash(pi+o.xx), pf.x), 
        pf.y);
}

float fbm(vec2 p)
{
    return (noise(p) * 8. + noise(p * 2.) * 4. + noise(p * 4.) * 2. + noise(p * 8.) * .5) / 7.25 - 1.;
}

vec2 fbm2(vec2 p)
{
    return vec2(fbm(p), fbm(p + 10.));
}

float h(vec2 p, float t)
{
    float t0 = t * .01;
    float t1 = t * -.025;
    float t2 = t * .035;
    return fbm(t0 + p - fbm2(t1 + p + fbm2(t2 + p))) * .5 + .5;
}

vec3 h3d(vec2 p, float t)
{
    return vec3(p.x * .25, p.y * .25, smoothstep(0., 1., h(p, t)));
}

const vec3 lightDir = vec3(.44022545316, -.88045090632, -.176090181264);
const vec3 light = vec3(.5, .45, .4);
const vec3 shade = vec3(.6, .65, 1.);

vec4 clouds(vec2 uv, float t, float a)
{
    vec3 p = h3d(uv, t);
    float alpha = smoothstep(.4 + a, .8 + a, p.z);
    vec2 eps = vec2(.01 + p.z * .2, 0.);
    vec3 n = normalize(cross(h3d(uv + eps.yx, t) - p, h3d(uv + eps, t) - p));
    float l = dot(n, lightDir);
    return vec4(mix(.5 * shade, .5 + light, 
              smoothstep(0., 1., l * .5 + .5)),alpha);
}

void main(void)
{

    vec2 uv = gl_FragCoord.xy/resolution.y * 3.;
    
    float t = time;
    vec4 col = vec4(0.);
    vec3 fog = vec3(.05, .2, .4);
    for (float i = .0; i < 1. && col.w < 1.; i += .066)
    {
        float i1 = i + 1.;
        uv += 10.;
        vec4 c = clouds(uv * (1. + i * 5.) + time * .05 * (2. - i1), t, (1. - sin(i * 3.14)) * .2);
        c.xyz = mix(c.xyz, fog, i * (2. - i));
        col.xyz = mix(c.xyz, col.xyz, col.w);
        col.w += c.w;
    }
    col.w = clamp(col.w, 0., 1.);
    col.xyz = mix(fog * .7, col.xyz, col.w);
    col.w = 1.;
    glFragColor = col;
}
