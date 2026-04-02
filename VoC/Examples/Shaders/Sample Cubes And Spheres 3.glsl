#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 lightpos1=vec3(0.,4.,9.);

vec3 modulation(vec3 pos,float range){
    pos.z+=sin(pos.y*100.)*range;
    pos.z+=sin(pos.x*100.)*range;
    return pos;
}

vec3 rotY(vec3 p,float ang){
    return vec3(p.x*cos(ang)-p.z*sin(ang),p.y,p.x*sin(ang)+p.z*cos(ang));}
vec3 rotX(vec3 p,float ang){
    return vec3(p.x,p.y*cos(ang)-p.z*sin(ang),p.y*sin(ang)+p.z*cos(ang));}
vec3 rotZ(vec3 p,float ang){
    return vec3(p.x*cos(ang)-p.y*sin(ang), p.x*sin(ang)+p.y*cos(ang), p.z);}
vec2 plane(in vec3 p, in vec3 n, float d, float obj){
    n=normalize(n);return vec2(dot(p,n)+d,obj);}
vec2 rBox(vec3 p,vec3 pos,vec3 ang,float obj){
    vec3 b=vec3(.23); 
    p-=pos;p.x=mod(p.x,2.)-1.;p.y=mod(p.y,2.)-1.;    
    p=rotY(p,ang.y*time);p=rotX(p,ang.x*time);p=rotZ(p,ang.z*time);
    return vec2(length(max(abs(p)-b,0.))-.1,obj);}
vec2 sphere(vec3 p,vec3 pos,float r,float obj){
    p-=pos;p.x=mod(p.x,2.)-1.;p.y=mod(p.y,2.)-1.;
    return vec2(length(p)-r,obj);}
vec2 min2(vec2 o1,vec2 o2){if(o1.x<o2.x)return o1;else return o2;}

vec2 scene(in vec3 p){
    vec2 d=vec2(10000.,0.);
    float o=mod(time/1.,10.);
    d=min2(d,rBox(p,vec3(1.-o,1.+o,0.),vec3(.5),2.)); 
    d=min2(d,sphere(p,vec3(-o,-o,-.1),.4,2.));    
    d=min2(d,plane(modulation(p,0.0004),vec3(0.,0.,1),.5,1.)); 
    return d; 
}

vec3 getNormal(vec3 p){
    vec3 eps=vec3(.01,0, 0); 
    float nx=scene(p+eps.xyy).x-scene(p-eps.xyy).x; 
    float ny=scene(p+eps.yxy).x-scene(p-eps.yxy).x; 
    float nz=scene(p+eps.yyx).x-scene(p-eps.yyx).x; 
    return normalize(vec3(nx,ny,nz)); 
}

float softShadow(vec3 ro,vec3 rd){
    vec3 pos = ro; 
    float shade = 0.; 
    for (int i=0;i<5;i++){
        vec2 d=scene(pos);pos+=rd*d.x; 
        shade+=(1.-shade)*clamp(d.x,0.,1.); 
    }
    return shade; 
}

float castShadow(vec3 ro,vec3 rd){
    vec3 pos=ro; 
    float shade=1.; 
    for (int i=0;i<5;i++){
        vec2 d=scene(pos);pos+=rd*d.x; 
        shade-=d.x*pow(2.,.5*float(i)); 
    }
    return shade; 
}

vec3 rayMarchingR(vec3 ro,vec3 rd){
    vec3 color=vec3(0.);
    vec3 contrib=vec3(0.); 
    vec3 pos=ro; 
    float dist=0.; 
    vec2 d=vec2(0.0); 
    for (int i=0;i<30;i++){
        d=scene(pos); 
        pos+=rd*d.x*1.;
        dist+=d.x*1.; 
        if(dist<100.&&abs(d.x)<.01){
            vec3 no=getNormal(pos); 
            vec3 l1=normalize(lightpos1-pos);
            vec3 re=reflect(rd,no); 
            float shade=.0; 
            float diffuse=clamp(dot(no, l1),0.,1.); 
            float specular=pow(clamp(dot(re, l1),0.,1.),128.); 
            vec3 rColor=vec3(.6);
            if(d.y>1.5){
                if(mod(pos.x+mod(time/1.,10.)+.5,2.)<1.){
                    rColor=vec3(.9,.5,.9);
                }else{
                    rColor=vec3(.4,.6,.6);
                }
            }
            color+=shade*vec3(.0)
                +diffuse*rColor*.5
                +specular*vec3(1);  
        }
    }
    color/=32.; 
    return color; 
}

void main( void ) {
    vec2 pixel=gl_FragCoord.xy/resolution.xy-.5;
    pixel.x*=resolution.x/resolution.y; 
    vec3 color=vec3(.0,.0,.0); 
    vec3 ambient=vec3(.0,.0,.0); 
    vec3 ro=vec3(0.,-8.,4.5);
    vec3 rd=normalize(vec3(pixel.x,pixel.y,-1.)); 
    rd=rotX(rd,(mouse.y/4.)*3.);
    rd=rotZ(rd,(3.-mouse.x)*7.);
    vec3 pos=ro; 
    float dist=0.; 
    vec2 d=vec2(0.0);
    for (int i=0;i<60;i++) {    
        d=scene(pos); 
        pos+=rd*d.x*1.;
        dist+=d.x*1.;
        if(d.x<.001)break;
    }
    if(dist<100.&&d.x<.001){
        vec3 no=getNormal(pos); 
        vec3 l1=normalize(lightpos1-pos);
        vec3 re=reflect(rd,no); 
        float diffuse=clamp(dot(no,l1),0.,1.); 
        float shade=smoothstep(0.,1.,1.-castShadow(pos+.01*no,.5*no)); 
        float specular=pow(clamp(dot(re,l1),0.,1.),128.); 
        vec3 reflection=rayMarchingR(pos+.01*no,re); 
        float shadow=clamp(softShadow(pos+.18*no,l1),-1.,1.); 
        if (d.y>0.&&d.y<1.5){
            color+=ambient
                +shadow*shade*vec3(1.)
                +diffuse*vec3(.8)*.5
                +specular*vec3(1.)*.0
                +reflection*vec3(1.)*.4;  
        }else{
            if(mod(pos.x+mod(time/1.,10.)+.5,2.)<1.){
            color+=ambient
                +shadow*shade*vec3(.1,.0,.1)
                +diffuse*vec3(.9,.0,.9)*.6
                +specular*vec3(1.)*4.
                +reflection*vec3(.9,.2,.7)*.8;  
            }else{
            color+=ambient
                +shadow*shade*vec3(.0,.1,.1)
                +diffuse*vec3(.0,.9,.9)*.6
                +specular*vec3(1.)*4.
                +reflection*vec3(.2,.9,.7)*.8;  
            }
        }
        color=mix(color,ambient,clamp(length(dist)/30.,0.0,1.));
    }
    glFragColor=vec4(color,1.); 
}
