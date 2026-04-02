#version 420

//--- mandala
// by Catzpaw 2018

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCT 4
#define ITER 64
#define EPS 0.00427
#define NEAR .5
#define FAR 50.

vec3 hsv2rgb(vec3 c){return ((clamp(abs(fract(c.x+vec3(0.,.7,.3))*7.-3.)-1.,0.,1.)-1.)*c.y+1.)*c.z;}

float map(vec3 p){float d=0.,s=8.;p+=1.;
    for(int i=0;i<OCT;i++){d=max(s*.590-length((fract(p/s)-.5)*s*.8455),d);s/=6.;}
    return d;}

float trace(vec3 ro,vec3 rd,out float n){float t=NEAR,d;
    for(int i=0;i<ITER;i++){d=map(ro+rd*t);if(abs(d)<EPS||t>FAR)break;t+=step(d,1.)*d*.2+d*.5;n+=1.;}
    return min(t,FAR);}

void main(void){
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y; uv *= 2.5;
    float n=0.,a=sin(time*.05)*3.,s=sin(a),c=cos(a);uv*=mat2(c,s,-s,c);
    float v=1.-trace(vec3(1.+sin(time*0.29)*.9,1.+sin(time*.127)*.5,1.-(time*0.927)),vec3(uv,-.5),n)/FAR;
    n/=float(ITER);
    glFragColor=vec4(mix(vec3(1),mix(hsv2rgb(vec3(0.5)),vec3(0),v),n)*v,1);
}
