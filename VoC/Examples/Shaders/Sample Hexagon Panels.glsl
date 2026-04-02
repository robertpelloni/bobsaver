#version 420

//--- hexagon panels
// by Catzpaw 2017

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER 128
#define EPS 0.01
#define NEAR 0.13
#define FAR 40.

vec3 hsv2rgb(vec3 hsv){return ((clamp(abs(fract(hsv.x+vec3(0.,2.,1.)/3.)*6.-3.)-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z;}

vec3 rotX(vec3 p,float ang){float si=sin(ang),co=cos(ang);return vec3(p.x,p.y*co-p.z*si,p.y*si+p.z*co);}
vec3 rotY(vec3 p,float ang){float si=sin(ang),co=cos(ang);return vec3(p.x*co-p.z*si,p.y,p.x*si+p.z*co);}
vec3 rotZ(vec3 p,float ang){float si=sin(ang),co=cos(ang);return vec3(p.x*co-p.y*si,p.x*si+p.y*co,p.z);}

float hex(vec3 p){p=abs(p);return max(p.z-.05,max((p.x*0.87+p.y*0.5),p.y)-.7);}

float map(vec3 p){
    p=rotZ(rotX(p,time*.5),time*.57);
    vec3 q=p;q.y+=1.;q.x+=1.73;
    q.x=mod(q.x,3.46)-1.73;q.yz=mod(q.yz,2.)-1.;
    p.x=mod(p.x,3.46)-1.73;p.yz=mod(p.yz,2.)-1.;
    return min(hex(p),hex(q));
}

float trace(vec3 ro,vec3 rd){float t=NEAR,d;
    for(int i=0;i<ITER;i++){d=map(ro+rd*t);if(abs(d)<EPS||t>FAR)break;t+=step(d,1.)*d*.2+d*.5;}
    return min(t,FAR);}

void main(void){
    vec2 uv=(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    float v=1.-trace(vec3(0,0,3),vec3(uv,-.5))/FAR;
    glFragColor=vec4(hsv2rgb(vec3(v*4.,.2,v))*v,1);
}
