#version 420

// original https://www.shadertoy.com/view/MlXGz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Jogging Rat by eiffie

//this wouldn't compile for me with texturing so it is a bit flat

bool bInside=false;
vec3 L,mcol=vec3(0.0);
int id=0;

#define TAO 6.2831
vec2 kaleido(vec2 v, float p){float a=floor(.5+atan(v.x,-v.y)*p/TAO)*TAO/p;return cos(a)*v+sin(a)*vec2(v.y,-v.x);}

float DE(in vec3 z){
    vec2 p=z.xy;p.y*=2.0;
    if(mod(p.y,2.0)<1.0)p.x+=0.5;
    vec2 c=floor(p);
    p=fract(p)-vec2(0.5);
    p.y*=0.5;
    float dB=length(max(abs(vec3(p.xy,z.z))-vec3(0.425,0.175,0.175),0.0))-0.05;
    float dM=abs(z.z)-0.175;
    p=z.xy;
    p.x=mod(p.x,8.0)-4.0;
    float dW=min(max(abs(p.x)-2.0,abs(p.y-5.0)-3.0),length(vec2(p.x,p.y-8.0))-2.0);
    dB=max(dB,-dW);dM=max(dM,-dW);
    vec2 p2=abs(mod(z.xy+vec2(1.0),2.0)-vec2(1.0));
    p.y-=8.0;
    float dP=min(min(p2.x,p2.y)-0.05,max(-p.y,0.7*min(abs(p.x+p.y)-0.05,abs(p.x-p.y)-0.05)));
    dP=min(dM,max(dP,abs(z.z)-0.1));
    p2=kaleido(p,31.0);
    float dB2=max(-p.y-0.1,length(max(abs(vec3(p2.x,p2.y+2.48,z.z))-vec3(0.175,0.425,0.225),0.0))-0.05);
    p=vec2(min(abs(z.x),z.y+2.0),z.z);
    float dC=length(max(abs(p)-vec2(0.5),0.0))-0.05;
    float tile=(bInside?1.0:3.0);
    p=abs(mod(z.xz+vec2(0.0,tile),2.0*tile)-tile);
    float dG=z.y+2.0+0.5*clamp(0.1-min(p.x,p.y),0.0,0.1);
    float d1=min(dB,dB2),d2=min(d1,dP),d3=min(d2,dC);
    if(dG<d3){id=0;return dG;}
    else if(dC<d2){id=1;return dC;}
    else if(dP<d1){id=2;return dP;}
    else if(dB<dB2){id=3;return dB;}
    id=4;return dB2;
}
float hash(float c){return fract(sin(c)*717.351);}
float rnd(vec2 co){return fract(sin(dot(co,vec2(123.42,117.853)))*412.453);}

float rndStart(){return 0.5+0.5*rnd(gl_FragCoord.xy+vec2(time));}

float CE(in vec3 z){
    float d=DE(z);
    vec3 col=vec3(1.0);
    if(id!=2){
        //vec2 p=z.xy;//you can uncomment all this to get some texturing 
        if(id==0){
            col=vec3(2.25+z.y);//p=z.xz;
            if(bInside){col+=vec3(0.25);}//p=vec2(z.x+z.z,(z.x-z.z)*0.1);}
        }else if(id==1)col=vec3(0.5);
        else if(id==4)col=vec3(0.5,0.35,0.3)*0.75;
        else if(id==3){
            vec2 c=floor(z.xy);
            col=vec3(0.5,0.35,0.3)+vec3(sin(c.x*2.0)*0.025,sin(c.y*2.0)*0.025,sin(c.x+sin(c.y))*0.05);
        }
        //vec3 tx=texture2D(tex,p*0.2).rgb;
        //col+=tx*0.125;
        if(abs(z.z)<0.13)col=vec3(1.0);
        //else d+=tx.r*0.03;
    }
    mcol+=col;
    return d;
}
float smin(float a,float b,float k){float h=clamp(0.5+0.5*(b-a)/k,0.0,1.0);return b+h*(a-b-k+k*h);}//from iq

float leg(vec3 p, vec3 j0, vec3 j3, vec3 l, vec4 r, vec3 rt){//z joint with tapered legs
    float lx2z=l.x/(l.x+l.z),h=l.y*lx2z;
    vec3 u=(j3-j0)*lx2z,q=u*(0.5+0.5*(l.x*l.x-h*h)/dot(u,u));
    q+=sqrt(max(0.0,l.x*l.x-dot(q,q)))*normalize(cross(u,rt));//faster version
    vec3 j1=j0+q,j2=j3-q*(1.0-lx2z)/lx2z;
    u=p-j0;q=j1-j0;
    h=clamp(dot(u,q)/dot(q,q),0.0,1.0);
    float d=length(u-q*h)-r.x-(r.y-r.x)*h;
    u=p-j1;q=j2-j1;
    h=clamp(dot(u,q)/dot(q,q),0.0,1.0);
    d=min(d,length(u-q*h)-r.y-(r.z-r.y)*h);
    u=p-j2;q=j3-j2;
    h=clamp(dot(u,q)/dot(q,q),0.0,1.0);
    return min(d,length(u-q*h)-r.z-(r.w-r.z)*h);
}

float DER(in vec3 z0){
    z0+=vec3(mod(time*8.0,80.0)-40.0,1.5,1.0);
    float d=length(z0);
    if(d>1.75)return d-1.5;
    const vec3 rt=vec3(0.0,0.0,1.0);
    vec3 p=z0;p.z=abs(p.z)-0.125;
    float sx=sign(p.x),a=-sx*time*24.0+1.57,sa=sin(a);
    vec3 j0=vec3((sa*0.05+0.5)*sx,+sx*0.1,0.0),j3=vec3(0.6*sx+sx*sa*0.25,-0.5+max(0.0,cos(a)*0.25),0.0);
    float dL=leg(p,j0,j3,vec3(0.2+sx*0.1,0.25,0.2),vec4(0.06,0.05,0.03,0.01),rt);
    p=z0;
    vec3 u=p-j0,q=-j0;
    float h=clamp(dot(u,q)/dot(q,q),0.0,1.0);
    p.y+=sa*0.05;
    float dB=length(u-q*h)-0.13,dB2=length(p*vec3(0.5,1.0,1.0))-0.2;
    u.x+=0.25;u.y+=0.01;
    q=j0+(sx+2.0)*vec3(0.3,-0.1,0.0);
    h=clamp(dot(u,q)/dot(q,q),0.0,1.0);
    if(sx>0.0){q.z+=sin(h*2.0+time*8.0)*h*0.5;}
    float dH=length(u-q*h)-(1.2-h)*abs(sx-0.5)*0.06;
    h=1.0;
    if(sx<0.0){
        u.z=abs(u.z)-0.05;u.y-=0.05;
        dH=min(dH,length(u*vec3(1.5,0.5,1.0))-0.05);
        if(id<0){
            u.x+=0.08+sa*0.01;u.y+=0.05;
            if(length(u)-0.025<dH)h=0.0;
        }
    }else dH*=0.8;
    mcol.r+=h;
    return smin(min(dL,min(dB2,dH)),dB,0.1);
}

vec3 getBackground( in vec3 ro, in vec3 rd ){
    return 0.3*(0.5+rd.y*0.5)*vec3(0.5,0.7,0.8);
}
float getShadow(vec3 ro){
    float t=-ro.z/L.z;
    vec2 p=ro.xy+L.xy*t;
    p.x=mod(p.x,8.0)-4.0;
    float d=min(max(abs(p.x)-2.0,abs(p.y-5.0)-3.0),length(vec2(p.x,p.y-8.0))-2.0);
    p=abs(mod(p+vec2(1.0),2.0)-vec2(1.0));
    float dP=min(p.x,p.y)-0.05;
    return 0.5+0.5*smoothstep(-0.1,0.1,min(-d,dP));
}
vec3 Color(vec3 ro, float px){
    vec2 e=vec2(0.5*px,0.0);
    mcol=vec3(0.0);
    float d=CE(ro);
    vec3 dn=vec3(CE(ro-e.xyy),CE(ro-e.yxy),CE(ro-e.yyx));
    vec3 dp=vec3(CE(ro+e.xyy),CE(ro+e.yxy),CE(ro+e.yyx));
    vec3 N=(dp-dn)/(length(dp-vec3(d))+length(vec3(d)-dn));
    vec3 f=ro*0.3;
    f=sin(f+sin(f.zxy));
    mcol*=0.143*clamp(0.5+0.2*(f.x+f.y+f.z)+clamp(((ro.y+2.0)-ro.z)*0.5-0.1,0.0,0.7),0.0,1.0);
    float shad=1.0;
    if(bInside && ro.y<=-2.0+px)shad=getShadow(ro);
    return mcol*(0.5+0.5*dot(L,N))*shad;
}
vec3 ColorR(vec3 ro, float d, float px){
    vec2 e=vec2(0.5*px,0.0);
    id=-1;mcol.r=0.0;
    vec3 dp=vec3(DER(ro+e.xyy),DER(ro+e.yxy),DER(ro+e.yyx));
    vec3 N=normalize(dp-vec3(d));
    return 0.25*mcol.r*vec3(1.0,0.9,0.8)*(1.0-(ro.y+2.0)*1.25)*(0.5+0.5*dot(L,N));
}
float rndFloor(float x){return floor(x+sin(x*0.25-sin(x*0.5-sin(x)*0.75)*0.58)*1.6);}

vec3 streetScene(vec3 ro, vec3 rd){
    float d=rd.y;
    float t=(-20.0-ro.z)/rd.z;
    vec2 p=ro.xy+rd.xy*t;p*=vec2(0.175,0.25);
    d=smin(d,0.05*(min(length(p+vec2(sin(time*0.5)*20.0,0.0)),length(p+vec2(sin(time*0.6)*20.0,-0.1)))-1.0),0.1);
    vec3 col=vec3(0.5+0.25*smoothstep(0.0,0.1,d));
    p=mod(ro.xy,2.0)-vec2(1.0);
    vec2 c=floor(ro.xy*0.5);
    if(hash(c.x+c.y)<0.125 && ro.y<8.0){
        vec2 rc=2.0*vec2(hash(c.x),hash(c.x+c.y))-vec2(1.0,0.5);
        p-=rc;
        float a=atan(p.y,p.x)+c.x*2.0+c.y;
        float r=0.25+hash(rndFloor(a*5.0))*(0.5+hash(c.x-c.y));
        if(length(p)<r)col=vec3((bInside)?1.0:0.0);
    }
    return col;
}
vec3 scene( vec3 ro, vec3 rd, float px )
{
    float tG=(-1.75-ro.y)/rd.y;if(tG<0.0)tG=1000.0;
    float tMax=(1.0-ro.z)/rd.z,tMin=min(tG,(-0.75-ro.z)/rd.z);
    float t=tMin+DE(ro+rd*tMin)*rndStart(),d=1.0,od=1.0,ed=1.0,et=-1.0;
    bool grab=false;
    for(int i=0;i<12;i++){
        if(t>tMax || d<0.00001)break;
        d=DE(ro+rd*t);
        if(d>od){
            if(grab && d<px*t && et<0.0){ed=d;et=t;}
        }else grab=true;
        od=d;
        t+=d;
    }
    vec3 col=getBackground(ro,rd);
    if(t>-ro.z/rd.z){//window reflection
        float frez=sqrt(rd.z);
        if(!bInside)frez=1.0-frez;
        col+=frez*streetScene(ro+rd*(-ro.z/rd.z),vec3(rd.xy,-rd.z));//reflect rd and get street scene
    }
    if(d<px*t)col=Color(ro+rd*t,px*t);
    if(ed<px*et)col=mix(Color(ro+rd*et,px*et),col,clamp(ed/(px*et),0.0,1.0));//nice-ify the edges
    
    tG=(-2.0-ro.y)/rd.y;if(tG<0.0)tG=1000.0;
    tMax=-ro.z/rd.z;tMin=min(tG,(-1.5-ro.z)/rd.z);
    t=tMin+DER(ro+rd*tMin)*rndStart();d=1.0;od=1.0;ed=1.0;et=-1.0;
    grab=false;
    for(int i=0;i<24;i++){
        if(t>tMax || d<0.00001)break;
        d=DER(ro+rd*t);
        if(d>od){
            if(grab && d<px*t && et<0.0){ed=d;et=t;}
        }else grab=true;
        od=d;
        t+=d;
    }
    t-=d;
    if(d<px*t)col=ColorR(ro+rd*t,d,px*t);
    if(ed<px*et)col=mix(ColorR(ro+rd*et,ed,px*et),col,clamp(ed/(px*et),0.0,1.0));
    return col;
}     

mat3 lookat(vec3 fw){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(0.0,1.0,0.0)));return mat3(rt,cross(rt,fw),fw);
}

void main() {
    L=normalize(vec3(-0.3,0.7,-0.5));
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro=vec3(1.5,2.5,-8.5),dr=vec3(uv,1.0),rd=lookat(vec3(clamp(-mod(time*8.0,80.0)+40.0,-0.5,3.5),2.0,0.0)-ro)*normalize(dr);
    if(mod(time,20.0)>10.0){bInside=true;L.z=-L.z;}
    vec3 color=scene(ro,rd,2.5/resolution.y);
    float fade=min(5.0-abs(mod(time,10.0)-5.0),1.0);
    glFragColor = vec4(color*fade,1.0);

}
