#version 420

// original https://www.shadertoy.com/view/MdccR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// cylinder cross
float sc2(vec3 p, float r) {
    float s1 = length(p.xz);
    float s2 = length(p.xy);
    float s3 = length(p.zy);
    return min(s1, min(s2, s3)) - r;
}

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float de(vec3 p) {
    float d = 0., s = 1.;

    p.xy *= r2d(cos(time));

    p.y -= .2;
    p.x -= .4;

    p.x = abs(p.x) - .6;

    if (mod(p.z, 2.) > 1.)
        p.xy *= r2d(cos(time + p.x)*.5);
    else
        p.xy *= r2d(-time + p.z);

    vec3 q = p;

    for (int i = 0; i < 5; i++) {
        q = mod(p*s + 1., 4.) - 1.;
        d = max(d, -sc2(q, .8) / s);
        s += 6.;
    }

    return d;
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;

    float dt = time * 2.;
    float a = cos(dt)*.3;
    float b = sin(dt)*.2;
    vec3 ro = vec3(a, b, -time*8.), p;
    vec3 rd = normalize(vec3(uv, -1));
    p = ro;

    float i = 0.;
    float d;
    for (float it=0.; it < 1.; it += .04) {
        i = it;
        d = de(p);
        if (d < .001) break;
        p += rd*d;
    }
    i /= .1 * tan(3.*p.x + p.y*p.y);

    vec3 c = mix(vec3(.4, .5, .6), vec3(.0, .2, .3), i*tan(p.z + p.y + cos(p.x + time*1.)));

    glFragColor = vec4(c, 1.0);
}
