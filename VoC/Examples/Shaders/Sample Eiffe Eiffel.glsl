#version 420

//Eiffel by eiffie (my namesake)
//THIS IS MY FRACTAL! all rights reserved haha
//it is a 4d mandelbrot (in that the formula is z=z^2+c) but with a strange multiplication table

//original https://www.shadertoy.com/view/XdX3WX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LOWQUAL

#define size resolution
float tim2;
vec4 dzc;

float DE(in vec3 z0){//hypercomplex eiffel by eiffie
    vec4 z=vec4(z0,0.0),c = z,dz=dzc;
    float r = length(z);
    for (int n = 0; n < 17; n++) {
        if(r>60.0)continue;
        dz=2.0*vec4(dz.x*z.x-dz.y*z.y-dz.z*z.z+dz.w*z.w,-dz.x*z.y-dz.y*z.x+dz.z*z.w+dz.w*z.z,-dz.x*z.z-dz.z*z.x+dz.y*z.w+dz.w*z.y,dz.x*z.w+dz.w*z.x+dz.y*z.z+dz.z*z.y)+dzc; 
        z=vec4(z.x*z.x-z.y*z.y-z.z*z.z+z.w*z.w,-2.0*(z.x*z.y-z.z*z.w),-2.0*(z.x*z.z-z.y*z.w),2.0*(z.x*z.w+z.y*z.z))+c;    
        r = length(z);
    }
    return 0.5*log(r)*r/length(dz);
}
float DL(in vec3 ro, in vec3 rd){
    vec3 p=vec3(-1.8,0.0,0.0);
    float d=100.0;
    for(int i=0;i<4;i++){
        float d2=distance(ro,p);
        d=min(d,distance(p,ro+rd*d2));
        p.x-=0.04;
    }
    return d;
}
vec3 Color(in vec3 z0){
    if(tim2>37.0)return vec3(1.0);
    vec4 z=vec4(z0,0.0),c = z;
    for (int n = 0; n < 9; n++) {
        z=vec4(z.x*z.x-z.y*z.y-z.z*z.z+z.w*z.w,-2.0*(z.x*z.y-z.z*z.w),-2.0*(z.x*z.z-z.y*z.w),2.0*(z.x*z.w+z.y*z.z))+c;
    }
    return vec3(0.5)+sin(z.xyz);
}
vec3 scene(vec3 ro, vec3 rd){
    float t=0.0,d,fStep=0.0;
    dzc=vec4(rd,0.0);//this really helps with this particular fractal (don't know why)
    for(int i=0;i<50;i++){
        if(t>4.0)break;
        t+=d=DE(ro+rd*t);
        if(d<0.0001){fStep=float(i);break;}
    }
    if(fStep==0.0 && d<0.005)fStep=(0.005-d)*5000.0;
    return max(vec3(0.0),Color(ro+rd*t)*fStep/50.0);
}
mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}

void main() {
    tim2=mod(time,60.0);
    vec3 col=vec3(0.1);
    vec2 uv=(2.0*gl_FragCoord.xy-size.xy)/size.y;
    if(abs(uv.x)<1.0 || tim2>37.0){
        mat3 rotCam;
        vec3 ro;
        if(tim2<37.0){
            float tim=sqrt(max(0.0,tim2-4.0)*20.0);
            ro=vec3(0.5-tim*0.1,exp(-tim*0.15)*2.5*vec2(cos(tim),sin(tim)));
            rotCam=lookat(vec3(-0.25+tim*0.015,-ro.yz+vec2(0.01)),vec3(-1.0,sin(tim*0.2)*0.1,0.0));
        }else{
            vec2 pt=vec2(-1.17,0.0);
            ro=vec3(0.75,pt+0.24*vec2(cos(tim2*0.25),sin(tim2*0.25)));
            rotCam=lookat(vec3(0.0,-(ro.yz-pt)),vec3(1.0,sin(tim2*0.2)*0.1,0.0));
        }
        vec3 rd=rotCam*normalize( vec3( vec2(1.5,1.0)*uv, 1.0 ) );
        col=scene(ro,rd);
#ifndef LOWQUAL
        vec2 d=vec2(0.666/size.y,0.0);//overlap pixels
        col+=scene(ro,rotCam*normalize( vec3( vec2(1.5,1.0)*(uv+d.xy), 1.0 ) ));
        col+=scene(ro,rotCam*normalize( vec3( vec2(1.5,1.0)*(uv+d.yx), 1.0 ) ));
        col+=scene(ro,rotCam*normalize( vec3( vec2(1.5,1.0)*(uv+d.xx), 1.0 ) ));
        col*=0.25;    
#endif
        if(tim2>30.0 && tim2<37.0)col=max(col,vec3(1.0,0.7,0.4)/max(DL(ro,rd)*1000.0,0.5));
    }
    glFragColor = vec4(col, 1.0);
}
