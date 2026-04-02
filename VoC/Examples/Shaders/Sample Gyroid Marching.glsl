#version 420

// original https://www.shadertoy.com/view/7dSGRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 64
#define MAX_DIST 64.0
#define EPS 0.0001

mat2 Rot(float a){
    float s=sin(a);
    float c=cos(a);
    return mat2(c,-s,s,c);
}

float sdSphere(vec3 p){
    return length(p)-0.9;
}

float sdGyroid(vec3 p,float scale,float tickness){
    p*=scale;
    return abs(dot(sin(p),cos(p.zxy))-1.0)/scale-tickness;
}

float GetDist(vec3 p){
    p=mod(p,2.0)-1.0;

    p.xy*=Rot(time);
    p.yz*=Rot(time);

    float sphere=sdSphere(p);
    float gyroid=sdGyroid(p,8.0-sin(time),0.09);
    float d=max(sphere,gyroid);

    return d;
}

float RayMarch(vec3 ro,vec3 rd){
    float dO=0.0;

    for(int i=0;i<MAX_STEPS;i++){
        vec3 p=ro+rd*dO;
        float dS=GetDist(p);
        dO+=dS;
        if(dS<EPS)break;
    }
    return dO;
}

vec3 GetNormal(vec3 p){
    float d=GetDist(p);
    vec2 e=vec2(EPS,0.0);

    vec3 n=d-vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    return normalize(n);
}

vec3 GetRayDir(vec2 uv,vec3 p,vec3 l,float z){
    vec3 f=normalize(l-p);
    vec3 r=normalize(cross(vec3(0.0,1.0,0.0),f));
    vec3 u=cross(f,r);
    vec3 c=f*z;
    vec3 i=c+uv.x*r+uv.y*u;
    vec3 d=normalize(i);
    return d;
}

void main(void) {
    vec2 uv=(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 ro=vec3(0.0,0.0,-time);
    //vec3 rd=GetRayDir(uv,ro,vec3(0.0),1.0);

    vec3 rd=normalize(vec3(uv,(1.0-dot(uv,uv)*0.5)*0.5));//fish eye

    rd.xy*=Rot(time*0.5);
    rd.yz*=Rot(time*0.5);

    vec3 col=vec3(0.0);
    float d=RayMarch(ro,rd);
    vec3 n;

    if(d<MAX_DIST){
        vec3 p=ro+rd*d;
        n=GetNormal(p);
        vec3 r=reflect(rd,n);
        
    }
    
    glFragColor=vec4(n*0.5+0.5,1.0);
}
