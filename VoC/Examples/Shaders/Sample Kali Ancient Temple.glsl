#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Ancient Temple" by Kali
// https://www.shadertoy.com/view/XslGWf

const int Iterations=16;
const float width=.22;
const float detail=.00004;
const float Scale=2.;

vec3 lightdir=normalize(vec3(0.,-0.3,-1.));
vec3 ambdir=normalize(vec3(0.,-1.,0.5));

float ot=0.;
float det=0.;

float hitfloor=0.;

float de(vec3 pos) {
    hitfloor=0.;
    vec3 p=pos;
    p.xz=abs(.5-mod(pos.xz,1.))+.008;
    float DEfactor=1.;
    ot=1000.;
    for (int i=0; i<Iterations; i++) {
        p = abs(p)-vec3(0.,2.,0.);  
        float r2 = dot(p, p);
        ot = min(ot,abs(length(p)-.1));
        float sc=Scale/clamp(r2,0.4,1.);
        p*=sc; 
        DEfactor*=sc;
        p = p - vec3(0.5,1.,0.5);
    }
    float fl=pos.y-3.013;
    float d=min(fl,length(p)/DEfactor);
    d=min(d,-pos.y+3.9);
    if (abs(d-fl)<.0001) hitfloor=1.;
    return d;
}

vec3 normal(vec3 p) {
    vec3 e = vec3(0.0,det,0.0);
    
    return normalize(vec3(
            de(p+e.yxx)-de(p-e.yxx),
            de(p+e.xyx)-de(p-e.xyx),
            de(p+e.xxy)-de(p-e.xxy)
            )
        );    
}

float shadow(vec3 pos, vec3 sdir) {
        float totalDist =2.0*detail, sh=1.;
         for (int steps=0; steps<20; steps++) {
            if (totalDist<.5) {
                vec3 p = pos - totalDist * sdir;
                float dist = de(p)*1.5;
                if (dist < detail)  sh=0.;
                totalDist += dist;
            }
        }
        return max(0.,sh);    
}

float calcAO( const vec3 pos, const vec3 nor ) {
    float aodet=det*15.;
    float totao = 0.0;
    float sca = 1.0;
    for( int aoi=0; aoi<5; aoi++ ) {
        float hr = aodet + aodet*float(aoi*aoi);
        vec3 aopos =  nor * hr + pos;
        float dd = de( aopos );
        totao += -(dd-hr)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - 5.0*totao, 0.0, 1.0 );
}

float kset(vec3 p) {
    p=abs(.5-fract(p*20.));
    float es, l=es=0.;
    for (int i=0;i<13;i++) {
        float pl=l;
        l=length(p);
        p=abs(p)/dot(p,p)-.5;
        es+=exp(-1./abs(l-pl));
    }
    return es;    
}

vec3 light(in vec3 p, in vec3 dir) {
    float hf=hitfloor;
    vec3 n=normal(p);
    float sh=shadow(p, lightdir);
    //float sh=1.;
    float ao=calcAO(p,n);
    float diff=max(0.,dot(lightdir,-n))*1.5;
    float amb=max(0.3,dot(normalize(ambdir),-n))*.75;
    vec3 r = reflect(lightdir,n);
    float spec=pow(max(0.,dot(dir,-r))*sh,10.);
    float k=kset(p)*.18; 
    vec3 col=mix(vec3(k*1.1,k*k*1.3,k*k*k),vec3(k),.4)*2.;
    col=col*ao*(amb*vec3(.85,.8,1.)+diff*vec3(1.,.9,.9))+spec*vec3(1,.9,.65)*.8;    
    return col;
}

vec3 raymarch(in vec3 from, in vec3 dir) 
{
    float t=time;
    vec2 lig=vec2(sin(t*2.)*.6,cos(t)*.25-.25);
    float fog,glow,d=1., totdist=glow=fog=0.;
    vec3 p, col=vec3(0.);
    float ref=0.;
    float steps;
    for (int i=0; i<140; i++) {
        if (d>det && totdist<4.) {
            p=from+totdist*dir;
            d=de(p);
            det=detail*(1.+totdist*50.);
            totdist+=d; 
            glow+=max(0.,.03-d);
            steps++;
        }
    }
    //glow/=steps;
    float l=pow(max(0.,dot(normalize(-dir),normalize(lightdir))),10.);
    vec3 backg=vec3(.8,.85,1.)*.25*(2.-l)+vec3(1.,.9,.65)*l*.4;
    float hf=hitfloor;
    if (d<det) {
        col=light(p-det*dir*1.5, dir); 
        if (hf>0.5) col*=vec3(1.,.85,.8)*.7;
        col*=min(1.,.3+totdist);
        col = mix(col, backg, 1.0-exp(-totdist));
    } else { 
        col=backg;
    }
    col+=glow*vec3(1.,.9,.75)*.15;
    col+=vec3(1,.8,.6)*pow(l,3.)*.5;
    return col; 
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.-1.;
    uv.y*=resolution.y/resolution.x;
    vec2 mouse2=(mouse.xy/resolution.xy-.5);
    float t=time*.15;
    float y=(cos(time*.1)+1.);
    mouse2=vec2(sin(t*2.),cos(t)+.3)*.15*(.5+y);
    uv+=mouse2*2.;
    uv.y-=.1;
    //uv+=(texture2D(iChannel1,vec2(iGlobalTime*.15)).xy-.5)*max(0.,h)*7.;
    vec3 from=vec3(0.0,3.02+y*.1,-2.+time*.05);
    vec3 dir=normalize(vec3(uv*.85,1.));
    vec3 color=raymarch(from,dir); 
    //col*=length(clamp((.6-pow(abs(uv2),vec2(3.))),vec2(0.),vec2(1.)));
    color+=vec3(1,.85,.7)*pow(max(0.,.3-length(uv-vec2(0.,.03)))/.3,1.5)*.7;
    color*=vec3(1.,.95,.87);
    color=pow(color,vec3(1.15));
    glFragColor = vec4(color,1.);
}
