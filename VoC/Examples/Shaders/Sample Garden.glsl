#version 420

//--- garden
// by Catzpaw 2018

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCT 24
#define ITER 64
#define EPS -.5
#define NEAR 2.
#define FAR 3.

vec3 rotX(vec3 p,float a){return vec3(p.x,p.y*cos(a)-p.z*sin(a),p.y*sin(a)+p.z*cos(a));}
vec3 rotY(vec3 p,float a){return vec3(p.x*cos(a)-p.z*sin(a),p.y,p.x*sin(a)+p.z*cos(a));}
vec3 rotZ(vec3 p,float a){return vec3(p.x*cos(a)-p.y*sin(a), p.x*sin(a)+p.y*cos(a), p.z);}
vec3 hsv(float h,float s,float v){return ((clamp(abs(fract(h+vec3(0.,.666,.333))*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;}

float map(vec3 p){
    float s=.98,df=1.;
    p=rotX(p,time*.17);p=rotY(p,time*.13);p+=1.;
    for(int i=0;i<OCT;i++){
        if(p.x>1.){p.x=2.-p.x;}else if(p.x<-1.){p.x=-2.-p.x;}
        if(p.y>1.){p.y=2.-p.y;}else if(p.y<-1.){p.y=-2.-p.y;}
        if(p.z>1.){p.z=2.-p.z;}else if(p.z<-1.){p.z=-2.-p.z;}
        float q=p.x*p.x+p.y*p.y+p.z*p.z;
        if(q<.25){p*=4.;df*=3.;}else if(q<1.){p*=1./q;df*=.9/q;}
        p*=s;p+=.2;df*=s;        
    }
    return (length(p)-1.5)/df;
}

float trace(vec3 ro,vec3 rd,out float n){float t=NEAR,d;
    for(int i=0;i<ITER;i++){d=map(ro+rd*t);if(abs(d)<EPS||t>FAR)break;t+=step(d,1.)*d*.2+d*.5;n+=1.;}
    return min(t,FAR);}

void main(void){
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float n=0.,v=trace(vec3(.0,-1.,0),vec3(uv,-.7),n)*.3;n/=float(ITER);
    glFragColor=vec4(mix(hsv(v+time*.05,.5,n),vec3(1),n),1);
}
