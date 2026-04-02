#version 420

// original https://www.shadertoy.com/view/7sjGWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS 0.001
#define POWER 8.0
#define ITR 15
#define MAX_DIST 64
#define PI 3.1415

mat2 rot(float a){
    float s=sin(a);
    float c=cos(a);
    return mat2(c,-s,s,c);
}

float mandelbulb(vec3 p){    

    float power=1.0+(POWER-1.0)*(0.5-cos(PI)*0.5);
    vec3 z=p;
    float dr=1.0;
    float r=0.0;
    for(int i=0;i<ITR;i++){
        r=length(z);
        if(r>3.0)break;

        float theta=acos(z.z/r);
        float phi=atan(z.y,z.x);

        dr=pow(r,power-1.0)*power*dr+1.0;

        float zr=pow(r,power);
        theta*=power;
        phi*=power;

        z=zr*vec3(sin(theta)*cos(phi),sin(phi)*sin(theta),cos(theta));
        z+=p;
    }
    return 0.5*log(r)*r/dr;
}

float mainDist(vec3 p){
    p.xz*=rot(time*0.5);
    p.yz*=rot(time*0.5);
    //p=mod(p,8.0)-4.0;
    
    return mandelbulb(p);
}

vec3 rayMarch(const vec3 eye,const vec3 ray,out float depth,out float steps){
    depth=0.0;
    steps=0.0;
    float dist;
    vec3 rp;

    for(int i=0;i<MAX_DIST;i++){
        rp=eye + depth*ray;
        dist = mainDist(rp);
        depth+= dist;
        steps++;
        if(dist<EPS)break;
    }
    
    return rp;
}

vec3 genNormal(vec3 p){
    return normalize(vec3(
        mainDist(vec3(p.x+EPS,p.y,p.z))-mainDist(vec3(p.x-EPS,p.y,p.z)),
        mainDist(vec3(p.x,p.y+EPS,p.z))-mainDist(vec3(p.x,p.y-EPS,p.z)),
        mainDist(vec3(p.x,p.y,p.z+EPS))-mainDist(vec3(p.x,p.y,p.z-EPS))
    ));
}

float color(float val,float offset,float level){
    return clamp((val-level)*(1.0+offset)+level,0.0,1.0);
}

void main(void) {
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ray=normalize(vec3(uv,1.0));
    
    vec3 camPos=vec3(0.0,0.0,-2.0);

    float depth=0.0;
    float steps=0.0;
    vec3 rp=rayMarch(camPos+EPS*ray,ray,depth,steps);

    
    float ao=steps*0.01;
    ao=1.0-ao/(ao+0.5);
    float offset=0.3;
    float level=0.5;
    ao=color(ao,offset,level);
    glFragColor=vec4(vec3(ao),1.0);
}
