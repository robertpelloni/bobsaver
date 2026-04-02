#version 420

// original https://www.shadertoy.com/view/4ttyRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define EPSILON 0.001
#define FAR 1000.
mat2 rot( in float a ) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);    
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdBox( vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCross( in vec3 p, float size)
{
  float da = sdBox(p.xy,vec2(size));
  float db = sdBox(p.yz,vec2(size));
  float dc = sdBox(p.zx,vec2(size));
  return min(da,min(db,dc));
}

#define PILLAR_SEP 160.
#define PILLAR_WIDTH 10.
#define FAME_SIZE 1.

float frame(vec3 p)
{
    float d;
    d = sdBox(p, vec3(FAME_SIZE));
    d = max(d, -sdCross(p, FAME_SIZE*0.5));
    return d;
}

float grid(vec3 q)
{
    q = mod(q,2.)-0.5*2.;
    return frame(q);
}

float gridCross(vec3 q)
{
    float d;
    q = mod(q, PILLAR_SEP)- 0.5*PILLAR_SEP;
    d = grid(q);
    d = max(sdCross(q, PILLAR_WIDTH), d);
    return d;
}

float map(vec3 p)
{
    float d;
       p.y += sin(p.x*0.0141231 + time*1.03123)*4.;
    p.x += sin(p.z*0.0323124 + time*0.8345)*7.;
    p.z += sin(p.x*0.022345 + time*0.73245)*6.;
    vec3 q = p;
    
    
    d = gridCross(q);
    q += vec3(-PILLAR_WIDTH,-PILLAR_WIDTH*3.,-PILLAR_WIDTH);
    q = mod(q , PILLAR_WIDTH*2.) - 0.5 * PILLAR_WIDTH*2.;
    d = max(-sdCross(q, 6.), d);
    return d;
}
#define steps 128
float march(vec3 o, vec3 r, out float m)
{
    float t = 0.;
    int i = 0;
    for(i; i < steps; i++)
    {
        vec3 p = o + r * t;
        float d = map(p);
        if(d < EPSILON || t > FAR)
            break;
        t += d * 0.4;
    }
    m = float(i);
    return min(FAR, t);
}

vec3 getNormal(vec3 pos)
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ) + 
                      e.yyx*map( pos + e.yyx ) + 
                      e.yxy*map( pos + e.yxy ) + 
                      e.xxx*map( pos + e.xxx ) );
}

const vec3 lightDir = normalize(vec3(2,2,-2));

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = -1. + 2.*uv;
    uv.x *= resolution.x/resolution.y;
    vec3 o = vec3(0,0,time*20.);
    vec3 r = normalize(vec3(uv,1.));
    
    float m;
    float d = march(o,r,m);
    
    vec3 fogCol = vec3(0.5,0.7,0.9)*0.7;
    
    vec3 col = vec3(fogCol);
    float l = 1.-smoothstep(0., .95, d/FAR);
    if(d < FAR)
    {
        m = (m / float(steps)) + 0.01;
        float fog = (1.0 / (1.0 + m*m * 10.));
        
        col = vec3(fog);
    }
    col = mix(vec3(fogCol), col, l);
    
    glFragColor = vec4(col,1.0);
}
