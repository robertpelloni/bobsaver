#version 420

// original https://www.shadertoy.com/view/mlSfzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define BASECOLOR vec3(.91,.91,.85)
#define PINK vec3(1.,0.75,0.75)
#define LidCol vec3(.36,.26,.25)
mat2 Rot(float radian)
{
    float c=cos(radian);
    float s=sin(radian);
    return mat2(c,-s,s,c);
}

float sdEllipse( in vec2 p, in vec2 ab )
{
    p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l;      float m2 = m*m; 
    float n = ab.y*p.y/l;      float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if (d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}
float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r*r-d*d);
    return ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                             : length(p-vec2(-d,0.0))-r;
}

float sdCircle(vec2 p,float r)
{
    return length(p)-r;
}

float sdEgg( in vec2 p, in float ra, in float rb )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x);
    float r = ra - rb;
    return ((p.y<0.0)       ? length(vec2(p.x,  p.y    )) - r :
            (k*(p.x+r)<p.y) ? length(vec2(p.x,  p.y-k*r)) :
                              length(vec2(p.x+r,p.y    )) - 2.0*r) - rb;
}

float sdMoon(vec2 p, float d, float ra, float rb )
{
    p.y = abs(p.y);
    float a = (ra*ra - rb*rb + d*d)/(2.0*d);
    float b = sqrt(max(ra*ra-a*a,0.0));
    if( d*(p.x*b-p.y*a) > d*d*max(b-p.y,0.0) )
          return length(p-vec2(a,b));
    return max( (length(p          )-ra),
               -(length(p-vec2(d,0))-rb));
}
float DrawSDF(float sdf)
{
    return smoothstep(0.0,-0.001,sdf);
}
float DrawMinusSDF(float sdf)
{
    return smoothstep(-0.001,0.0,sdf);
}
float whisker(vec2 p,vec2 trans ,float scale,float rotate,float bend)
{
    
    p-=trans;    
    p*=scale;
    p*=Rot(rotate);
    p*=Rot(bend*(p.y));
   
    
    
    float d1=length(p-vec2(0,clamp(p.y,-.2,.2)));
    float r1=mix(-.02,.005,smoothstep(-.2,.2,p.y));   
    float m1=smoothstep(.01,.005,d1-r1);
    
    float d2=length(p-vec2(0,clamp(p.y,.2,1.1)));
    float r2=mix(.005,-.02,smoothstep(.2,1.1,p.y));
    float m2=smoothstep(.01,.005,d2-r2);
    float m=max(m1,m2);
    
    return m;
}

float Hash11(float t)
{
  
    return fract(sin(t)*12561.1516);
}
void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

   
    vec3 col =vec3(0.3);
    
    vec2 catUV=uv;
   
    //ears
   
    vec2 earUV=catUV-vec2(0.,0.);
    float earUVside=sign(earUV.x);
    earUV.x=abs(earUV.x);
    earUV*=Rot(sin(time*2.)*0.03);
    
    vec2 auricleUV=earUV*vec2(1.1,0.5);
    auricleUV-=vec2(0.21,0.1);
    auricleUV*=Rot(PI*-.2);
    float sdEar=sdEgg(auricleUV,.19,.35);
    float ear=DrawSDF(sdEar);
    col=mix(col,BASECOLOR,ear);
    
    
    
    float earMod=DrawMinusSDF(sdVesica(auricleUV-vec2(0.12,-0.02),.2,.05));
    earMod=earUVside>0.?0.:earMod;
    col=mix(col,vec3(0),earMod*ear);
    
    
    vec2 earInnerUV=earUV*vec2(1.,0.9);
    earInnerUV*=Rot(PI*.09);
    earInnerUV-=vec2(0.195,0.25);
    float sdEarOutline=sdVesica(earInnerUV,.285,.19);
    float earInner=DrawSDF(sdEarOutline);
    col=mix(col,PINK,earInner);
    
    vec2 earFurUV=earUV;
    
    float sdEarFur1=sdMoon((earFurUV*Rot(PI*.05)-vec2(.31,.16)),.18,.2,.35);
    float sdEarFur2=sdMoon((earFurUV*Rot(PI*.1)-vec2(.23,.11)),.18,.2,.3);
    float sdEarFur3=sdMoon((earFurUV*Rot(PI*.3)-vec2(.14,.22)),.18,.19,.35);
    float earFur=max(max(DrawSDF(sdEarFur1),DrawSDF(sdEarFur2)),
    DrawSDF(sdEarFur3));
    col=mix(col,BASECOLOR,earFur);
    
     //head
    vec2 headUV=catUV-vec2(0.,-.15);
    headUV*=Rot(PI);
    
    float sdHead=sdEgg(headUV,.4,.6);
    float head=DrawSDF(sdHead);
    col=mix(col,BASECOLOR,head);
    
    float headBlack=DrawSDF(sdCircle(headUV*vec2(1.3,1.)-vec2(.25,-.48),.2));    
    headBlack=head*headBlack;
    col=mix(col,vec3(0),headBlack);
    
   
    //eye
    
    vec2 eyeUV=catUV*1.05;
    float eyeUVside=sign(eyeUV.x);
    eyeUV.x=abs(eyeUV.x);
    eyeUV-=vec2(.2,-.1);
    float blinky=smoothstep(0.,1.,mix(-999.,1.,sin(time)*.5+.5));
    eyeUV.y*=mix(1.,20.,blinky);
    
    
    
    float sdLid=sdCircle(eyeUV*vec2(.95,1.)-vec2(0.,.015),.09);
    float lid=DrawSDF(sdLid);
    col=mix(col,LidCol,lid);
    
    
    float sdEye=sdVesica(eyeUV*Rot(PI*0.5),.1,.01);
    float eye=DrawSDF(sdEye);
    col=mix(col,vec3(0.99,0.98,0.6),eye);
    
    vec2 signEyeUV=eyeUV;
    signEyeUV.x*=eyeUVside;
    float T1=floor(time/5.);
    float T2=floor((time+352.43)/2.);
    float pupilMove=smoothstep(0.,1.,mix(-2000.,100.,sin(time*1.2)*.5+.5));
    float to1=Hash11(T1)*2.-1.;
    float to2=Hash11(T2)*2.-1.;
    
    
    float pupil=DrawSDF(sdCircle(signEyeUV+
    vec2(mix(0.,to1,pupilMove)*.018,mix(0.,to2,pupilMove)*.018),.075));
    col=mix(col,vec3(0),pupil*eye);
    
    
    float highLight=DrawSDF(sdCircle(signEyeUV-vec2(-0.05,0.03),.022));
    highLight+=DrawSDF(sdCircle(signEyeUV-vec2(-0.06,-.007),.01));
    col=mix(col,vec3(1),highLight);
    
    
    //whisker
    vec2 whiskerUV=catUV;
    whiskerUV.x=abs(whiskerUV.x);
    
    float whiskers=whisker(whiskerUV,vec2(.3,-.2),3.,1.0,1.);
    whiskers+=whisker(whiskerUV,vec2(.3,-.21),2.2,1.4,1.);
    whiskers+=whisker(whiskerUV,vec2(.3,-.24),2.8,1.6,1.);
    
    col=mix(col,vec3(1),whiskers);
    
    //nose
    
    vec2 noseUV=catUV;
    float noseUVSide=sign(noseUV.x);
    noseUV.x=abs(noseUV.x);
    
    float blusher=DrawSDF(sdEllipse(noseUV-vec2(.2,-.22),vec2(.03,.01)));    
    col=mix(col,PINK,blusher);
    
    float mouth=DrawSDF(sdMoon((noseUV-vec2(0.04,-.23))*Rot(PI*-0.4),.015,.04,.045));
    col=mix(col,vec3(0),mouth);
    
    
    float nose=DrawSDF(sdEgg(noseUV-vec2(0.,-.2),.031,.062));    
    col=mix(col,vec3(0),nose);
    
    float highLightN=DrawSDF(sdEllipse(noseUV-vec2(.02,-.205),vec2(.01,.005)));
    highLightN=noseUVSide>0.?0.:highLightN;
    col=mix(col,vec3(1),highLightN);
    
    
    //brows
    
    vec2 browsUV=catUV;
    browsUV.x=abs(browsUV.x);
    
    float brows=DrawSDF(sdEllipse((browsUV-vec2(.2,.08))*Rot(.3),vec2(.04,.015)));
    col=mix(col,vec3(1),brows);
   
    glFragColor = vec4(col,1.0);
    
       
}
