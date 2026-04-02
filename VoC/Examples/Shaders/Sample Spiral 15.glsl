#version 420

// original https://www.shadertoy.com/view/XtsBDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float de(vec3 p) {
    p.y += cos(time*2.) * .2;

    p.xy *= r2d(time + p.z);

    vec3 r;
    float d = 0., s = 1.6;

    for (int i = 0; i < 3; i++)
        r = max(r = abs(mod(p*s + 1., 2.) - 1.), r.yzx),
        d = max(d, (.8 - min(r.x, min(r.y, r.z))) / s),
        s = sqrt(s) + 7.;

    return d;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro = vec3(.1*cos(time), 0, -time), p;
    vec3 rd = normalize(vec3(uv, -1));
    p = ro;

    float it = 0.;
    for (float i=0.; i < 1.; i += .01) {
        it = i;
        float d = de(p);
        if (d < .001) break;
        p += rd * d*.5;
    }
    it /= .9 * sqrt(abs(tan(time*1.3) + p.x*p.x + p.y*p.y));

    vec3 c = mix(vec3(1., 1., 0), vec3(.9, .2, .6), it*pow(sin(p.z), 1./10.));

    glFragColor = vec4(c, 1.0);
}
