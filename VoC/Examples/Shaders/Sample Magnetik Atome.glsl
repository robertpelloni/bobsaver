#version 420

// original https://www.shadertoy.com/view/ttlGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){float s=sin(a);float c=cos(a);return mat2(c,s,-s,c);}
vec3 hash(float p)
{
    vec3 pp = vec3(fract(cos(p*87.)),p*25., p*93.25);
    return fract((sin(dot(pp.yx, pp.xz*34.)*583.+pp*456.)*.5+.5)*562.);
}
float fbm(vec2 p)
{
    /*
    float n = texture(iChannel1, p/resolution.xy).r * .5; p *= 2.;
    n += texture(iChannel1, p/resolution.xy).r * .25; p *= 2.;
    n += texture(iChannel1, p/resolution.xy).r * .125; p *= 2.;
    n += texture(iChannel1, p/resolution.xy).r * .0625; p *= 2.;
    return n/.9735;
    */
    return 0.0;
}
float fft(float p)
{ return 0.0;//texelFetch(iChannel0, ivec2(floor(p*512.), 0.), 0).r;
}
float box(vec3 p, vec3 b)
{
    vec3 d = abs(p)-b;
    return max(d.x,max(d.y,d.z));//+length(max(vec3(0.),d));
}
float portal(vec3 p, float a)
{
    p = abs(p);
    p.x -= 2.5;
    p.xy *= rot(a);
    return box(p, vec3(.25,4.,.25));
}
float at = 0.;
float mat = 0.;
float map(vec3 p)
{
    vec3 sp = p;
    float pl = p.y + 0.5;
     float s = 7.;
    float r = length(p)*.07;
    float rr = pow(r, 2.5);
    for(int i=0; i<3; i++)
    {
        p.xz *= rot(float(i)*.7);
        p.yz *= rot(float(i)*.3*time*.3);
        p = abs(p);
        p -= s*rr;
        s *= .65;
    }
    float b = portal(p, .8*rr)/(r*1.6);
    float c = length(p)-.4/r;
    at += .25/(.4+c);
    mat = c<b? 1. : 0.;
    return min(c, b);
}
void main(void)
{
    vec3 col; vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    float time = time*.3;
    vec3 p = vec3(0.,0.,-60.);    vec3 t;
    p.xz = vec2(sin(time), cos(time))*60.;
    vec3 cz = normalize(t-p); vec3 up = normalize(vec3(0.,1.,0.));
    vec3 cx = normalize(cross(cz, up));
    vec3 cy = normalize(cross(cz, cx));
    vec3 rd = normalize(uv.x*cx + uv.y*cy + cz);

    float td; int i;
    for(; i<100; i++)
    {
        float d = map(p);
        if(d<.001) break;
        if(td>100.){td=100.;break;}
        td += d; p += d*rd;
    }
    float atmos = at; float curmat = mat;
    float fog = (100.-td)/100.;
    vec3 ld = normalize(vec3(.5,1.,-.5));
    vec2 o = vec2(.001,0.); vec3 n = normalize(map(p)-vec3(map(p-o.xyy),map(p-o.yxy),map(p-o.yyx)));
    vec3 h = normalize(ld-rd);
    float lum = dot(n,ld)*.5+.5;
    float spec = pow(max(0., dot(n,h)), 5.);
    float f = pow(max(0.,dot(-n,rd)), 5.);
    float r = length(p);
    vec3 sky = max(0.,dot(ld, rd))*vec3(.3, .0, .6) * fbm(p.xy*.1);
    vec3 glow = pow(atmos*.25, 1.2)*vec3(.2,.0,.7)/*(r*.08)*/ * fft(r*.05) *2.;
    vec3 diff = mix(vec3(.9, .0, .2) + vec3(2.8, .0, 1.)*f, vec3(.0, .8, .4)*spec, curmat);
    col += lum*fog*diff;
    col += glow*.5;
    col += sky;
    //col = vec3(fbm(p.xz));
    
    glFragColor = vec4(col,1.0);
}
