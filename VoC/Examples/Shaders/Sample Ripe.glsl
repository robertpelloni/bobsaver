#version 420

// original https://www.shadertoy.com/view/wddXWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Final SHADERTOBER 31 Ripe (actually, it's GREEN CHICKEN)
// Poulet Vert 03-11-2019
// thanks everyone for your advices, tricks, functions
// i learned a lot and it's because of this great community

#define VOLUME 0.001
#define PI 3.14159

//MICROSOFT PAINT COLORS ftw
#define black   vec3(0.0, 0.0, 0.0)
#define white   vec3(1.0, 1.0, 1.0)
#define gray1   vec3(0.4980, 0.4980, 0.4980)
#define gray2   vec3(0.7647, 0.7647, 0.7647)
#define brown1  vec3(0.5333, 0.0, 0.0823)
#define brown2  vec3(0.7254, 0.4784, 0.3411)
#define red1    vec3(0.9294, 0.1098, 0.1411)
#define red2    vec3(1.0, 0.6823, 0.7882)
#define orange1 vec3(1.0, 0.4980, 0.1529)
#define orange2 vec3(1.0, 0.7882, 0.0549)
#define yellow1 vec3(1.0, 0.9490, 0.0)
#define yellow2 vec3(0.9372, 0.8941, 0.6901)
#define green1  vec3(0.7098, 0.9019, 0.1137)
#define green2  vec3(0.1333, 0.6941, 0.2980)
#define cyan1   vec3(0.0, 0.6352, 0.9098)
#define cyan2   vec3(0.6, 0.8509, 0.9176)
#define blue1   vec3(0.2470, 0.2823, 0.8)
#define blue2   vec3(0.4392, 0.5725, 0.7450)
#define purple1 vec3(0.6392, 0.2862, 0.6431)
#define purple2 vec3(0.7843, 0.7490, 0.9058)

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

vec2 opU2( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

vec2 opP2( vec2 d1, vec2 d2)
{
    return (d1.x < d2.x) ? d1 : max(d1, d2);
}

vec3 opRep(vec3 p, vec3 c)
{
     return mod(p+0.5*c,c)-0.5*c;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// iq based line function
float sdLine( vec3 p, vec3 a, vec3 b )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdCone( in vec3 p, in vec2 c )
{
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

// Scene setup
vec2 map(vec3 p)
{
    
    // world
    vec3 gp = p;
    gp.xy *= rot(p.z*.02+sin(time)*.5);
    vec3 wp = gp + vec3(0.0, -.5, 0.0);
    wp = opRep(wp, vec3(1.0));
    float world = sdBox(wp, vec3(1.0));
    
    vec3 swp = gp + vec3(0.0, -.5, 0.0);
    swp = opRep(swp, vec3(0.0, 0.0, 2.0));
    float sworld = sdBox(swp, vec3(2.0));
    world = max(world, -sworld);
    
    // particules
    vec3 pp = p + vec3(1.0, 0.0, 0.0);
    pp.xy *= rot(time+p.z);
    pp.z += time*5.0;
    pp.y += sin(time);
    pp = opRep(pp, vec3(0.0, 0.0, 5.0));
    float pb = sdBox(pp, vec3(.1));
    
    pp = p + vec3(-1.0, 0.0, .5);
    pp.xy *= rot(time+p.z);
    pp.z += time*5.0;
    pp.y += sin(time);
    pp = opRep(pp, vec3(0.0, 0.0, 5.0));
    pb = min(pb, sdBox(pp, vec3(.1)));
    
    // body
    vec3 b = p + vec3(0.0);
    b.xy *= rot(sin(p.y+time)*.5);
    float body = sdVerticalCapsule(b, 1.0, .5);
    vec3 shl = b + vec3(0.0, -.0, 0.0);
    
    // left arm
    vec3 la = shl + vec3(-.4, -0.7, 0.0);
    la.x -= sin(la.y*5.+time*5.0)*.1;
    vec3 l1l = vec3(.75, .75, 0.0);
    float l1 = sdLine(la, vec3(0.0, 0.0, 0.0), l1l);
    l1 -= 0.1;
    float larm = l1;
    
    // right arm
    vec3 ra = shl + vec3(.4, -0.7, 0.0);
    ra.x += sin(ra.y*5.+time*5.0)*.1;
    vec3 r1l = vec3(-.75, .75, 0.0);
    float r1 = sdLine(ra, vec3(0.0, 0.0, 0.0), r1l);
    r1 -= 0.1;
    float rarm = r1;
    
    // left foot
    vec3 lf = b + vec3(.3, .3, 0.0);
    lf.x += sin(lf.y*5.0+time*5.0)*.1;
    vec3 lf1l = vec3(-.5, -.5, 0.0);
    float lf1 = sdLine(lf, vec3(0.0, 0.0, 0.0), lf1l);
    lf1 -= 0.2;
    float lleg = lf1;
    
    // right foot
    vec3 rf = b + vec3(-.3, .3, 0.0);
    rf.x += sin(rf.y*5.0+1.0+time*5.0)*.1;
    vec3 rf1l = vec3(.5, -.5, 0.0);
    float rf1 = sdLine(rf, vec3(0.0, 0.0, 0.0), rf1l);
    rf1 -= 0.2;
    float rleg = rf1;
    
    // rooster top
    vec3 roo = b + vec3(0.0, -1.5, -0.2);
    float rooster = sdSphere(roo, .2);
    roo = b + vec3(0.0, -1.5, 0.0);
    rooster = min(rooster, sdSphere(roo, .25));
    roo = b + vec3(0.0, -1.5, 0.2);
    rooster = min(rooster, sdSphere(roo, .2));
    
    // eyes du cul
    vec3 be = b + vec3(0.0, -.95, -0.4);
    vec3 ep = be + vec3(0.2, 0.0, 0.0);
    float eyes = sdSphere(ep, .15);
    ep = be + vec3(-0.2, 0.0, 0.0);
    eyes = min(eyes, sdSphere(ep, .15));
    vec3 se = be + vec3(0.0, -.3, 0.0);
    float subEye = sdSphere(se, .35);
    eyes = max(eyes, -subEye);
    
    // pupil
    vec3 pup = be + vec3(0.2, 0.0, -0.2);
    float pupi = sdSphere(pup, .04);
    pup = be + vec3(-0.2, 0.0, -0.2);
    pupi = min(pupi, sdSphere(pup, .04));
    
    // mouth
    vec3 mp = b + vec3(0.0, -0.7, -0.5);
    float mouth = sdSphere(mp, .3);
    mp = b + vec3(0.0, -1.0, -0.5);
    mouth = max(mouth, -sdSphere(mp, .4));
    body = max(body, -mouth);
    
    // materials
    vec2 scene = vec2(body, 0.0);
    scene = opU2(scene, vec2(larm, 0.0));
    scene = opU2(scene, vec2(rarm, 0.0));
    scene = opU2(scene, vec2(lleg, 0.0));
    scene = opU2(scene, vec2(rleg, 0.0));
    scene = opU2(scene, vec2(rooster, 1.0));
    scene = opU2(scene, vec2(eyes, 2.0));
    scene = opU2(scene, vec2(pupi, 3.0));
    
    scene = opP2(scene, vec2(mouth, 4.0));
    
    scene = opU2(scene, vec2(world, 5.0));
    scene = opU2(scene, vec2(pb, 6.0));
    
    return scene; 
}

vec2 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<128 ; i++)
    {
        vec2 ray = map(ro + rd * t);
        
        if(ray.x < (0.0001*t))
        {
            return vec2(t, ray.y);
        }
        
        t += ray.x;
    }
    
    return vec2(-1.0, 0.0);
}

vec3 GetNormal (vec3 p)
{
    float c = map(p).x;
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(map(p+e.xyy).x, map(p+e.yxy).x, map(p+e.yyx).x) - c);
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv, float time)
{
    
    
    // map stuffs
    vec2 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    
    vec3 nor = GetNormal(pos);
    vec3 light = vec3(sin(time), 1.0, cos(time));
    float l = clamp(dot(nor, light), 0.0, 1.0);
    
    if(t.x == -1.0)
    {
            
        col = black;
    }
    else
    {   
        if(t.y==0.0)
        {
            col = mix(green1, green2, step(l, .5));
        }
        else if(t.y==1.0)
        {
            col = mix(red1, brown1, step(l, .5));
        }
        else if(t.y==2.0)
        {
            col = mix(white, gray2, step(l, .1));
        }
        else if(t.y==3.0)
        {
            col = black;
        }
        else if(t.y==4.0)
        {
            col = mix(purple2, purple1, step(l, .5));
        }
        else if(t.y==5.0)
        {
            col = mix(blue1, blue2, step(fract(pos.z*.2+time), .5));
            
        }
        else if(t.y==6.0)
        {
            col = mix(yellow1, orange1, step(l, .5));
        }
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(0.0, -1.0, 0.0), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 2.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    vec3 cp = vec3(0.0, 0.0, 5.0);
    vec3 ct = vec3(0.0, 0.0, 0.0);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    vd.xy *= rot(time);
    
    vec3 col = Render(cp, vd, uv, time);
    
    col.b -= uv.y*.5;
    
    glFragColor = vec4(col,1.0);
}
