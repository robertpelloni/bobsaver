#version 420

// original https://www.shadertoy.com/view/tt3yW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define USE_MOUSE 0
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdVesica3D(vec3 p, float r, float h, float d ) {
    p.x = abs(p.x);
    p.x+=d;
    return sdCappedCylinder(p,r,h);
}

vec4 GetDist(vec3 p) {
    float t = time*1.1;
    p*=matRotateX(radians(90.0));
    vec3 prevP = p;
    float _floor = p.y;

    float y = 1.0;
    
    vec3 pos = vec3(0.0,0.0,-y);
    
    p+=pos;
    p*=matRotateY(radians(30.0*t))*matRotateZ(radians(20.0*t));
    
    p.xz = DF(vec2(p.x,p.z),4.0);
    p.xz = abs(p.xz);
    p.xz -= vec2(0.6);
    
    float d = sdVesica3D(p*matRotateY(radians(45.0)),0.3,0.05,0.2);

    p = prevP;
    p+=pos;
    p*=matRotateY(radians(20.0*t));
    p.xz = DF(vec2(p.x,p.z),8.0);
    p.xz = abs(p.xz);
    p.xz -= vec2(1.2);
    
    float d2 = sdVesica3D(p*matRotateY(radians(45.0)),0.3,0.05,0.2);

    p = prevP;
    p+=pos;
    p*=matRotateY(radians(25.0*t));
    p.xz = DF(vec2(p.x,p.z),16.0);
    p.xz = abs(p.xz);
    p.xz -= vec2(1.8);
    
    float d3 = sdVesica3D(p*matRotateY(radians(45.0)),0.3,0.05,0.2);
    
    p = prevP;
    p+=pos;
     p*=matRotateY(radians(30.0*-t));
    p.xz = DF(vec2(p.x,p.z),12.0);
    p.xz = abs(p.xz);
    p.xz -= vec2(1.5);
    
    float d4 = length(p)-0.1;
        
    p = prevP;
    p+=pos;
    p*=matRotateY(radians(30.0*-t))*matRotateZ(radians(40.0*-t));
    p.xz = DF(vec2(p.x,p.z),6.0);
    p.xz = abs(p.xz);
    p.xz -= vec2(0.9);
    
    float d5 = length(p)-0.1;
    
    vec3 col = 0.5 + 0.5*cos(time+p.xyz+vec3(0,1,2));
    vec4 res = vec4(col,min(d,min(d2,min(d3,min(d4,d5)))));
        
    vec4 model = res;
    return model;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 dO= vec4(0.0);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO.w;
        vec4 dS = GetDist(p);
        dO.w += dS.w;
        dO.xyz = dS.xyz;
        if(dO.w>MAX_DIST || dS.w<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).w;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).w,
        GetDist(p-e.yxy).w,
        GetDist(p-e.yyx).w);
    
    return normalize(n);
}

vec2 GetLight(vec3 p) {
    vec3 lightPos = vec3(2,5,3);
    
    lightPos.yz *= Rot(radians(-60.0));
    lightPos.xz *= Rot(time*.3+1.0);
    
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l).w;
    
    float lambert = max(.0, dot( n, l))*0.6;
    
    return vec2((lambert+dif),max(0.9, 1.0)) ;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
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
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 4, -5);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    ro.yz *= Rot(radians(-60.0));
    ro.xz *= Rot(time*.3+1.0);
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,1,0), 1.);

    vec4 d = RayMarch(ro, rd);
    
    if(d.w<MAX_DIST) {
        vec3 p = ro + rd * d.w;
    
        vec2 dif = GetLight(p);
        col = vec3(dif.x)*d.xyz;
        col *= dif.y;
        
    } else {
        // background
        col = vec3(1.0);
    }
    
    glFragColor = vec4(col,1.0);
}
