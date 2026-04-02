#version 420

// original https://www.shadertoy.com/view/WdfczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Base code:
///// "RayMarching starting point" 
//// by Martijn Steinrucken aka BigWings/CountFrolic - 2020
//// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define MAX_STEPS 200
#define MAX_DIST 10.
#define SURF_DIST .001

#define S(a, b, t) smoothstep(a, b, t)
#define M(x, y, a) mix(x, y, a) 

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdLine(vec3 p, vec3 o, vec3 dir, float t) {
    vec3 a = o;
    vec3 b = a+dir;
    vec3 bMinusA = b-a;
    float h = min(t, max(-t, dot((p-a), bMinusA)/dot(bMinusA,bMinusA)));
    //float h = dot(p-a, bMinusA)/dot(bMinusA,bMinusA);
    float dist = length(p - a +-(b-a) * h )- 0.05;
    return dist;
}

mat3 rx(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(1,0,0,0,c,-s,0,s,c);
}
mat3 ry(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(c,0,s,0,1,0,-s,0,c);
}
mat3 rz(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float smoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

vec4 sdTorus(vec3 p, vec2 t) {
    p-=0.5;
    p = rx(3.*sin(time*1.0244)) * p;
    p = ry(2.72*sin(325.+time*1.79)) * p;
    p = rz(1.35*sin(12.4+time*0.984)) * p;
    p += vec3(sin(time/5.), cos(time/7.), sin(cos(time/8.)))/3.;
    vec2 q = vec2(length(p.xz)-t.x,p.y);
     
    
    return vec4(length(q)-t.y, 0.4, max(0., .9*sin(time)*sin(time)), max(0., .9*sin(time)*sin(time)));
}

vec4 grid(vec3 p) {
    vec3 pp = mod(p+1.,3.)-1.;
    float dist = MAX_DIST;
    float x =0.5, y=0.5, z = 0.5;
    float t1 = .5+0.5*sin(time);
    float t2 = .5+0.5*cos(time*2.);
    float t3 = .5+0.5*sin(3.*time+3.141592);
    dist = smoothUnion(dist, sdLine(pp, vec3(x,y,z), vec3(1,0,0), MAX_DIST), 0.1);
    dist = smoothUnion(dist, sdLine(pp, vec3(x,y,z), vec3(0,1,0), MAX_DIST), 0.1);
    dist = smoothUnion(dist, sdLine(pp, vec3(x,y,z), vec3(0,0,1), MAX_DIST), 0.1);

    
    if (dist >= MAX_DIST) {
    return vec4(dist, .00001, .00001, .00001);
    }
    return vec4(dist, max(0.,max(0.,.9*sin(time)*sin(time))), .04, .02);
}

vec4 GetDist(vec3 p) {
    vec4 distCol;
    vec4 distGrid = grid(p);
    vec4 distTorus = sdTorus(p, vec2(0.5, 0.2));
    float newDist = smoothUnion(distGrid.x, distTorus.x, 0.7+0.3*sin(time));
    vec3 newCol = M(distGrid.yzw, distTorus.yzw, clamp(0.,1., distGrid.x/distTorus.x));
    return vec4(newDist, newCol.x, newCol.y, newCol.z);
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 dCol = vec4(0.);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dCol.x;
        vec4 dS = GetDist(p);
        dCol.x += dS.x;
        dCol.yzw = dS.yzw;
        if(dCol.x>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }
    
    return dCol;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col = vec3(.00001);
    
    vec3 ro = 3.*vec3(cos(time/2.), sin(time/3.), -sin(cos(time)));
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0.5), 1.);

    vec4 d = RayMarch(ro, rd);
        
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        
        float dif = clamp(dot(n, normalize(vec3(1,2,3)))*.5+.5, 0.2, 0.8);
        col = vec3(dif)*d.yzw;
        col = d.yzw;
        col *= 0.5+0.5*n.y;
        col = M(col, vec3(0.), S(1.,10.,d.x));
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
