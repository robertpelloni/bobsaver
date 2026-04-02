#version 420

// original https://www.shadertoy.com/view/MtX3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct        obj
{
    int id;
    vec4 pos;
    vec3 dir;
    vec3 col;
    float ka;
    float kt;
    float kd;
    float ks;
    float kr;
    float kl;
};

vec3 cam = vec3(0.0, 0.0, 8.0);

obj olum = obj(0, vec4(0.0, 4.5, 0.0, 0.0), vec3(0.0), vec3(1.0, 1.0, 0.0), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
obj osph = obj(1, vec4(-1.0, 0.5, 0.0, 0.5), vec3(0.0), vec3(1.0, 1.0, 1.0), 0.15, 0.0, 0.5, 0.5, 0.6, 42.0);
obj osph2 = obj(2, vec4(1.0, 0.5, 0.0, 0.5), vec3(0.0), vec3(0.0, 1.0, 1.0), 0.15, 0.0, 0.5, 0.5, 0.0, 42.0);
obj opln = obj(3, vec4(0.0, -1.0, 0.0, -2.0), vec3(0.0), vec3(1.0, 0.0, 0.0), 0.15, 0.0, 0.5, 0.5, 0.2, 42.0);
obj opln2 = obj(4, vec4(-1.0, 0.0, 0.0, -5.0), vec3(0.0), vec3(0.0, 0.0, 1.0), 0.15, 0.0, 0.5, 0.5, 0.2, 1.0);
obj opln3 = obj(5, vec4(1.0, 0.0, 0.0, -5.0), vec3(0.0), vec3(0.0, 1.0, 0.0), 0.15, 0.0, 0.5, 0.5, 0.2, 1.0);
obj opln4 = obj(6, vec4(.0, 11.0, 0.0, -5.0), vec3(0.0), vec3(0.0, 1.0, 1.0), 0.3, 0.0, 0.5, 0.5, 0.0, 1.0);
obj opln5 = obj(7, vec4(.0, 0.0, -1.0, -15.0), vec3(0.0), vec3(1.0, 1.0, 1.0), 0.0, 0.0, 0.0, 0.5, 1.0, 142.0);
obj opln6 = obj(8, vec4(.0, 0.0, 1.0, -15.0), vec3(0.0), vec3(1.0, 1.0, 1.0), 0.0, 0.0, 0.0, 0.5, 1.0, 142.0);
obj ocyl = obj(9, vec4(-2.0, 0.0, -5.0, 0.3), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), 0.15, 0.0, 0.5, 0.5, 0.0, 24.0);
obj ocyl2 = obj(10, vec4(2.0, 0.0, -5.0, 0.3), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), 0.15, 0.0, 0.5, 0.5, 0.0, 24.0);
obj ocon = obj(11, vec4(0.0, 1.0, -10.0, 0.3), vec3(0.0), vec3(0.0, 0.0, 1.0), 0.15, 0.0, 0.5, 0.5, 0.1, 42.0);
obj otri = obj(12, vec4(0.0, 0.0, 0.0, 0.0), vec3(0.0), vec3(0.0, 0.0, 1.0), 0.15, 0.0, 0.5, 0.5, 0.1, 42.0);

vec3 ntri = vec3(0.0);

vec3 v;
float rand(vec2 n)
{
  return (0.5 + 0.5 * fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453));
}

obj        getObj(in int id)
{
    if (id == 1)
        return (osph);
    if (id == 2)
        return (osph2);
    if (id == 3)
        return (opln);
    if (id == 4)
        return (opln2);
    if (id == 5)
        return (opln3);
    if (id == 6)
        return (opln4);
    if (id == 7)
        return (opln5);
    if (id == 8)
        return (opln6);
    if (id == 9)
        return (ocyl);
    if (id == 10)
        return (ocyl2);
    if (id == 11)
        return (ocon);
    if (id == 12)
        return (otri);
    return (olum);
}

float    isphere(in vec3 ro, in vec3 rd, in int id)
{
    obj o = getObj(id);
    ro = ro - o.pos.xyz;
    float a = dot(rd, rd);
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - o.pos.w * o.pos.w;
    float d = b * b - 4.0 * a * c;
    if (d < 0.001)
        return (-1.0);
    a *= 2.0;
    return (min((-b - sqrt(d)) / a, (-b + sqrt(d)) / a));
}

vec3    nsphere(in vec3 pos, in int id)
{
    obj o = getObj(id);
    return ((pos - o.pos.xyz) / o.pos.w);
}

float    iplane(in vec3 ro, in vec3 rd, in int id)
{
    obj o = getObj(id);
    float d = -(dot(ro, normalize(o.pos.xyz)) + o.pos.w) / dot(rd, normalize(o.pos.xyz));

    return (d);
}

vec3    nplane(in vec3 pos, int id)
{
    obj o = getObj(id);
    return (o.pos.xyz * -1.0);
}

float    icylender(in vec3 ro, in vec3 rd, in int id)
{
    obj o = getObj(id);
    ro = ro - o.pos.xyz;
    ro *= 1.0 - o.dir;
    rd *= 1.0 - o.dir;
    float a = dot(rd, rd);
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - o.pos.w * o.pos.w;
    float d = b * b - 4.0 * a * c;
    if (d < 0.001)
        return (-1.0);
    a *= 2.0;
    return (min((-b - sqrt(d)) / a, (-b + sqrt(d)) / a));
}

vec3    ncylender(in vec3 pos, in int id)
{
    obj o = getObj(id);
    vec3 n = ((pos - o.pos.xyz) * (1.0 - o.dir)) / o.pos.w;
    return (n);
}

float    icone(in vec3 ro, in vec3 rd, in int id)
{
    obj o = getObj(id);
    ro = ro - o.pos.xyz;
    float a = dot(rd.xz, rd.xz) - o.pos.w * rd.y * rd.y;
    float b = 2.0 * (dot(ro.xz, rd.xz) - o.pos.w * ro.y * rd.y);
    float c = dot(ro.xz, ro.xz) - o.pos.w * ro.y * ro.y;
    float d = b * b - 4.0 * a * c;
    if (d < 0.001)
        return (-1.0);
    a *= 2.0;
    return (min((-b - sqrt(d)) / a, (-b + sqrt(d)) / a));
}

vec3    ncone(in vec3 pos, in int id)
{
    obj o = getObj(id);
    vec3 n = pos - o.pos.xyz;
    n.y = -n.y * tan(o.pos.w);
    return (normalize(n));
}

float    itriangle(in vec3 ro, in vec3 rd, in int id)
{
    vec3 p0 = vec3(-1.0, 1.0, 0.0);
    vec3 p1 = vec3(1.0, 1.0, 0.0);
    vec3 p2 = vec3(0.0, 0.0, 0.0);

    vec3 e1 = p1 - p0;
    vec3 e2 = p2 - p0;
    vec3 e1e2 = cross(e1, e2);
    vec3 p = cross(rd, e2);
    e1e2 = normalize(e1e2);
    float a = dot(e1, p);
    if(a < 0.001)    
        return (-1.0);

    float f =  1.0 / a;
    vec3 s = ro - p0;
    float u = f * (dot(s, p));
    if(u < 0.0 || u > 1.0)
        return (-1.0);
    
    vec3 q = cross(s, e1);
    float v = f * (dot(rd, q));
    if(v < 0.0 || u + v > 1.0)
        return (-1.0);
    float t = f * (dot(e2, q));
    ntri = e1e2;
    return (t);
}

float    getIntersect(in vec3 ro, in vec3 rd, in int id)
{
    if (id > 11)
        return (itriangle(ro, rd, id));
    if (id > 0 && id < 3)
        return (isphere(ro, rd, id));
    if (id > 2 && id < 9)
        return (iplane(ro, rd, id));
    if (id > 8 && id < 11)
        return (icylender(ro, rd, id));
    return (icone(ro, rd, id));
}

vec3    getNormale(in vec3 pos, in int id)
{
    if (id > 11)
        return (ntri);
    if (id > 0 && id < 3)
        return (nsphere(pos, id));
    if (id > 2 && id < 9)
        return (nplane(pos, id));
    if (id > 8 && id < 11)
        return (ncylender(pos, id));
    return (ncone(pos, id));
}

int        intersect(in vec3 ro, in vec3 rd, out float t)
{
    int id = -1;
    
    t = 1000.0;
    for (int i = 1; i < 13; ++i)
    {
        float ti = getIntersect(ro, rd, i);
        if (i != 0 && ti > 0.001 && ti < t)
        {
            id = i;
            t = ti;
        }
    }
    return (id);
}

vec3    processColor3(in vec2 uv, in vec3 ro, in vec3 rd, in float t, int id)
{
    obj o, l;
    vec3 amb, dif, spe, p, n, ln, lp, nlp;
    float ps1, ps2, t1, tmp, coef;

    o = getObj(id);
    l = olum;
    p = ro + t * rd;
    n = getNormale(p, id);
    lp = normalize(l.pos.xyz - p);
    nlp = normalize(p - l.pos.xyz);
    ps1 = dot(n, lp);
    ps2 = -dot(n, nlp);
    amb = o.col * (1.0 - o.kt) * o.ka;
    dif = spe = vec3(0.0);
    if (ps1 > 0.0)
    {
        tmp = o.ks * pow(ps2, o.kl);
        if ((intersect(l.pos.xyz, nlp, t1) == id))
        {
            dif = o.kd * o.col * ps1;
            if (ps2 > 0.0)
                spe = l.col * vec3(tmp);
        }
    }
    return (amb + dif + spe);
}

vec3    getPixelColor3(in vec2 uv, in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.0);
    float t = 1000.0;
    int id = intersect(ro, rd, t);
    
    if (id > 0)
        return (processColor3(uv, ro, rd, t, id));
    return (col);
}

vec3    processColor2(in vec2 uv, in vec3 ro, in vec3 rd, in float t, int id)
{
        obj o, l;
    vec3 amb, dif, spe, refl, refr, p, n, ln, lp, nlp;
    float ps1, ps2, t1, tmp, coef;

    o = getObj(id);
    l = olum;
    p = ro + t * rd;
    n = getNormale(p, id);
    lp = normalize(l.pos.xyz - p);
    nlp = normalize(p - l.pos.xyz);
    ps1 = dot(n, lp);
    ps2 = -dot(n, nlp);
    amb = o.col * (1.0 - o.kt) * o.ka;
    dif = spe = refl = refr = vec3(0.0);
    if (ps1 > 0.0)
    {
        tmp = o.ks * pow(ps2, o.kl);
        
        if ((intersect(l.pos.xyz, nlp, t1) == id))
        {
            dif = o.kd * o.col * ps1;
            if (ps2 > 0.0)
                spe = l.col * vec3(tmp);
        }
    }
    if (o.kr > 0.0)
        refl = o.kr * getPixelColor3(uv, p, reflect(rd, n));
    return (amb + dif + spe + refl + refr);
}

vec3    getPixelColor2(in vec2 uv, in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.0);
    float t = 1000.0;
    int id = intersect(ro, rd, t);
    
    if (id > 0)
        return (processColor2(uv, ro, rd, t, id));
    return (col);
}

vec3    processColor(in vec2 uv, in vec3 ro, in vec3 rd, in float t, int id)
{
    obj o, l;
    vec3 amb, dif, spe, refl, refr, p, n, ln, lp, nlp;
    float ps1, ps2, t1, tmp, coef;
    int id2;

    o = getObj(id);
    l = olum;
    p = ro + t * rd;
    n = getNormale(p, id);
    lp = normalize(l.pos.xyz - p);
    nlp = normalize(p - l.pos.xyz);
    ps1 = dot(n, lp);
    ps2 = -dot(n, nlp);
    amb = o.col * (1.0 - o.kt) * o.ka;
    dif = spe = refl = refr = vec3(0.0);
    if (ps1 > 0.0)
    {
        tmp = o.ks * pow(ps2, o.kl);
        id2 = intersect(l.pos.xyz, nlp, t1);
        if (id2 == id)
        {
            dif = o.kd * o.col * ps1;
            if (ps2 > 0.0)
                spe = l.col * vec3(tmp);
        }
    }
    if (o.kr > 0.0)
        refl = o.kr * getPixelColor2(uv, p, reflect(rd, n));
    return (amb + dif + spe + refl + refr);
}

vec3    getPixelColor(in vec2 uv, in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.0);
    float t = 1000.0;
    int id = intersect(ro, rd, t);
    
    if (id > 0)
        return (processColor(uv, ro, rd, t, id));
    return (col);
}

void main(void)
{
    float e = tan(30.0 * 3.14 / 180.0);
    float ratio = resolution.x / resolution.y;
    vec2 uv = (-1.0 + 2.0 * gl_FragCoord.xy / resolution.xy) * vec2(e, e / ratio);
    vec3 ro = cam;
    vec3 rd = normalize(vec3(uv, -1.0));
    
    olum.pos.x = cos(time) * 3.0;
    olum.pos.z = sin(time) * 3.0;
    osph.pos.x = cos(time) * 3.0;
    osph.pos.z = sin(time) * 3.0;
    osph2.pos.y += cos(time);
    glFragColor = vec4(getPixelColor(uv, ro, rd),1.0);
}
