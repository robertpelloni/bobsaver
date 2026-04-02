#version 420

// original https://www.shadertoy.com/view/7lKXWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sat(a) clamp(a, 0.,1.)
mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
float _sqr(vec2 uv, vec2 s)
{
    vec2 l = abs(uv)-s;
    return max(l.x, l.y);
}

vec3 rdr(vec2 uv, float t)
{
    vec3 col = vec3(0.);
    float acc = 1000.;
    const int cnt = 9;
    for (int x = 0; x < cnt; ++x)
    {
        for (int y = 0; y < cnt; ++y)
        {
            vec2 cpos = (vec2(x, y)/float(cnt-1)-vec2(.5))*2.;
            vec2 pos = .05*cpos*pow(mod(t*2.,5.),5.);

            float shape = _sqr((uv-pos), vec2(.05)*abs(sin(t*2.)));
            acc = min(acc, shape);
        }
    }
    col = mix(col, vec3(1.), 1.-sat(acc*resolution.x*.5));
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.xx;

    float off = sin(time)*.1;

    vec3 col = vec3(0.);
    col.x = rdr(uv,time).x;
    col.y = rdr(uv,time+off).y;
    col.z = rdr(uv,time+off*2.).z;
    glFragColor = vec4(col,1.0);
}
