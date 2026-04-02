#version 420

// original https://www.shadertoy.com/view/wdGGWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 14 Overgrown
// Poulet vert 14-10-2019
// Thanks to iq, Leon

#define VOLUME 0.001
#define PI 3.14159
#define MAXSTEP 64
#define sdist(p,r) (length(p)-r)
#define TAU (2.*PI)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float uSDF(float s1, float s2) { return min(s1, s2);}

float sSDF( float d1, float d2 ) { return max(-d1,d2); }

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); 
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdBox( vec3 p, float s )
{
  vec3 q = abs(p) - vec3(s);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 opRep(vec3 p, vec3 c)
{
     return mod(p+0.5*c,c)-0.5*c;
}

float opU(float d1, float d2)
{
    return min(d1, d2);
}

vec2 opU2( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

// leon ftw
float amod (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an/2.;
    float c = floor(a/an);
    a = mod(abs(a),an)-an/2.;
    p = vec2(cos(a),sin(a))*length(p);
    return c;
}

float polarModulo (vec3 p) {
    amod(p.xz, 5.);
    p.x -= 1.;
    return sdist(p, .5);
}

float tubeTwist (vec3 p, float s, float o) {
    p.xz *= rot(p.y*2.0-time-o);
    amod(p.xz, 8.);
    p.x -= .5;
    return sdist(p.xz, s);
}

// Scene setup

vec2 map(vec3 pos)
{

    vec2 t = vec2(pos.y, 0.0);
    
    float anim = (.25 + abs(sin(time))*.25) * (1.0-pos.y*.2);
    
    vec3 sp = pos + vec3(0.0, 0.0, time*5.0);
    sp = opRep(sp, vec3(4.0, 0.0, 4.0));
    float grow = tubeTwist(sp, anim, 0.0);
    grow = opU(grow, tubeTwist(sp, anim, 3.0));
    
    vec2 g = vec2(grow, 1.0);
    
    vec3 shp = pos + vec3(-2.0, -1.0, -4.0+sin(time)*2.0);
    shp.xy *= rot(time);
    float sh = sdSphere(shp, .5);
    float ch = sdBox(shp, .25);
    
    vec2 s = vec2(mix(sh, ch, (1.0+sin(time*5.0))*.5), 2.0);
    
    t = opU2(t, g);
    t = opU2(t, s);
    
    return t;
}

vec2 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<64 ; i++)
    {
        vec2 ray = map(ro + rd * t);
        
        if(ray.x < (0.0001*t))
        {
            return vec2(float(i)/64., ray.y);
        }
        
        t += ray.x;
    }
    
    return vec2(-1.0, 0.0);
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv)
{
    vec2 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    
    if(t.x == -1.0)
    {
        
        col = vec3(.0); 
        
    }
    else
    {
        float depth = 1.0 - t.x;
        
        if(t.y == 0.0)
        {
            col = vec3(depth*.25);
        }
        else if(t.y == 1.0)
        {
            col = vec3(0.0, 1.0, 1.0) * depth*.5;
        }
        else if(t.y == 2.0)
        {
            col = vec3(1.0, 0.0, 0.0) + depth * .8;
        }
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(sin(time), -1.0, cos(time)), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 1.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    float forwardTime = 0.0;// time*5.0;
    float offsetTime = 2.0+sin(time);
    float up = 1.0+sin(time*.3)*.9;
    
    vec3 cp = vec3(offsetTime, up, forwardTime-1.0);
    vec3 ct = vec3(offsetTime, up, forwardTime);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    vec3 col = Render(cp, vd, screenUV);
    
    // compo
    col.g -= screenUV.y * .2;
    col.r += (1.0-length(uv)*2.0)-.5;
    
    
    col += random(uv)*.1* length(uv) * 2.0;
    
    col = clamp(col, 0.0, 1.0);
    col *= 1.0-length(uv)*.75;
    
    glFragColor = vec4(col,1.0);
}
