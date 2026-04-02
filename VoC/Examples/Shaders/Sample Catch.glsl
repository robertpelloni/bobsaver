#version 420

// original https://www.shadertoy.com/view/tsdSRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 30 Catch
// Poulet vert 31-10-2019
// thanks iq for sdf functions
// inspired by hexeosis psy loop visuals

#define VOLUME 0.001
#define PI 3.14159

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

vec3 opRep(vec3 p, vec3 c)
{
     return mod(p+0.5*c,c)-0.5*c;
}

vec2 opU2( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// Scene setup
vec2 map(vec3 p)
{
    // base full world
    vec3 bp = p + vec3(0.0);
    bp = opRep(bp, vec3(1.0));
    float b = sdBox(bp, vec3(1.0));
    
    // tunnels
    vec3 tp = p + vec3(0.0);
    tp = opRep(tp, vec3(0.0, 0.0, 1.0));
    float t = sdBox(tp, vec3(1.0));
    
    tp = p + vec3(1.0, 0.0, 0.0);
    tp = opRep(tp, vec3(0.0, 0.0, .5));
    t = min(t, sdBox(tp, vec3(.5)));
    
    tp = p + vec3(-1.0, 0.0, 0.0);
    tp = opRep(tp, vec3(0.0, 0.0, .5));
    t = min(t, sdBox(tp, vec3(.5)));
    
    tp = p + vec3(0.0, 1.0, 0.0);
    tp.xy *= rot(PI/4.0);
    tp = opRep(tp, vec3(0.0, 0.0, .5));
    t = min(t, sdBox(tp, vec3(.5)));
    
    tp = p + vec3(0.0, -1.0, 0.0);
    tp.xy *= rot(PI/4.0);
    tp = opRep(tp, vec3(0.0, 0.0, .5));
    t = min(t, sdBox(tp, vec3(.5)));
    
    b = max(b, -t);
    
    // lines
    vec3 lp = p + vec3(1.5, 0.0, 0.0);
    lp = opRep(lp, vec3(0.0, 0.0, 2.0));
    float l = sdBox(lp, vec3(0.1, .5, 1.0));
    
    lp = p + vec3(-1.5, 0.0, 0.0);
    lp = opRep(lp, vec3(0.0, 0.0, 2.0));
    l = min(l, sdBox(lp, vec3(0.1, .5, 1.0)));
    
    lp = p + vec3(0.0, 1.0, 0.0);
    lp.xy *= rot(PI/4.0);
    lp = opRep(lp, vec3(0.0, 0.0, 2.0));
    l = min(l, sdBox(lp, vec3(0.5, .5, 1.0)));
    
    lp = p + vec3(0.0, 0.9, 0.0);
    lp.xy *= rot(PI/4.0);
    lp = opRep(lp, vec3(0.0, 0.0, 1.0));
    l = max(l, -sdBox(lp, vec3(0.5, .5, 1.0)));
    
    lp = p + vec3(0.0, -1.0, 0.0);
    lp.xy *= rot(PI/4.0);
    lp = opRep(lp, vec3(0.0, 0.0, 2.0));
    l = min(l, sdBox(lp, vec3(0.5, .5, 1.0)));
    
    lp = p + vec3(0.0, -0.9, 0.0);
    lp.xy *= rot(PI/4.0);
    lp = opRep(lp, vec3(0.0, 0.0, 1.0));
    l = max(l, -sdBox(lp, vec3(0.5, .5, 1.0)));
    
    // torus
    vec3 ap = p + vec3(0.0);
    ap.yz *= rot(PI/2.0);
    ap = opRep(ap, vec3(0.0, 1.0, 0.0));
    float a = sdTorus(ap, vec2(3.0, .1));
    
    // rooms
    vec3 rp = p + vec3(0.0);
    rp = opRep(rp, vec3(0.0, 0.0, 10.0));
    float r = sdBox(rp, vec3(5.0, 5.0, 2.0));
    
    b = max(b, -r);
    l = max(l, -r);
    
    
    // Materials
    vec2 scene = vec2(b, 0.0);
    scene = opU2(scene, vec2(l, 1.0));
    scene = opU2(scene, vec2(a, 2.0));
    
    return scene;
}

vec3 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<128 ; i++)
    {
        vec2 ray = map(ro + rd * t);
        
        if(ray.x < (0.0001*t))
        {
            return vec3(t, ray.y, float(i)/128.);
        }
        
        t += ray.x;
    }
    
    return vec3(-1.0, 0.0, 0.0);
}

vec3 GetNormal (vec3 p)
{
    float c = map(p).x;
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(map(p+e.xyy).x, map(p+e.yxy).x, map(p+e.yyx).x) - c);
}

float GetLight(vec3 N, vec3 lightPos)
{
    return max(dot(N, normalize(lightPos)), 0.0);
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv)
{
    vec3 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    vec3 polyCol = palette(fract(floor(pos.z)*.05), vec3(.5), vec3(.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
    polyCol *= step(fract(pos.z+.1), .8);
    
    if(t.x == -1.0)
    {
        col = vec3(0.0);
    }
    else
    {    
        vec3 N = GetNormal(pos);
        
        vec3 mainL = vec3(1.0, 1.0, 0.0);
        float mainlight = GetLight(N, mainL);
        
        vec2 ledFreq = vec2(.15, .17);
        vec2 ledUV =  vec2(-pos.x+5.08, -pos.y-.5);
        
        float depth = t.z;
        
        if(t.y == 0.0)
        {
            col = vec3(1.0)*mainlight*.5+.5;
            col.y -= uv.y;
            col *= .1;
        }
        else if(t.y == 1.0) // effect
        {
            col = polyCol;
            
        }
        else if(t.y == 2.0) // effect
        {
            col = vec3(1.0);
            col.x = uv.y;
            
        }
        
        col *= 1.0-t.z;
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(0.0, -1.0, 0.0), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 1.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    float time = time * 10.0;
    
    
    vec3 cp = vec3(0.0, 0.0, time-5.0);
    vec3 ct = vec3(0.0, 0.0, time);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec3 col = Render(cp, vd, screenUV);
    
    vec3 gradient = mix(vec3(1.0, 0.25, 0.3), vec3(0.3, 0.1, 1.0), -uv.y);
    
    col *= gradient;
    
    col = sqrt(clamp(col, 0.0, 1.0));
    
    glFragColor = vec4(col,1.0);
}
