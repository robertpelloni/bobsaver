#version 420

// original https://www.shadertoy.com/view/Wsf3Dn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// GLOOPY

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 opUnionRound(const in vec2 a, const in vec2 b, const in float r)
{
    vec2 res = vec2(smin(a.x,b.x,r),(a.x<b.x) ? a.y : b.y);
    return res;
}

// http://mercury.sexy/hg_sdf/
// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size)
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}
    
#define    TAU 6.28318
#define CHS 0.35
float sdBox2(in vec2 p,in vec2 b) {vec2 d=abs(p)-b;return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);}
float line2(float d,vec2 p,vec4 l){vec2 pa=p-l.xy;vec2 ba=l.zw-l.xy;float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);return min(d,length(pa-ba*h));}
float LR(vec2 p, float d){p.x=abs(p.x);return line2(d,p,vec4(2,-3.25,2,3.25)*CHS);}
float TB(vec2 p, float d){p.y=abs(p.y);return line2(d,p,vec4(2,3.25,-2,3.25)*CHS);}
float TBLR(vec2 p, float d){return min(d,abs(sdBox2(p,vec2(2,3.25)*CHS)));}
float G(vec2 p,float d){d=TB(p,d);d=line2(d,p,vec4(-2,-3.25,-2,3.25)*CHS);d=line2(d,p,vec4(2,2.25,2,3.25)*CHS);d=line2(d,p,vec4(2,-3.25,2,-0.25)*CHS);return line2(d,p,vec4(2,-0.25,0.5,-0.25)*CHS);}
float L(vec2 p,float d){d=line2(d,p,vec4(2,-3.25,-2,-3.25)*CHS);return line2(d,p,vec4(-2,3.25,-2,-3.25)*CHS);}
float O(vec2 p,float d){return TBLR(p,d);}
float P(vec2 p,float d){d=line2(d,p,vec4(-2,-3.25,-2,0.0)*CHS);p.y-=1.5*CHS;return min(d,abs(sdBox2(p,vec2(2.0,1.75)*CHS)));}
float Y(vec2 p,float d){d=line2(d,p,vec4(0,-0.25,0,-3.25)*CHS);p.x=abs(p.x);return line2(d,p,vec4(0,-0.25,2,3.25)*CHS);}

float message(vec3 p)
{
    float d = 1.0;
    float cw = 5.8*CHS;
    float gap = (cw*2.0)+40.0;
    float width = (16.0*cw);
    float xmod = width+gap;
    
    float c = pMod1(p.z,9.0);
    p.z -= 0.2+sin(p.x*1.3+fract(time*0.05)*TAU)*0.08;
    p.x += fract(time*0.075)*xmod+c*16.0;
    pMod1(p.x, xmod);
    vec2 uv = p.xy;
    float x = -((width*0.5+gap*0.5)-cw);
    float t1 = fract(time*0.5) * TAU;
    float y = -1.0+sin(t1+p.x*0.25)*0.5;
    uv-=vec2(x,y);
    d = G(uv,d); uv.x -= cw;
    d = L(uv,d); uv.x -= cw;
    d = O(uv,d); uv.x -= cw;
    d = O(uv,d); uv.x -= cw;
    d = P(uv,d); uv.x -= cw;
    d = Y(uv,d);
    d -= 0.1;
    if (d<1.0)
    {
        float dep = 0.025;
        vec2 e = vec2( d, abs(p.z) - dep );
        d = min(max(e.x,e.y),0.0) + length(max(e,0.0));
        d -= 0.325*CHS;
    }
    return d;
}

mat2 rot(float a)
{
    float c = cos(a),
        s = sin(a);
    return mat2(c, s, -s, c);
}

float map(vec3 p)
{
    float t2 = fract(time*0.05) * TAU;
    p.xy *= rot(p.y*0.02+p.x*0.04-p.z * .05 + t2);
    float k = dot(sin(p.z+2. * p - cos(p.yxz)), vec3(.233));
    k-=sin(p.x*p.y+p.z)*0.14;
    k*=0.7+sin(fract(time*0.54)*TAU+p.z*1.4)*0.35;
    float d = 2.5 -abs(p.y) - k*k;
    float dm = message(p);
    d = smin(d,dm,0.75);
    return d;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.001, 0.);
    vec3 n;
    n.x = map(p + e.xyy) - map(p - e.xyy);
    n.y = map(p + e.yxy) - map(p - e.yxy);
    n.z = map(p + e.yyx) - map(p - e.yyx);
    return normalize(n);
}

vec3 render(vec2 uv) {
    
    vec3 ro = vec3(sin(time)*0.15, cos(time*0.5)*0.2, time*0.75);
    vec3 rd = normalize(vec3(uv, .8));
    vec3 p = vec3(0.);
    float t = 0.;
    for (int i = 0; i < 80; i++)
    {
        p = ro + rd * t;
        float d = map(p);
        if (d < .001 || t > 100.) break;
        t += .5 * d;
    }
    vec3 l = ro;
    vec3 n = normal(p);
    vec3 lp = normalize(l - p);
    float diff = .5 * max(dot(lp, n), 0.);
    return vec3(diff*0.65,diff*1.49,diff*0.65) / (1. + t * t * .01);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    glFragColor = vec4(render(uv), 1.);
}

