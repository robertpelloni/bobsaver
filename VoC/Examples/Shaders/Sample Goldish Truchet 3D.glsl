#version 420

// original https://www.shadertoy.com/view/fdlXz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define USE_MOUSE 0
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .005
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)

float sdPie3d(vec3 p, float rad, float r, float h) {
    p.xy = abs(p.xy);
    vec2 c = vec2(sin(rad),cos(rad));
    float d = max(p.y-h,length(p.xz) - r);
    float m = length(p.xz-c*clamp(dot(p.xz,c),0.0,r)); 
    return max(d,m*sign(c.y*p.x-c.x*p.z));
}

float pattern(vec3 p) {
    vec3 prevP = p;
    float r = 1.135;
    float h = 0.1;
    float rad = radians(-45.0);
    p*=matRotateY(radians(45.0));
    
    p.z*=-1.0;
    p.z=abs(p.z);
    p.z-=1.415;
    
    float d = sdPie3d(p,rad,r,h);
    float d2 = sdPie3d(p,radians(180.),r*0.75,h+0.02);
    d = max(-d2+0.01,d);

    return d;
}

vec4 GetDist(vec3 p) {
    
    p.z-=time*1.1;
    vec2 id = floor(p.xz*0.5);
    p.xz = mod(p.xz,2.0)-1.0;

    vec2 randP = fract(sin(id*123.456)*567.89);
    randP += dot(randP,randP*34.56);
    float rand = fract(randP.x*randP.y);
    
    float speed = 1.5;
    if(rand<0.5) {
        p.z*=-1.0;
        speed = 1.0;
    }
    
    float d = pattern(p);
    
    p.x-=time*speed;
    p.x = mod(p.x,4.0)-2.0;
    
    float shine = length(p.xy)-0.05;
    shine = 1.0-smoothstep(-0.1,0.1,shine);
    vec4 res = vec4(vec3(1.0)*shine,d);

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
    vec3 lightPos = vec3(2,5,-3);
    
    lightPos.yz *= Rot(radians(-30.0));
    lightPos.xz *= Rot(time*1.5+1.0);
    
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

vec3 Bg(vec3 rd) {
    float k = rd.y*0.5+0.5;
    vec3 col = mix(vec3(.3,.3,.3),vec3(1.0,.7,.0),k);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 3, -10);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    ro.yz *= Rot(radians(30.0));
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,0,0), 1.);

    vec4 d = RayMarch(ro, rd);
    
    if(d.w<MAX_DIST) {
        vec3 p = ro + rd * d.w;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd,n);
        float spec = pow(max(0.0,r.y),30.);
        float dif = dot(n,normalize(vec3(1,2,3)))*0.5+0.5;
        col = mix(Bg(r),vec3(dif),0.5)+spec;
        col += d.rgb;
    } else {
        // background
        col += Bg(rd);
    }
    
    glFragColor = vec4(col,1.0);
}
