#version 420

// original https://www.shadertoy.com/view/fd2SRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by @etiennejcb
// Using this shader from lsdlive as raymarching template : https://www.shadertoy.com/view/4s3yDM
// Thanks lsdlive
// Thanks to Cookie collective
// Thanks to tdhooper and iq

#define PI 3.14159
#define TAU (2.*PI)

#define radius1 18.
#define radius2 19.
#define duration 3.0

// hglib / iq
// http://mercury.sexy/hg_sdf/
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float rep(float p, float d) {
    return mod(p - d*.5, d) - d*.5;
}

vec3 rep(vec3 p, float d) {
    return mod(p + d*.5, d) - d*.5;
}

void amod(inout vec2 p, float m) {
    float a = rep(atan(p.x, p.y), m);
    p = vec2(cos(a), sin(a)) * length(p);
}

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float smoo(float a, float b, float r) {
    return clamp(.5 + .5*(b - a) / r, 0., 1.);
}

float smin(float a, float b, float r) {
    float h = smoo(a, b, r);
    return mix(b, a, h) - r*h*(1. - h);
}

vec4 opu(vec4 a, vec4 b) {
    return a.w < b.w ? a : b;
}

float time2;
float glow;
float d2_saved;
float d3_saved;
//return vec4: vec3 color + float distance
vec4 map(vec3 p) {

    vec4 surface;
    vec3 q = p;
    float d = 10000.;
    
    d = min(d,length(q*vec3(1.,1.,1.))-radius1);
    d = min(d,-(length(q*vec3(1.,1.,1.))-radius2));
    float d2 = d;
    
    // walls, less visible for large angle
    float angle = 0.07;
    p.xy *= r2d(angle);
    float d3 = p.x;
    p.xy *= r2d(-2.*angle);
    d3 = min(d3,-p.x);
    float k = 0.07;
    d = smin(d3,d2,k);
    surface = vec4(vec3(0.),d);
    
    p = q;
    //p.y-=13.0;
    float m2 = TAU/150.;
    p.yz *= r2d(- 2.0*time2*m2-0.*PI/2.0);
    float indDepth = floor((atan(p.z,p.y)+0.5*m2)/m2);
    p.yz *= r2d(m2/2.0);
    amod(p.yz,m2);
    float m1 = TAU/230.;
    float rot = PI/2.0;
    float addRot = (mod(indDepth,2.0)==1.?m1/2.0:0.);
    float indHorizontal = floor((atan(p.y,p.x)+0.5*m1+addRot)/m1);
    if(indHorizontal!=floor(TAU/m1/4.)+1.||mod(indDepth,2.0)!=1.)
    {
        p.xy *= r2d(rot+addRot);
        amod(p.xy,m1);
        p.xy *= r2d(-rot);
        
        float cnt = 6.0;
        float si = sign(indHorizontal-(floor(TAU/m1/4.)+0.5));
        p.xz *= r2d(14.0*p.y*si-si*10.*time2*TAU/cnt);
        
        float m3 = TAU/cnt;
        float indTwist = floor((atan(p.z,p.x))/m3);
        amod(p.xz,m3);
        float r = 0.055;
        p.x -= r;
        d = length(p.xz)-TAU*r/cnt/2.0;
        d = smin(d2,d,0.2);
        
        float col1 = mod(indTwist,2.0);
        float lp = smoothstep(0.,0.3,d2);
        col1 = mix(0.,col1,lp);
        
        surface = opu(surface,vec4(vec3(col1),d));
    }
    
    //glow from lsdlive
    glow += .015 / (.01 + d*d);
    d2_saved = d2;
    d3_saved = d3;
    
    return surface;

}

vec3 camera(vec3 ro, vec2 uv, vec3 ta) {
    vec3 fwd = normalize(ta - ro);
    vec3 left = cross(vec3(0, 1, 0), fwd);
    vec3 up = cross(fwd, left);
    return normalize(fwd + uv.x*left + up*uv.y);
}

vec3 normal(in vec3 pos)
{
    vec2 e = vec2(1., -1.)*.5773*.0005;
    return normalize(e.xyy*map(pos + e.xyy).w +
        e.yyx*map(pos + e.yyx).w +
        e.yxy*map(pos + e.yxy).w +
        e.xxx*map(pos + e.xxx).w);
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (q - .5) * resolution.xx / resolution.yx;
    
    time2 = mod(time/duration,duration);

    float posy = mix(radius1,radius2,0.17);
    vec3 ro = vec3(0., posy-0.25, -4.);
    vec3 ta = vec3(0, posy+0.2, 0.);
    vec3 rd;

    rd = camera(ro, uv, ta);

    vec3 p;
    vec4 res;
    float ri, t = 0.;
    for (float i = 0.; i < 1.; i += 1.0/80.0) {
        ri = i;
        p = ro + rd*t;
        res = map(p);
        if (res.w<.001 || t>30.) break;
        t += res.w*0.6;
    }

    vec3 bg = vec3(0.);
    
    vec3 col = res.xyz;
    
    float dper = 1.0;
    float dist = t + 1.5*p.y + 1.5*pow(abs(p.x),1.3);
    float a = mod(dist-dper*time2,dper)/dper;
    float lp = smoothstep(0.,0.5,d2_saved);
    float v = 0.5*glow*(lp+0.1);
    col += vec3(v,0.6*v,0.4*v)*pow(min(a,10.0*(1.-a)),6.0);
    col += vec3(0.2*glow*(1.0-lp),0.,0.)*pow(min(a,20.0*(1.-a)),20.0);
    col += vec3(0.05);
    
    col = mix(col, vec3(0.4,0.8,1.0), 0.9*ri);

    glFragColor = vec4(col, 1.);
}
