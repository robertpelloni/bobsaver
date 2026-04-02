#version 420

// original https://www.shadertoy.com/view/wsK3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 04 Freeze
// Poulet vert 04/10/2019
// thanks to flafla2, iq, Leon and certainly everyone else <3

#define VOLUME 0.001
#define PI 3.14159

float Vignette(vec2 uv, float force)
{
    return force - length(uv);
}

////////////////////////////////////////////////////////////////////////////////
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float uSDF(float s1, float s2) { return min(s1, s2);}

float sSDF( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdOctahedron( in vec3 p, in float s)
{
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdIce(vec3 pos)
{
    float t = 0.0;
    
    vec3 icePos = pos * vec3(1.5, 1.0, 1.5);
    t = sdOctahedron(icePos, 1.0);
    icePos = pos * vec3(1.5, .7, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(0.3, 0.0, 0.0), 1.0));
    icePos = pos * vec3(1.6, .6, 1.3);
    t = uSDF(t, sdOctahedron(icePos+vec3(-0.4, 0.0, 0.1), .9));
    icePos = pos * vec3(1.2, 1.1, 1.7);
    t = uSDF(t, sdOctahedron(icePos+vec3(-0.1, 0.0, -0.7), .9));
    icePos = pos * vec3(1.5, 1.5, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(1.0, 0.0, 0.0), 1.0));
    icePos = pos * vec3(1.5, 1.0, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(-1.0, 0.0, 0.0), 1.0));
    icePos = pos * vec3(1.5, 1.2, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(0.0, 0.0, 1.0), 1.0));
    icePos = pos * vec3(1.5, 1.3, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(0.0, 0.0, -1.0), 1.0));
    icePos = pos * vec3(1.5, 2.1, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(1.0, 0.0, -1.0), 1.0));
    icePos = pos * vec3(1.5, 1.2, 1.5);
    t = uSDF(t, sdOctahedron(icePos+vec3(-1.0, 0.0, -1.0), 1.0));
    icePos = pos * vec3(1.5, 0.8, 1.3);
    t = uSDF(t, sdOctahedron(icePos+vec3(-1.0, 0.0, 1.0), 1.0));
    icePos = pos * vec3(1.4, 0.9, 1.7);
    t = uSDF(t, sdOctahedron(icePos+vec3(1.0, 0.0, 1.0), 1.0)); 
    
    return t;
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float sdTorus( vec3 p, vec2 t )
{
    p.zy *= rot(PI/2.0);
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec2 map(vec3 pos)
{
    float t = 0.0;
    
    pos.xz *= rot(PI/-14.0);
    pos.xy *= rot(PI/8.0+sin(time*1.)*.3-0.3);
    
    t = pos.y, 0.0;
    
    t = uSDF(t, sdIce(pos));
    
    vec3 sPos = pos + vec3(0.0, 0.0, 0.0);
    float sp = sdVerticalCapsule(sPos, 1.0, 1.0);
    
    t = opIntersection(t, sp);
    
    vec2 tm = vec2(0.0);
    
    tm = vec2(t, 0.0);
    
    vec3 eyeP = pos + vec3(-0.3, 0.0, -1.0);
    vec2 eyeL = vec2(sdSphere(eyeP, .05), 1.0);
    vec3 brightP = eyeP + vec3(0.02, -0.03, -0.03);
    vec2 brightL = vec2(sdSphere(brightP, .02), 2.0);
    
    eyeP = pos + vec3(0.3, 0.0, -1.0);
    vec2 eyeR = vec2(sdSphere(eyeP, .05), 1.0);
    brightP = eyeP + vec3(0.02, -0.03, -0.03);
    vec2 brightR = vec2(sdSphere(brightP, .02), 2.0);
    
    
    vec3 smileP = pos + vec3(0.0, 0.2, -1.0);
    float circle = sdTorus(smileP, vec2(0.1, 0.03));
    float circleSub = sdSphere(smileP+vec3(0.0, -0.1, 0.0), .12);
    vec2 smile = vec2(sSDF(circleSub, circle), 1.0);
    
    vec3 patteP = pos + vec3(0.2, 0.5, -1.0);
    patteP.zy *= rot(PI/2.0);
    patteP.xy *= rot(PI/-8.0);
    vec2 patteL = vec2(sdVerticalCapsule(patteP, .8, .05), 1.0);
    
    vec3 papatteP = patteP + vec3(0.0, -.8, .3);
    papatteP.zy *= rot(PI/2.0);
    vec2 papatteL = vec2(sdVerticalCapsule(papatteP, .3, .05), 1.0);
    
    patteP = pos + vec3(-0.2, 0.5, -1.0);
    patteP.zy *= rot(PI/2.0);
    patteP.xy *= rot(PI/8.0);
    vec2 patteR = vec2(sdVerticalCapsule(patteP, .8, .05), 1.0);
    
    papatteP = patteP + vec3(0.0, -.8, .3);
    papatteP.zy *= rot(PI/2.0);
    vec2 papatteR = vec2(sdVerticalCapsule(papatteP, .3, .05), 1.0);
    
    
    
    tm = opU(tm, eyeL);
    tm = opU(tm, brightL);
    tm = opU(tm, eyeR);
    tm = opU(tm, brightR);
    tm = opU(tm, smile);
    tm = opU(tm, patteL);
    tm = opU(tm, patteR);
    tm = opU(tm, papatteL);
    tm = opU(tm, papatteR);
    
    return tm;
}

vec2 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<64 ; i++)
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

float GetShadow (vec3 pos, vec3 at, float k) {
    vec3 dir = normalize(at - pos);
    float maxt = length(at - pos);
    float f = 01.;
    float t = VOLUME*50.;
    for (float i = 0.; i <= 10.0; i += .1) {
        float dist = map(pos + dir * t).x;
        if (dist < VOLUME) return 0.;
        f = min(f, k * dist / t);
        t += dist;
        if (t >= maxt) break;
    }
    return f;
}

vec3 GetNormal (vec3 p)
{ 
    vec2 e = vec2(0.01, 0.0); 
    return normalize(vec3(
        map(p+e.xyy).x - map(p-e.xyy).x,
        map(p+e.yxy).x - map(p-e.yxy).x,
        map(p+e.yyx).x - map(p-e.yyx).x
        ));
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv)
{
    vec2 t = CastRay(ro, rd);
    vec3 pos = ro + rd * t.x;
    vec3 col = vec3(0.0);
    
    if(t.x == -1.0)
    {
        vec2 vignetteUV = uv;
        vignetteUV.y -= 0.2;
        col = vec3(1.0 - length(vignetteUV))*.3;
        
        
    }
    else
    {
        vec3 N = GetNormal(ro+rd*t.x);
        vec3 L = vec3(-1.0, 1.0, -0.5);
        float light = dot(N,L);
        vec3 dir = pos - rd;
        float rim = dot(N, dir) * (.1 + sin(time*5.)*.02);
        float shade = GetShadow(pos, L, 4.0);
        
        if(t.y == 0.0) // ice
        {
            col = vec3(0.0, .5, .5+sin(time*10.)*0.01) + vec3(light)*.2;
            col += vec3(rim);
            col = mix(col, vec3(0.0, 0.0, .5), -uv.y) * .7;
        }
        else if(t.y == 1.0) // cute black things
        {
            col = vec3(0.0);
        }
        else if(t.y == 2.0)
        {
            col = vec3(1.0);
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
    
    float time = time * .2;
    
    vec3 cp = vec3(sin(time)*.5, 1.0+sin(time)*.3, 5.0+sin(time)*.4);
    vec3 ct = vec3(-0.2, 0.0, 0.0);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec3 col = vec3(length(uv));
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    col = Render(cp, vd, uv);
    
    // compo
    col *= Vignette(uv, 2.0);
    col.b -= screenUV.y*.2;
    

    
    glFragColor = vec4(col,1.0);
}
