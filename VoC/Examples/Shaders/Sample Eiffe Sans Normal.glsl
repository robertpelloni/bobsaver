#version 420

// original https://www.shadertoy.com/view/Xll3zH

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

//sans normal by eiffie (lighting without finding the surface normal)
//Some of my multisampling stuff requires a number of lighting calcs so I was wondering
//what the minimum number of DE taps would be to calc diffuse and spec terms. 2

#define LOTSAPOTS 2

float DE(in vec3 p0){
    const vec2 v=vec2(2.0,2.5);
    vec3 p=p0;p.xz=mod(p.xz+v,2.0*v)-v;
    float d=100.0,scl=0.8;
    for(int i=0;i<LOTSAPOTS;i++){
        float r=0.5+sin((p.y+0.75)*3.5)*0.25;
        float o0=length(max(abs(vec2((length(p)-0.8)*0.57,p.y+0.5))-vec2(0.0,0.5),0.0))-0.02;
        p.z-=sign(p.z)*1.6;
        float o1=length(max(abs(vec2((length(p.xz)-r)*0.7,p.y))-vec2(0.0,1.0),0.0))-0.02;
        p.x-=sign(p.x)*1.4;
        float d0=max(abs(p.z),abs(p.x))-r*0.707;
        float d1=0.577*(max(abs(p.x+p.z),abs(p.x-p.z))-r);
        float o2=length(max(abs(vec2(max(d0,d1)*0.8,p.y))-vec2(0.0,1.0),0.0))-0.02;
        p.z-=sign(p.z)*1.0;
        p.y+=0.75;
        d=min(d,min(o0,min(o1,o2))*scl);
        p*=5.0;scl*=0.2;
    }
    return d;
}

float rnd(vec2 p){return fract(sin(dot(p,vec2(317.234,13.241)))*423.1123);}
mat3 lookat(vec3 fw){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(0.0,1.0,0.0)));return mat3(rt,cross(rt,fw),fw);
}
void main() {
    float tim=time*0.3;
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro=vec3(sin(tim),1.0,cos(tim))*(1.5+tim*0.1);
    vec3 rd=lookat(-ro)*normalize(vec3(uv,1.0));
    float t=DE(ro)*rnd(gl_FragCoord.xy),d=0.0;
    float tG=-(1.0+ro.y)/rd.y;
    for(int i=0;i<64;i++){
        t+=d=DE(ro+rd*t);
        if(d<0.01 || t>tG)break;
    }
    
    vec3 col=vec3(0.9+0.1*sin((ro.xz+rd.xz*tG)*100.0),0.5)*max(0.25*sqrt(DE(ro+rd*tG)),rd.y*0.5);
    
    if(d<0.01){
        vec3 lightDir=normalize(vec3(0.6,0.2,0.1));
        vec3 in4r=normalize(lightDir-rd);//ideal normal for reflection (half ray)
        vec3 lightCol=vec3(1.0,0.5,0.0);
        vec3 diffuse=vec3(0.7,0.6,0.5);
        ro+=rd*(t-d);
        
        //here are the lighting equations sans normal 
        col=diffuse*pow(clamp(0.5*DE(ro+d*lightDir)/d,0.0,1.0),2.0);//self shadow
        col+=lightCol*pow(clamp(0.5*DE(ro+d*in4r)/d,0.0,1.0),8.0);//specular
    }
    float vig=3.0*max(1.0-abs(uv.x*uv.y),0.0);
    glFragColor = vec4(vig*min(tim*0.3,1.0)*col*exp(-t*0.1),1.0);
}
