#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(float x){
  return fract(sin(dot(vec2(x) ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand(vec3 v){
  return fract(sin(dot(vec2(v.x+v.y,v.y+v.z) ,vec2(12.9898,78.233))) * 43758.5453);
}
vec3 pos;

float noise(vec3 a){
    a=vec3(a.x-time,a.y+time,a.z+time);
    vec3 fr=fract(a);
    vec3 fl=floor(a);
    return mix(
    mix(mix(rand(vec3(fl.x,fl.y,fl.z)),rand(vec3(fl.x+1.0,fl.y,fl.z)),fr.x),
    mix(rand(vec3(fl.x,fl.y,fl.z+1.0)),rand(vec3(fl.x+1.0,fl.y,fl.z+1.0)),fr.x),fr.z),
    mix(mix(rand(vec3(fl.x,fl.y+1.0,fl.z)),rand(vec3(fl.x+1.0,fl.y+1.0,fl.z)),fr.x),
    mix(rand(vec3(fl.x,fl.y+1.0,fl.z+1.0)),rand(vec3(fl.x+1.0,fl.y+1.0,fl.z+1.0)),fr.x),fr.z)
    ,fr.y);
}

vec3 rotateY(in vec3 v, in float a) {
    return vec3(cos(a)*v.x + sin(a)*v.z, v.y,-sin(a)*v.x + cos(a)*v.z);
}

vec3 rotateX(in vec3 v, in float a) {
    return vec3(v.x,cos(a)*v.y + sin(a)*v.z,-sin(a)*v.y + cos(a)*v.z);
}

float dToBox(vec3 p,vec3 bP,float bR){
    p=abs(p-bP);
    float a= max(p.x,max(p.y,p.z))-bR;
    float b= min(p.y,max(p.z,p.x))-bR;
    return min(a,b)-0.15*(noise(7.0*vec3(pos.xy,pos.z-fract(time)+time))-0.2);
}

float dToCircle(vec3 p,vec3 cP,float r){
    return length(p-cP)-r;
}

float scene(vec3 p){
    //float circle=dToCircle(p,vec3(0.5),0.2-0.1*sin(time));
    float box=dToBox(p,vec3(0.5,0.5,0.5),0.04);
    //return min(box,circle);
    return box;
}

#define MAX 100

vec3 noise3d(vec3 a){
    vec3 fr=fract(a);
    vec3 fl=floor(a);
    return mix(
    mix(mix(vec3(rand(fl.x),rand(fl.y),rand(fl.z)),vec3(rand(fl.x+1.0),rand(fl.y),rand(fl.z)),fr.x),
    mix(vec3(rand(fl.x),rand(fl.y),rand(fl.z+1.0)),vec3(rand(fl.x+1.0),rand(fl.y),rand(fl.z+1.0)),fr.x),fr.z),
    mix(mix(vec3(rand(fl.x),rand(fl.y+1.0),rand(fl.z)),vec3(rand(fl.x+1.0),rand(fl.y+1.0),rand(fl.z)),fr.x),
    mix(vec3(rand(fl.x),rand(fl.y+1.0),rand(fl.z+1.0)),vec3(rand(fl.x+1.0),rand(fl.y+1.0),rand(fl.z+1.0)),fr.x),fr.z)
    ,fr.y);
}

void main( void ) {
    vec2 uv=gl_FragCoord.xy/resolution-0.5;
    uv.x*=resolution.x/resolution.y;
    pos=vec3(0,0,fract(time));
    vec3 r=normalize(vec3(uv,0.5));
    r=rotateX(r,4.0*(mouse.y-0.5));
    r=rotateY(r,4.0*(mouse.x-0.5));
    float j=0.0;
    float iter=0.0;
    float dist=0.0;
    for(int i=0;i<MAX;i++){
        dist+=j=scene(fract(pos));
        if(j<0.0001){
            break;
        }
        pos+=j*r;
        iter++;
    }
    vec4 color=vec4(noise3d(vec3(pos.xy,pos.z-fract(time)+time)),1.0);
    glFragColor= color*(1.0-iter/float(MAX));
    
}
