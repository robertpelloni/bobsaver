#version 420

// original https://www.shadertoy.com/view/7sGSzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define sat(a) clamp(a, 0., 1.)
#define PI 3.14159265

mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float _cucube(vec3 p, vec3 s, vec3 th)
{
    vec3 l = abs(p)-s;
    float cube = max(max(l.x, l.y), l.z);
    vec3 l2 = abs(l)-th;
    
    float x = max(l2.y, l2.z);
    float y = max(l2.x, l2.z);
    float z = max(l2.x, l2.y);
    float cucube = max(min(min(x, y), z), cube);
    return cucube;
}

vec2 _min(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}
vec2 map(vec3 p)
{
    vec2 acc = vec2(10000.,-1.);
    acc = _min(acc, vec2(-(abs(p.y)-1.), 0.));
    p.xy *= r2d(time*.76);
    p.xz *= r2d(time*.5);
    acc = _min(acc, vec2(_cucube(p, vec3(.5), vec3(.02)), 1.));
    return acc;
}

vec3 getCam(vec3 rd, vec2 uv)
{
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    return normalize(rd+r*uv.x+u*uv.y);
}

vec3 trace(vec3 ro, vec3 rd, int steps)
{
    vec3 p = ro;
    for (int i = 0; i < steps; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
            return vec3(res.x, distance(p,ro), res.y);
        p+= rd*res.x;
    }
    return vec3(-1.);
}

float _sqr(vec2 p, vec2 s)
{
    vec2 l = abs(p)-s;
    return max(l.x, l.y);
}

vec3 palette(float f)
{
    vec3 cols[6];
    cols[0] = vec3(1.000,0.871,0.522);
    cols[1] = vec3(1.000,0.608,0.059);
    cols[2] = vec3(1.000,0.302,0.000);
    cols[3] = vec3(0.565,0.180,0.325);
    cols[4] = vec3(0.196,0.145,0.208);
    cols[5] = vec3(0.122,0.106,0.102);
    float coef = f*5.;
    int idx = int(coef);
    return mix(cols[idx], cols[min(idx+1,5)], fract(coef));
}

vec3 rdr(vec2 uv)
{
    vec3 col = vec3(0.);
    
    float dist = 10.;
    float t = time*.25;
    vec3 ro = vec3(sin(t)*dist,-0.5,cos(t)*dist);
    vec3 ta = vec3(0.,0.,0.);
    vec3 rd = normalize(ta-ro);
    
    rd = getCam(rd, uv);
    vec3 res = trace(ro, rd, 128);
    if (res.y > 0.)
    {
        vec3 p = ro+rd*res.y;
        vec3 n = normalize(cross(dFdx(p), dFdy(p)));
        col = n*.5+.5;
        if (res.z == 0.)
        {

        vec2 uvp = p.xz;
        vec2 rep = vec2(1.,1.7);
        vec2 idx = floor(((uvp+rep*.5)/rep));
        uvp = mod(uvp+rep*.5,rep)-rep*.5;
        float an = atan(uvp.y,uvp.x);
        float astp = PI*2./6.;
        float sector = mod(an+astp*.5,astp)-astp*.5;
        //uvp -= vec2(0.,0.5);
        uvp = vec2(sin(sector), cos(sector))*length(uvp);
        uvp -= vec2(0.,.5);
        col = mix(col, col*.5, 1.-sat((uvp.y)*400.));
        
        vec2 uvp2 = p.xz+rep*.5;
        vec2 idx2 = floor(((uvp2+rep*.5)/rep));
        uvp2 = mod(uvp2+rep*.5,rep)-rep*.5;
        float an2 = atan(uvp2.y,uvp2.x);
        float sector2 = mod(an2+astp*.5,astp)-astp*.5;
        //uvp -= vec2(0.,0.5);
        uvp2 = vec2(sin(sector2), cos(sector2))*length(uvp2);
        uvp2 -= vec2(0.,.5);
        col = mix(col, col*.5, 1.-sat((uvp2.y)*400.));
        col = palette(sin(sign(uv.y)*idx.x+time)*.5+.5);
        idx *= r2d(time*.15*sign(p.y));
        idx2*= r2d(-time*.25*sign(p.y));
        float shape = _sqr(idx,vec2(.5));
        float shape2 = _sqr(idx2-vec2(.5),vec2(.5));
        col = vec3(0.);
        col = mix(col, palette(sat(shape*.12)), 1.-sat((uvp.y)*400.));
        col = mix(col, palette(sat(shape2*.12)), 1.-sat((uvp2.y)*400.));
          }
                else
                {
                    col = vec3(1.);
                }
    }
    else
        col = mix(vec3(0.1), vec3(0.875,0.490,0.949), 1.-sat(abs(rd.y)*15.))*.125;
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.xx;
    uv *= r2d(PI*.125*sin(time*.25));
    vec3 col = rdr(uv);
    
    vec2 off = (vec2(1., -1.)/(resolution.x*2.));
    if (true) // Not so cheap antialiasing
    {
        //col = vec3(1.,0.,0.);
        vec3 acc = col;
        acc += rdr(uv+off.xx);
        acc += rdr(uv+off.xy);
        acc += rdr(uv+off.yy);
        acc += rdr(uv+off.yx);
        col = acc/5.;
        
    }

    glFragColor = vec4(col,1.0);
}
