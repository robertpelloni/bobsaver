#version 420

// original https://www.shadertoy.com/view/mtX3W7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based on https://glslsandbox.com/e#98250.0
vec3 getWaves(vec2 p)
{
    const vec3 col = vec3(0.02,.3,.55);
    const mat3 _m = mat3(-2.0,-1.0,2.0, 3.0,-2.0,1.0, 1.0,2.0,2.0);
    vec4 d = vec4(time*.122);
    d.xy = p;
    d.xyw *=_m*.5;
    float v1 = length(.5-fract(d.xyw));
    d.xyw *=_m*.4;
    float v2 = length(.5-fract(d.xyw));
    d.xyw *=_m*.3;
    float v3 = length(.5-fract(d.xyw));
    float v = pow(min(min(v1,v2),v3), 5.)*15.;
    return col+vec3(v,v,v);
}

mat3 rotX(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        1, 0, 0,
        0, c, -s,
        0, s, c
    );
}
mat3 rotY(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        c, 0, -s,
        0, 1, 0,
        s, 0, c
    );
}

float random(vec2 pos) {
    return fract(sin(dot(pos, vec2(1789.9898, 78.233))) * 43758.5453);
}

float hash( float n )
{
    return fract(sin(n)*758.5453)*2.;
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    float a = random(i + vec2(0.0, 0.0));
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p)
{
    float f = 0.0;
    f += 0.500000000000*noise( p); p = p*2.02+0.15;
    f -= 0.25000*noise( p); p = p*2.03+0.15;
    f += 0.1500*noise( p); p = p*2.01+0.15;
    f += 0.06250*noise( p); p = p*2.04+0.15;
    f -= 0.03125*noise( p); p = p*2.04+0.15;
    return f/0.9678;
}

float waves2(vec2 p)
{
    p-=fbm(vec2(p.x,p.y)*0.5)*0.7;
    
    float a =0.0;
    a-=fbm(p*3.0)*2.2-0.998;
    if (a<0.0) a=0.0;
    a=a*a;
    return a;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 3.0 - resolution.xy) / min(resolution.x, resolution.y);

    float t = 0.0, d;

    float time2 = 4.0 * time / 13.0;

    vec2 q = vec2(0.0);
    q.x = fbm(p + 0.00 * time2);
    q.y = fbm(p + vec2(1.0));
    vec2 r = vec2(0.0);
    r.x = fbm(p + 1.0 * q + vec2(5.3, 9.2) + 0.23 * time2);
    r.y = fbm(p + 1.0 * q + vec2(2.3, 2.8) + 0.4466 * time2);
    float f = fbm(p + r);
    vec3 color = mix(
        vec3(0.101961, 1.0, 0.8),
        vec3(.466667, 1.0, 0.666667),
        clamp((f * f) * 9.0, 0.0, 22.0)
    );

    color = mix(
        color,
        vec3(1, 0.6, 0.6),
        clamp(length(q), 0.0, 1.0)
    );

    color = mix(
        color,
        vec3(0., 1, 3.5),
        clamp(length(r.x), 0.0, 1.0)
    );

    color = getWaves(vec2(q+r)) * 12.0 ;
    color = (f *f * f + 0.2 * f * f + 0.5 * f) * color * waves2(q);

    glFragColor = vec4( color, 0.5);
}
