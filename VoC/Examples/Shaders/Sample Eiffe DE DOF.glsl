#version 420

//original https://www.shadertoy.com/view/MsBGRh

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// DE DOF by eiffie
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// This is an example of calculating DOF based on distance estimates. The idea of
// gathering samples any time you are within the circle of confusion came from IQ.
// The implementation is as simple as I could make it. The surface is treated like
// a cloud density so the DOF can "see around" the edges of objects by stepping thru them.
// There are several problems with this though:
// It is very expensive if you are doing shadow marchs/reflections with each step.
// Distance estimates are quite bad at large distances so banding occurs - to remove
// the banding I added random jitter at each step (you must add jitter each time you come
// close to the surface as it re-aligns the steps of adjacent pixels).
// It could be improved if you took 1 sample within the CoC. (not sure where??)
// Also it would be nice to have a method that finds the nearest point on a ray to a
// distance estimate. (anyone??? just taking the nearest march step sucks!)
// But still a nice trick for Shadertoy! 

const float aperature=20.0,focalDistance=1.5;//play with these to test the DOF

#define size resolution

#define TAO 6.283
void Rotate(inout vec2 v, float angle){v=cos(angle)*v+sin(angle)*vec2(v.y,-v.x);}
void Kaleido(inout vec2 v,float power){Rotate(v,floor(.5+atan(v.x,-v.y)*power/TAO)*TAO/power);}
float HTorus(in vec3 z, float radius1, float radius2){return max(-z.y,length(vec2(length(z.xy)-radius1,z.z))-radius2-z.x*0.035);}

vec3 mcol;
float dB;
float DE(in vec3 z0){
    vec4 z=vec4(z0,1.0);
    float d=max(abs(z.y+1.0)-1.0,length(z.xz)-0.13);
    for(int i=0;i<4;i++){
        Kaleido(z.xz,3.0);
        z.z+=1.0;
        d=min(d,HTorus(z.zyx,1.0,0.1)/z.w);
        z.z+=1.0;
        z*=vec4(2.0,-2.0,2.0,2.0);
    }
    z.z-=0.8;
    dB=(length(z.xyz)-1.0)/z.w;
    return min(d,dB);
}
float CE(in vec3 z0){//same but also colors
    float d=DE(z0);
    if(abs(d-dB)<0.001)mcol+=vec3(1.0,1.0-abs(sin(z0.x*100.0)),0.0);
    else mcol+=vec3(0.0,abs(sin(z0.z*40.0)),1.0);
    return d+abs(sin(z0.y*100.0))*0.005;//just giving the surface some procedural texture
}
float rand(vec2 co){// implementation found at: lumina.sourceforge.net/Tutorials/Noise.html
    return fract(sin(dot(co*0.123,vec2(12.9898,78.233))) * 43758.5453);
}
float CircleOfConfusion(float t){//calculates the radius of the circle of confusion at length t
    return (focalDistance+aperature*abs(t-focalDistance))/(focalDistance*size.y);
}
mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}

void main() {
    vec3 ro=vec3(cos(time),sin(time*0.3)*0.3,sin(time))*2.4;//camera setup
    vec3 L=normalize(ro+vec3(0.5,2.5,-0.5));
    vec3 rd=lookat(-ro*vec3(1.0,2.0,1.0)-vec3(1.0,0.0,0.0),vec3(0.0,1.0,0.0))*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,1.0));
    vec4 col=vec4(0.0);//color accumulator
    float t=0.0;//distance traveled
    for(int i=1;i<64;i++){//march loop
        if(col.w>0.9 || t>10.0)continue;//bail if we hit a surface or go out of bounds
        float d=DE(ro);
        float rCoC=CircleOfConfusion(t);//calc the radius of CoC
        if(d<rCoC){//if we are inside add its contribution
            mcol=vec3(0.0);//clear the color trap, collecting color samples with normal deltas
            vec2 v=vec2(rCoC*0.333,0.0);//use normal deltas based on CoC radius
            vec3 N=normalize(vec3(-CE(ro-v.xyy)+CE(ro+v.xyy),-CE(ro-v.yxy)+CE(ro+v.yxy),-CE(ro-v.yyx)+CE(ro+v.yyx)));
            vec3 scol=mcol*0.1666*max(0.1,0.25+dot(N,L)*0.75);//do some fast light calcs (you can forget about shadow casting, too expensive)
            scol+=pow(max(0.0,dot(reflect(rd,N),L)),8.0)*vec3(1.0,0.9,0.8);//todo: adjust this for bokeh highlights????
            float alpha=(1.0-col.w)*smoothstep(-rCoC,rCoC,-d);//calculate the mix like cloud density
            col+=vec4(scol*alpha,alpha);//blend in the new color
        }
        d=abs(d)*rand(gl_FragCoord.xy*vec2(i))+0.005;//add in noise to reduce banding and create fuzz
        ro+=d*rd;//march
        t+=d;
    }//mix in background color
    vec3 scol=mix(vec3(0.0,0.2,0.1),vec3(0.4,0.5,0.6),smoothstep(0.0,0.1,rd.y));
    col.rgb+=scol*(1.0-clamp(col.w,0.0,1.0));//mix(vec3(0.0,0.2,0.1),col.rgb,clamp(col.a,0.0,1.0));
    glFragColor = vec4(clamp(col.rgb,0.0,1.0),1.0);
}
