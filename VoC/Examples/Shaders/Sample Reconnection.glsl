#version 420

// original https://www.shadertoy.com/view/NltSRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define resolution resolution.xy
#define gl_glFragColor glFragColor
#define gl_gl_FragCoord.xy gl_FragCoord.xy

#define hash(x) fract(sin(x)*43758.5453)
#define X(col) if(h<.5){\
        q=vec2(q.y,-q.x);\
    }\
    h=hash(h);\
    if(h<.5){\
        q=abs(q);\
        col+=smoothstep(.1,0.,min(q.x,q.y));\
    }else{\
        if(q.y<-q.x){\
            q.xy=-q.yx;\
        }\
        q-=.5;\
        col+=smoothstep(.1,0.,abs(length(q)-.5));\
    }

const float pi2=acos(-1.)*2.;

float hash21(vec2 p){
    return hash(dot(p ,vec2(12.9898,78.233)));
}

void rot3d(inout vec3 v,float a,vec3 ax){
    ax=normalize(ax);
    v=mix(dot(ax,v)*ax,v,cos(a))-sin(a)*cross(ax,v);
}

mat2 rot(float a){
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

const float radius=.15;
const float floorHeight=-.12;
float lightTime=0.;
float map(vec3 p){
    float d,d1,d2;
    float h=hash21(floor(p.zx));
    
    vec3 q=p;
    q.zx=fract(q.zx)-.5;
    if(h<.5){
        q.zx=vec2(q.x,-q.z);
    }
    
    vec3 q1=q;
    q.x=abs(q.x);
    d1=length(q.xy)-radius;
    float grad=48.*radius*q.x*(q.x-.5);
    float tmp=length(vec2(abs(q.y-(q.x*q.x*(q.x-.75)*32.+2.)*radius)/sqrt(1.+grad*grad),q.z))-radius;
    d1=min(d1,tmp);
        
    q=q1;
    if(q.x<-q.z){
        q.zx=-q.xz;
    }
    q.zx-=.5;
    d2=length(vec2(length(q.zx)-.5,q.y))-radius;

    float a=1.;
    float ac=0.;
    for(int i=0;i<5;i++){
        q=(p+hash(float(i))*500.)*a;
        q+=sin(q*1.7)*2.;
        q=sin(q);
        ac+=q.x*q.y*q.z/a*.07;
        a*=2.;
    }
    h=hash(h);
    lightTime=time+h*pi2;
    d=mix(d1,d2,smoothstep(-.5,.5,sin(lightTime)));
    d+=ac;
    
    float df=p.y-floorHeight;
    d=min(d,df);
    d=mix(d,df,smoothstep(-.2,.2,-sin(time*.3)));
    
    return d;
}

vec3 calcN(vec3 p){
    vec2 e=vec2(.001,0);
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),
                  map(p+e.yxy)-map(p-e.yxy),
                  map(p+e.yyx)-map(p-e.yyx)
                  ));
}

vec3 getC(vec3 p){
    vec3 col=vec3(0);
    if(p.y>floorHeight+.01){
        col+=vec3(.9,.7,.3);        
        return col;
    }
    
    vec2 q=p.zx*5.;
    float h=hash21(floor(q)*1.1523);
    q=fract(q)-.5;
    
    vec3 c1=vec3(0);
    vec2 q1=q;
    X(c1)
        
    vec3 c2=vec3(0);
    q=q1;
    h=hash(h);
    X(c2);
    
    col=mix(c1,c2,smoothstep(-.5,.5,sin(lightTime)));
    
    q=p.zx*.5;
    q=fract(q)-.5;
    if(q.x*q.y>0.){
        col=1.-col;
    }
    col=clamp(col,.05,.95);
    float red=smoothstep(.51,.49,abs(sin(lightTime)));
    col+=vec3(1,0,0)*red*100.;
    
    return col;
}

float shadow(vec3 rp,vec3 rd){
    float d;
    float h=.001;
    float res=1.;
    float c=.2;
    for(int i=0;i<30;i++){
        d=map(rp+rd*h);
        if(d<.001){
            return c;
        }
        res=min(res,16.*d/h);
        h+=d;
    }
    return mix(c,1.,res);
}

float fs(float f0,float c){
    return f0+(1.-f0)*pow(1.-c,5.);
}

vec3 march(inout vec3 rp,inout vec3 rd,inout bool hit,inout vec3 ra,int itr){
    vec3 col=vec3(0);
    float t=0.;
    hit=false;
    
    for(int i=0;i<100;i++){
        if(i>=itr||t>30.){
            break;
        }
        float d=map(rp+rd*t);
        if(abs(d)<.0001){
            hit=true;
            break;
        }
        t+=d*.9;
    }
    rp+=rd*t;
    
    vec3 ld=normalize(vec3(-3,3,-1));
    vec3 al=getC(rp);
    vec3 n=calcN(rp);
    vec3 ref=reflect(rd,n);
    float diff=max(dot(ld,n),0.);
    float spec=pow(max(dot(reflect(ld,n),rd),0.),20.);
    float fog=exp(-t*t*.005);
    float sh=shadow(rp+.01*n,ld);
    float f0=0.8;
    float lp=10.;
    float m=0.9;
    col+=al*diff*sh*(1.-m)*lp;
    col+=al*spec*sh*m*lp;
    col=mix(vec3(1),col,fog);
    
    col*=ra;
    ra*=al*fs(f0,dot(ref,n))*fog;
    
    rp+=.01*n;
    rd=ref;
    
    return col;
}

vec3 acesFilm(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0., 1.);
}

#define ihash(x,n) floor(hash(x)*float(n))
float in1d(float x,int n){
  float i=floor(x);
  float s=.1;
  float u=smoothstep(.5-s,.5+s,fract(x));
  return mix(ihash(i,n),ihash(i+1.,n),u);
}

void main(void) {
    vec2 uv=(gl_FragCoord.xy*2.-resolution)/min(resolution.x,resolution.y);
    vec3 col=vec3(0);
    
    vec3 cp=vec3(0,1.,-time);
    vec3 rd=normalize(vec3(uv,-2.+dot(uv,uv)*.3));
    
    cp.x+=in1d(cp.z*.33-550.5,10);
    cp.y+=in1d(cp.z*.39-61.,5);
    
    rot3d(rd,cp.y*.3,vec3(1,0,0));
    
    vec3 rp=cp;
    vec3 ra=vec3(1);
    bool hit=false;
    col+=march(rp,rd,hit,ra,100);
    if(hit){
        col+=march(rp,rd,hit,ra,30);
    }
    if(hit){
        col+=march(rp,rd,hit,ra,30);
    }
    
    col=acesFilm(col);
    col=pow(col,vec3(1./2.2));
    
    gl_FragColor = vec4(col,1);
}
