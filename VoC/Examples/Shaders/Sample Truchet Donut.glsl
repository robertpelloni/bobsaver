#version 420

// original https://www.shadertoy.com/view/DltGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by @etiennejcb
// using donut distortion from leon: https://www.shadertoy.com/view/XlfBR7
// inspired by flopine

float t;

float R = 1.2;
float r = 0.4;
float L = 0.145;

vec2 localUV;
float glow = 0.;
float type1;
float type2;
float i1,i2;
float h;

float PI = 3.141592;
#define TAU (2.*PI)

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

int randomInt(int minVal, int maxVal, int seed1, int seed2) {
    vec2 seeds = vec2(float(seed1), float(seed2));
    float randomFloat = rand(seeds);
    int range = maxVal - minVal + 1;
    return int(floor(randomFloat * float(range))) + minVal;
}

mat2 rot(float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c,-s,s,c);
}

// from Inigo Quilez
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// from https://www.shadertoy.com/view/XlfBR7
vec2 displaceLoop (vec2 p, float r)
{
    return vec2(length(p.xy)-r, atan(p.y,p.x));
}

// from https://www.shadertoy.com/view/XlfBR7
float amod (inout vec2 p, float count)
{
    float an = TAU/count;
    float a = atan(p.y,p.x)+an/2.;
    float c = floor(a/an);
    c = mix(c,abs(c),step(count*.5,abs(c)));
    a = mod(a,an)-an/2.;
    p.xy = vec2(cos(a),sin(a))*length(p);
    return c;
}

// from https://www.shadertoy.com/view/XlfBR7
float amodIndex (vec2 p, float count)
{
    float an = TAU/count;
    float a = atan(p.y,p.x)+an/2.;
    float c = floor(a/an);
    c = mix(c,abs(c),step(count*.5,abs(c)));
    return c;
}

// from https://www.shadertoy.com/view/XlfBR7
float repeat (float v, float c){return mod(v,c)-c/2.; }
vec2 repeat (vec2 v, vec2 c) { return mod(v,c)-c/2.; }
vec3 repeat (vec3 v, float c) { return mod(v,c)-c/2.; }

float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2.*p, g);
  else
    return 1. - 0.5 * pow(2.*(1. - p), g);
}

float map(vec3 p)
{
    float dist = 12345.;
    
    p.xy *= rot(0.4*t);
    p.yz *= rot(0.65*t+PI/2.);

    // donut distortion from leon : https://www.shadertoy.com/view/XlfBR7
    vec3 pDonut = p;
    pDonut.xz = displaceLoop(pDonut.xz, R);
    pDonut.z *= R;
    pDonut.xzy = pDonut.xyz;
    
    p = pDonut;
    
    p.xz *= rot(0.7*t);
    
    float repetitionLength = 0.314;
    i1 = floor(p.y/repetitionLength);
    p.y = repeat(p.y, repetitionLength);
    
    float cnt = 10.;
    i2 = amodIndex(p.xz,cnt);
    amod(p.xz,cnt);
    p.x -= r;
    
    float q = 0.22*t-(0.082*i1+0.12*mod(i2,2.0)+0.015*i2)+12345.;
    float qMod2 = mod(q,2.);
    
    float fp = 5.;
    float rotIndex = floor(qMod2);
    float r = ease(clamp(fp*qMod2-fp*rotIndex,0.,1.),2.2)+rotIndex;
    p.xz *= rot(r*PI);
    
    float l1 = L;
    float l2 = L;
    dist = min(dist,sdBox(p,vec3(0.02,l1,l2))-0.013);

    type1 = (p.x>=0.?0.:1.);
    float qMod4 = mod(q+1.+type1,4.);
    type2 = qMod4>1.5?1.:0.;
    
    localUV = p.yz/vec2(l1,l2);
    h = p.x;
    
    glow += 0.003/(0.2+pow(0.01*abs(dist),0.5));
    
    return dist;
}

// NuSan
// https://www.shadertoy.com/view/3sBGzV
vec3 getNormal(vec3 p) {
    vec2 off=vec2(0.001,0);
    return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

void main(void)
{
    vec2 a = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (a - .5) * resolution.xx / resolution.yx;
    
    vec3 ro=vec3(uv*3.5,-10.), rd=vec3(0.,0.,1.);
    
    t = time;

    vec3 p;
    float res;
    float d = 0.;
    bool hit = false;
    vec3 nrml;
    
    float q;
    
    // raymarching loop
    for (q = 0.; q < 1.; q += 1.0/44.0) {
        p = ro + rd*d;
        res = map(p);
        if (res<.001)
        {
            hit = true;
            nrml = getNormal(p);
            break;
        }
        d += res*0.8;
    }

    
    vec3 col = vec3(1.)-vec3(0.2)*length(uv);
    float patternColorMix = 0.;
    float otherMixer = 0.;
    
    if(hit)
    {
        // truchet pattern...
        
        if(type1==0.)
            localUV *= rot(PI/2.*(i1+i2));
        if(type2==0.)
            localUV *= rot(PI/2.*float(randomInt(0,4,int(i1),int(i2))));
        
        float A = 4.2;
        float B = 3.7;
        
        float pattern0 = sin(PI*clamp(A*length(localUV-vec2(1.))-B,0.,1.));
        float pattern1 = sin(PI*clamp(A*length(localUV-vec2(-1.))-B,0.,1.));
        
        float pattern= min(1.,pattern0+pattern1);

        glow += pattern;
        patternColorMix += pattern*0.66;
        // uncomment for a variant, quite glitchy
        // otherMixer += max(0.,1.0-30.*abs(h));
    }
    
    // color experiments...
    
    col = mix(col,vec3(0.4,0.65,1.),glow);
    col = mix(col,vec3(0.6,0.6,0.8),otherMixer);
    
    float light = 0.7+0.2*dot(nrml,vec3(4.*sin(0.2*t+3.),1.*sin(0.3*t+2.),2.*sin(0.4*t)));
    
    vec3 blueColor = mix(vec3(0.4,0.3,1.0),vec3(1.,1.,1.),clamp(1.5*light,0.,1.2));
    vec3 redColor = mix(vec3(1.2,0.3,0.4),vec3(1.,1.,1.),clamp(1.2-1.1*light,0.,1.0));
    
    col = mix(col,type1==0.?blueColor:redColor,patternColorMix);

    glFragColor = vec4(col.xyz, 1.);
}
