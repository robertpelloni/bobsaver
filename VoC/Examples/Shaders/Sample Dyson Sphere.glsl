#version 420

// original https://www.shadertoy.com/view/wd2cWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 64
#define MAX_DIST 20.
#define EPS 0.001
const float PI = acos(-1.0);

mat3 rotX(float angle)
{
    return mat3(1,    0,            0,
               0,    cos(angle), -sin(angle),
               0,    sin(angle), cos(angle));
}

mat3 rotY(float angle)
{
    return mat3(cos(angle), 0, sin(angle),
               0,            1, 0,
               -sin(angle), 0, cos(angle));
}

mat3 rotZ(float angle)
{
    return mat3(cos(angle), -sin(angle), 0,
               sin(angle),     cos(angle),     0,
               0,             0,             1);
}

vec2 opRevolution( in vec3 p, float w )
{
    return vec2( length(p.xz) - w, p.y );
}

float sdCube(vec2 pos, vec2 r)
{
    vec2 q = abs(pos) - r;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);
}

float sdCube(vec3 pos, vec3 r)
{
    vec3 q = abs(pos) - r;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere(vec3 pos, float r)
{
    return length(pos) - r;
}

float sdRing(vec3 pos, float r)
{
    pos.zy = opRevolution(pos, r);
    return sdCube(vec2(pos.z, pos.y), vec2(0.02, 0.03));
}

float sdRingsCross1( in vec3 pos, in float r )
{
    float d1 = sdRing(pos, r);
    
    pos *= rotZ(PI/2.);
    float d2 = sdRing(pos, r);
    
    pos *= rotX(PI/2.);
    float d3 = sdRing(pos, r);
    
    pos *= rotX(PI/4.);
    float d4 = sdRing(pos, r);
    
    return min(d1,min(d2,min(d3,d4)));
}

float sdRingsCross2( in vec3 pos, in float r )
{
    pos *= rotZ(PI/4.);
    float d1 = sdRing(pos, r);
    
    pos *= rotZ(PI/2.);
    float d2 = sdRing(pos, r);
    
    return min(d1,d2);
}

float sdDysonSphere( in vec3 pos, in float r )
{
    float d1 = sdRingsCross1(pos, r);
    
    pos *= rotY(PI/4.);
    float d2 = sdRingsCross2(pos, r);
    
    pos *= rotY(PI/2.);
    float d3 = sdRingsCross2(pos, r);
    
    return min(d1, min(d2, d3));
}

float map(vec3 pos)
{
    
    float d0 = sdSphere(pos, 0.2+sin(time*0.3)*0.05);
    float d1 = sdDysonSphere(pos * rotY(time * 1.00), 0.5);
    float d2 = sdDysonSphere(pos * rotY(time * 0.50), 0.7);
    float d3 = sdDysonSphere(pos * rotY(time * 0.25), 0.9);
    
    float res = MAX_DIST;
    res = min(res, d0);
    res = min(res, d1);
    res = min(res, d2);
    res = min(res, d3);
    return res;
}

vec3 normals(vec3 pos)
{
    vec2 e = vec2(0, 0.01);
    return normalize(vec3(
        map(pos+e.yxx)-map(pos-e.yxx),
        map(pos+e.xyx)-map(pos-e.xyx),
        map(pos+e.xxy)-map(pos-e.xxy)
    ));
}

const vec4 miss = vec4(MAX_DIST, vec3(0));
vec4 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for(int i = 0; i<MAX_STEPS; i++)
    {
        vec3 pos = ro + rd*t;
        float d = map(pos);
        
        if(abs(d)<=EPS) return vec4(length(pos-ro), normals(pos));
        if(d >= MAX_DIST) return miss;
        
        t+=d;
    }
         
    
    return miss;
}

const vec3 BACKGROUND = vec3(0.2);
vec3 GetScene(vec3 ro, vec3 rd)
{
    
    vec4 a = raymarch(ro, rd);
    float d = a.x;
    vec3 nor = a.yzw;
    
    vec3 col = BACKGROUND;
    
    if(d < MAX_DIST)
    {
        vec3 pos = ro+rd*d;
        
        float li = dot(normalize(-pos), nor);
        li = li*0.5+0.5;
        li = li*0.9+0.1;
        
        col = vec3(1, 0.94, 0.8) * li;
    }
    
    return col;
    
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.x;
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    float camAngle = PI/4.; // mouse.x*PI*2.;
    vec2 p = 3.0 * vec2(cos(camAngle), sin(camAngle));
    vec3 ro = vec3(p.x,1.5,p.y);
    mat3 ca = setCamera(ro, vec3(0,0,0), 0.0);
    vec3 rd = ca*normalize(vec3(uv,1.8));
    
    vec3 col = GetScene(ro, rd);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
