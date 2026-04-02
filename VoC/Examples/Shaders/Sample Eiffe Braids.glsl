#version 420

//original https://www.shadertoy.com/view/4dBGR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Braids by eiffie
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Inspired by gaz's way of doing a helix https://www.shadertoy.com/view/MsjGRV

#define size resolution

float focalDistance,pixelSize,FudgeFactor=0.75;
const float aperture=0.01;
vec3 L;
vec3 mcol=vec3(1.0);
float timer;
const float WoT=30.0/6.2831853;
float DE(in vec3 p)
{    
    p.x=abs(p.x)-6.0+p.y*p.y*timer*0.01;
    float d=100.0,a=p.y;
    for(int i=0;i<3;i++){
        vec2 v=p.xz-vec2(cos(a),sin(a*2.0)*0.5);
        float r=length(v)-0.4;
        float b=atan(v.y,v.x);
        v=vec2(r,0.06*(fract((a+b)*WoT)-0.5));
        d=min(d,length(v)-0.05);
        a+=2.0944;//TAO/3
    }
    return d;
}

float CircleOfConfusion(float t){//calculates the radius of the circle of confusion at length t
    return max(abs(focalDistance-t)*aperture,pixelSize*(1.0+t));
}
mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}
float linstep(float a, float b, float t){return clamp((t-a)/(b-a),0.,1.);}// i got this from knighty
//random seed and generator
float randSeed,GoldenAngle;
float randStep(){//a simple pseudo random number generator based on iq's hash
    randSeed=fract(randSeed+GoldenAngle);
    return  (0.8+0.2*randSeed);
}
float FuzzyShadow(vec3 ro, vec3 rd, float coneGrad, float rCoC){
    float t=0.0,d,s=1.0,r;
    ro+=rd*rCoC*2.0;
    for(int i=0;i<12;i++){
        r=rCoC+t*coneGrad;d=DE(ro+rd*t)+r*0.5;s*=linstep(-r,r,d);t+=abs(d)*randStep();
    }
    return clamp(s,0.0,1.0);
}
vec3 Background(vec3 rd){return vec3(0.0);}

void main() {
    timer=sin(time+sin(time));
    GoldenAngle=2.0-0.5*(1.0+sqrt(5.0));
    randSeed=fract(sin(dot(gl_FragCoord.xy,vec2(13.434,77.2378))+time)*41323.34526);
    pixelSize=4.0/size.y;
    vec3 ro=vec3(0.0,0.0,-10.0);
    vec3 rd=lookat(vec3(timer,-3.0,0.0)-ro,vec3(-0.1*timer,1.0,0.0))*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,1.75));
    focalDistance=10.0;
    L=normalize(vec3(0.5,0.6,-0.1));
    vec4 col=vec4(0.0);//color accumulator
    float t=10.0;//distance traveled
    ro+=rd*t;
    for(int i=0;i<30;i++){//march loop
        if(col.w<0.99 && t<20.0){
        float rCoC=CircleOfConfusion(t);//calc the radius of CoC
        float d=DE(ro);
        if(d<rCoC){//if we are inside add its contribution
            vec2 v=vec2(rCoC*0.1,0.0);//use normal deltas based on CoC radius
            //vec3 N=normalize(vec3(-DE(ro-v.xyy)+DE(ro+v.xyy),-DE(ro-v.yxy)+DE(ro+v.yxy),-DE(ro-v.yyx)+DE(ro+v.yyx)));
            vec3 N=normalize(vec3(DE(ro+v.xyy),DE(ro+v.yxy),DE(ro+v.yyx))-vec3(d));
            if(N!=N)N=-rd;
            vec3 scol=vec3(1.0,1.0,0.8+dot(N,rd)*0.5)*mcol*(0.5+0.5*dot(N,L));
            scol+=vec3(1.0,0.0,0.0)*pow(max(0.0,dot(L,reflect(rd,N))),20.0); 
            scol*=FuzzyShadow(ro,L,0.5,rCoC);
            float alpha=FudgeFactor*(1.0-col.w)*linstep(-rCoC,rCoC,-d);//calculate the mix like cloud density
            col+=vec4(scol*alpha,alpha);//blend in the new color    
        }
        d=abs(d)*randStep()*FudgeFactor;//add in noise to reduce banding and create fuzz
        ro+=d*rd;//march
        t+=d;
        }
    }//mix in background color
    col.rgb=mix(Background(rd),col.rgb,clamp(col.w,0.0,1.0));

    glFragColor = vec4(clamp(col.rgb,0.0,1.0),1.0);
}
