#version 420

// original https://www.shadertoy.com/view/ldSSDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fractal Condos by eiffie
// This is a test of an auto-overstep method and lighting without normals.
// You can test the speed difference by commenting this out:
#define USE_OVERSTEP

#define size resolution
bool bColoring=false,bLite=false;
vec3 mcol=vec3(0.0);
vec2 rep(vec2 p, vec2 a){return abs(mod(p+a,a*2.0)-a);}

float DE(vec3 z0){//amazingBox by tglad
    z0.xz=rep(z0.xz,vec2(4.25,4.25));
    vec4 z = vec4(z0,1.0),c=vec4(0.0,1.0,0.8,0.0);
    float dS=1000.0,dB=z0.y+1.41;
    for (int n = 0; n < 3; n++) {
        z.xz=clamp(z.xz, -1.0, 1.0) *2.0-z.xz;
        z*=2.0/clamp(dot(z.xyz,z.xyz),1.0,1.18);
        z+=c;
        if(bColoring && n==2)mcol=vec3(0.6+abs(fract(z.x*z.y*0.5)*0.4-0.2));
        dS=min(dS,(length(max(abs(z.xyz)-vec3(0.82,2.83,0.82),0.0))-0.33)/z.w);
    }
    float dG=dS+0.037;
    c=floor(z*2.5);
    z.xyz=abs(mod(z.xyz,0.4)-0.2);
    dS=max(dS,-max(z.y-0.16,min(z.x,z.z)-0.14)/z.w);
    if(bColoring){
        if(dB<dS)mcol=vec3(0.5);
        else mcol*=vec3(1.0,0.9,0.7);
        if(dG<dS && dG<dB){mcol=vec3(0.3,0.4+fract((c.x+c.z-c.y)*0.32454213)*0.3,0.5)*30.0*(sqrt(z.z)+0.13)*pow(dS-dG,0.6);if(sin(4.0*c.x-c.y+3.0*c.z)<-0.8)bLite=true;}
    }
    return min(dS,min(dG,dB));
}
float rndStart(vec2 co){return max(0.001,fract(sin(dot(co,vec2(123.42,117.853)))*412.453));}
float ShadAO(vec3 ro, vec3 rd){
    float res=1.0,t=0.01*rndStart(gl_FragCoord.xy);
    for(int i=0;i<10;i++){
        float d=DE(ro+rd*t)*2.0+0.01;
        res=min(res,(d*d)/(t*t));
        t+=d;
    }
    return clamp(res,0.1,1.0);
}
mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,up));return mat3(rt,cross(rt,fw),fw);
}
float fakefbm(vec2 p){
    return 0.5+0.5*(sin(p.x+cos(p.y))+sin(p.y+cos(p.x)));
}
void main(){
    float tim=time*0.25;
    vec3 ro=vec3(sin(tim)*4.0,0.65*sin(tim*1.3),cos(tim)*4.5);
    if(ro.z>-1.0)ro.z=mix(ro.z,1.65,clamp(pow((ro.z+1.0)*0.225,2.0),0.0,1.0));
    ro.x+=ro.x*pow(abs(ro.z-1.65),2.0)*0.02;
    ro.y+=-0.48+length(ro.xz)*0.12;
    vec3 rd=lookat(vec3(sin(tim*0.6)*7.0,-1.0,-0.25)-ro,vec3(0.0,1.0,0.0))*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,1.0));
    float t=DE(ro)*rndStart(gl_FragCoord.xy);    //total distance
    float d=1.0;    //estimated distance
    float pd=10.0;//previous estimate
    float os=0.0;    //overstep
    for(int i=0;i<64;i++){
        d=DE(ro+rd*t);
#ifdef USE_OVERSTEP
        if(d>os){        //we have NOT stepped over anything
            os=0.5*d*d/pd;//calc overstep based on ratio of this step to last
            t+=d+os;    //add in the overstep
            pd=d;    //save this step length for next calc
        }else{        //we MAY have stepped over something
            os*=0.5;    //bisect overstep
            t-=os;    //back up
            if(os>0.002)d=0.1;    //don't bail unless the overstep was small (and d of course)
        }
#else
        t+=d;
#endif
        if(t>20.0 || d<0.001)break;
    }
    vec3 col=vec3(rd.y);
    if(d<0.1){
        bColoring=true;
        t+=DE(ro+rd*t);
        bColoring=false;
        ro+=rd*t;
        if(!bLite)col=mcol*ShadAO(ro,normalize(vec3(0.4,0.7,-0.3)));
        else col=mcol*1.5;
        ro.y-=3.0;
        col/=(0.06*dot(ro,ro));
    }else if(rd.y>0.0){
        float c=fakefbm(vec2(atan(rd.x,rd.z)*6.0,rd.y*20.0));
        col.g+=(c*2.0-rd.y*8.0)*0.01;
    }
    glFragColor=vec4(col*1.5,1.0);
}
