#version 420

// original https://www.shadertoy.com/view/ss3GRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: truchet district

float t;
#define T 6.283185307

vec3 SpectrumPoly(in float x) {
    // https://www.shadertoy.com/view/wlSBzD
    return (vec3( 1.220023e0,-1.933277e0, 1.623776e0)+(vec3(-2.965000e1, 6.806567e1,-3.606269e1)+(vec3( 5.451365e2,-7.921759e2, 6.966892e2)+(vec3(-4.121053e3, 4.432167e3,-4.463157e3)+(vec3( 1.501655e4,-1.264621e4, 1.375260e4)+(vec3(-2.904744e4, 1.969591e4,-2.330431e4)+(vec3( 3.068214e4,-1.698411e4, 2.229810e4)+(vec3(-1.675434e4, 7.594470e3,-1.131826e4)+ vec3( 3.707437e3,-1.366175e3, 2.372779e3)*x)*x)*x)*x)*x)*x)*x)*x)*x;
}
vec3 hsv2rgb(in vec3 c) { vec3 rgb = clamp(abs(mod(c.x*6.0 + vec3(0.0,4.0,2.0),6.0) - 3.0) - 1.0,0.0,1.0); return c.z*mix(vec3(1.0),rgb,c.y); }
float rand(in vec2 st) { return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.585); }
mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
vec4 mod289(vec4 g){return g-floor(g*(1./289.))*289.;}vec4 permute(vec4 g){return mod289((g*34.+1.)*g);}vec4 taylorInvSqrt(vec4 g){return 1.79284-.853735*g;}vec2 fade(vec2 g){return g*g*g*(g*(g*6.-15.)+10.);}float cnoise(vec2 g){vec4 v=floor(g.rgrg)+vec4(0.,0.,1.,1.),d=fract(g.rgrg)-vec4(0.,0.,1.,1.);v=mod289(v);vec4 r=v.rbrb,a=v.ggaa,p=d.rbrb,e=d.ggaa,c=permute(permute(r)+a),f=fract(c*(1./41.))*2.-1.,t=abs(f)-.5,b=floor(f+.5);f=f-b;vec2 m=vec2(f.r,t.r),o=vec2(f.g,t.g),l=vec2(f.b,t.b),u=vec2(f.a,t.a);vec4 n=taylorInvSqrt(vec4(dot(m,m),dot(l,l),dot(o,o),dot(u,u)));m*=n.r;l*=n.g;o*=n.b;u*=n.a;float i=dot(m,vec2(p.r,e.r)),x=dot(o,vec2(p.g,e.g)),s=dot(l,vec2(p.b,e.b)),S=dot(u,vec2(p.a,e.a));vec2 I=fade(d.rg),y=mix(vec2(i,s),vec2(x,S),I.r);float q=mix(y.r,y.g,I.g);return 2.3*q;}

float id_c_F;
vec4 truchetMap(in vec2 st, in float div, in float div_a, in float div_b) {
    vec2 P = floor(st*div);
    vec2 p = fract(st*div) - .5;
    
    float mov = t*.25;
    
    if(floor(rand(P* + vec2(.123,.74))*10.) > 6.) {
        float dir = sign(p.x*p.y);
        p = abs(p);
        vec2 v = vec2(min(p.x, p.y),max(p.x, p.y));
        mov *= step(0.,-(length(v.x) - .04))*dir*.5;
        id_c_F = floor((v.y - .1 + mov)/(2./div_b))/8.;
        return vec4(v, vec2(mod(v.y - .1 + mov, 2./div_b) - 1./div_b,v.x - .1));
    }
    
    p = mix(p, vec2(p.x,-p.y), floor(rand(P)*2.));
    
    float or = sign(float(p.x > -p.y) - .5);
    p -= .5*or;
    
    float k = length(p) - .5; mov *= step(0.,-(abs(k) - .05))*sign(k)*or;
    
    vec2 pp = p*rot(mov);
    div_a *= 2.;
    float a = floor(((atan(pp.x, pp.y))/T + .5)*div_a);
    id_c_F = a/8.;
    a = (a/div_a)*T;
    pp *= rot(-a - T/(div_a*2.));
    pp.y = abs(pp.y + .5) - .1;
    
    p = vec2(abs(length(p) - .5), atan(p.x,p.y)/2.);
    
    return vec4(p, pp);
}

float cyl(in vec3 p, in float r, in float h) { return max(length(p.xy) - r, abs(p.z) - h); }
float box(in vec3 p, in vec3 s) { p = abs(p) - s; return max(p.x,max(p.y,p.z)); }
float box(in vec3 p, in float s) { p = abs(p) - s; return max(p.x,max(p.y,p.z)); }
float box(in vec2 p, in vec2 s) { p = abs(p) - s; return max(p.x,p.y); }
float invbox(in vec2 p, in vec2 s) { p = abs(p) - s; return min(p.x,p.y); }

int id_h;
float house(in vec3 p, in float s) {
    p /= s;
    p.xy = vec2(abs(p.x), p.y - .375);
    float roof = dot(vec2(p.x, p.y - .5),normalize(vec2(1.,1.5)));
    float windows = -max(max(box(mod(p.yz + vec2(.3,.225), .45) - .225,vec2(.12,.1)), p.y - .2),-p.x + .47);
    float d = max(min(max(box(p, vec3(.5,.75,.7)), roof), box(p - vec3(0.,.5,.5), .1)),windows);
    id_h = d == roof ? 1 : d == windows ? 2 : 0;
    return d*s;
}
int id_c;
float car(in vec3 p, in float s) {
    p /= s;
    p.y -= .6;
    float wheels = cyl(vec3(abs(p.x) - .7,p.y + .5, abs(p.z) - .42), .2,.1);
    float d = max(box(p, vec3(1.,.5,.5)), -box(vec3(abs(p.x - .1),p.yz) - vec3(1.1,.49,0.), vec3(.5,.5,1.)));
    d = min(max(d, -max(invbox(p.xz, vec2(.4,.4)), abs(p.y - .24) - .2)), wheels);
    id_c = d == wheels ? 1 : 0;
    return d*s;
}
int id_p;
float plane(in vec3 p, in float s) {
    p /= s;
    float k = smoothstep(-.6,1.,p.z);
    p.y -= k*.1;
    float d = min(cyl(p, .15 - k*.05,1.), box(vec3(p.x, abs(p.y - .06) - .2, p.z + .5), vec3(1.1,.025,.2)));
    float k2 = cos(p.z*4. - t*30.);
    float r = box(p - vec3(k2*.2,k2*.02,3.5), vec3(.01, .3, 2.))/2.;
    d = min(d, r);
    d = min(min(d, box(p - vec3(0.,.2,.9),vec3(.025,.25,.125))), box(p.yzx - vec3(0.,.9,0.),vec3(.025,.125,.5)));
    float wheel = cyl(vec3(abs(p.x), p.yz).zyx + vec3(.5,.4,-.2), .1,.01);
    d = min(d, wheel);
    d = min(d, box(p + vec3(0.,.25,.5), vec3(.05,.15,.05)));
    p.xz = abs(p.xz + vec2(0.,.5)) - vec2(1.05,.15);
    p.y -= .04;
    d = min(d, box(p, vec3(.01,.2,.01)));
    id_p = d == r ? 1 : d == wheel ? 2 : 0;
    return d*s;
}

int id;
vec2 tp_xy;
float df(in vec3 p) {
    
    float sz = .55;
    
    vec3 pl_pos = p;
    pl_pos.xz *= rot(t);
    
    p.x += t*.5;
    
    p.y += cnoise(p.xz*sz)/sz*.2;
    vec4 tp = truchetMap(p.xz*rot(T/6.), sz, 8., 10.);
    tp_xy = tp.xy;
    vec3 pp_b = vec3(tp.z, p.y*sz, tp.w);
    
    float h = house(pp_b.zyx, .05)/sz*.4;
    float c = car(pp_b + vec3(0.,0.,0.08), .01)/sz;
    float pl = plane(pl_pos + vec3(.75,-.4,0.), .05);
    float f = p.y;
    
    float d = min(min(min(h,f),c),pl);
    
    id = d == f ? 1 : d == h ? 2 : d == c ? 3 : 4;
    
    return d;
}

#define LIM .0005
vec3 normal(in vec3 p) { float d = df(p); vec2 u = vec2(0.,LIM); return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d); }

#define MAX_D 5.
#define MIN_D 0.
#define MAX_IT 180
struct rmr { vec3 p; int i; float d; };
rmr rm(in vec3 c, in vec3 r) {
    rmr res;
    res.p = c + r*MIN_D, res.i = MAX_IT;
    for(int i = 0; i < MAX_IT; i++) {
        res.d = df(res.p);
        if(res.d < LIM || distance(c,res.p) > MAX_D) { res.i = i; return res; }
        res.p += res.d*r;
    }
    return res;
}

vec3 plane2sphere(in vec2 p) {
    float t = -4./(dot(p,p) + 4.);
    return vec3(-p*t, 1. + 2.*t);
}

float anim1(float x, float sm){
  float xmd = mod(x,2.) - .5;
  return smoothstep(-sm,sm,xmd) - smoothstep(-sm,sm,xmd - 1.);
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    t = time + 35.;
    
    vec3 c = vec3(0.,.4,0.);
    float k = anim1(t/16. + floor(st.x*20.)/100., .02);
    vec3 r = normalize(plane2sphere(st*4.*(1. + .75*k)));
    r.xz *= rot(T/4.); r.xy *= rot(T/4.*(k*2. - 1.));

    rmr res = rm(c,r);
    
    vec3 color = SpectrumPoly(clamp((-r.y+1.6)*.2,0.1,.32))*1.75;
    if(res.d < LIM) {
        vec3 n = normal(res.p);
        vec3 color_m;
        
        if(id == 1) {
            float d0 = step(tp_xy.x,0.05);
            float d1 = step(tp_xy.x,0.04);
            float d2 = step(max(tp_xy.x, mod(tp_xy.y,.02) - .01),0.0025);
            color_m = mix(vec3(0.357,1.000,0.200),mix(vec3(.4),mix(vec3(.2),vec3(1.),d2),d1), d0);
        } else if(id == 2)
            color_m = id_h == 0 ? vec3(1.) : id_h == 1 ? vec3(0.900,0.124,0.099) : vec3(0.307,0.480,1.000);
        else if(id == 3)
            color_m = id_c == 0 ? hsv2rgb(vec3(rand(vec2(.12,id_c_F)),.8,1.)) : vec3(.1);
        else
            color_m = id_p == 1 ? vec3(.8) : id_p == 2 ? vec3(.1) : vec3(1.000,0.826,0.115);
        
        float k = distance(c, res.p);
        color = mix(color_m, color, clamp(k*k*.05,0.,1.));
        k = 1. - dot(n, -r);
        color += vec3(k*k*k*.52);
    }
    
    k = length(st);

    glFragColor = vec4(color - k*k,1.0);
}
