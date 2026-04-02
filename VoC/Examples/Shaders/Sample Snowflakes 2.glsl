#version 420

//--- rikka
// by Catzpaw 2019

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCT 3
#define ITER 128
#define EPS 0.001
#define NEAR 0.
#define FAR 10.0

float hash(float v){return fract(sin(v*22.9)*67.);}
mat2 rotate(float a){float s=sin(a),c=cos(a);return mat2(c,s,-s,c);}
vec2 foldRotate(vec2 p){float a=.5236-atan(p.x,p.y),n=1.0472;a=floor(a/n)*n;return p*rotate(a);}
float dHex(vec3 p){p.xy*=rotate(.5236);p=abs(p);return max(p.z-.01,max((p.x*.866+p.y*.5),p.y)-.04);}

float map(vec3 p){float h=hash(floor(p.x)+floor(p.y)*133.3+floor(p.z)*166.6),o=FAR;
    vec3 q=fract(p)-.5;q.xz*=rotate(time*(h+.5));q.yz*=rotate(time+h*5.);
    for(int i=0;i<OCT;i++){q.xy=foldRotate(q.xy);
        h=hash(h);q.x*=(2.-h);h=hash(h);q.y-=h*.11;q.y*=.9;h=hash(h);q*=.8+h;o=min(o,dHex(q));}
    return o;}

float trace(vec3 ro,vec3 rd,out float c,out vec3 n){float t=NEAR,d;vec3 p;vec2 e=vec2(.1,-.1);
    for(int i=0;i<ITER;i++){p=ro+rd*t;d=map(p);if(abs(d)<EPS||t>FAR)break;t+=step(d,2.)*d*.5+d*.1;c+=1.;}
    n=normalize(e.xyy*map(p+e.xyy*EPS)+e.yyx*map(p+e.yyx*EPS)+e.yxy*map(p+e.yxy*EPS)+e.xxx*map(p+e.xxx*EPS));
    return min(t,FAR);}

void main(void){
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;vec3 r,n;
    float c=0.,v=trace(vec3(0,time*.5,-1.2),vec3(uv,.6),c,n)*.3;c/=float(ITER);
    float s=pow(clamp(dot(n,vec3(0,0,-1)),0.,1.),3.);
    glFragColor=vec4(vec3(1.-v*.7)+s,1);
}
