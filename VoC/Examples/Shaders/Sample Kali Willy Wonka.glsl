#version 420

// "Willy Wonka" by Kali

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// #define enable_shadow

#define version1 // 1-3 for different presets

#ifdef version1
const int Iterations=10;  
const float Wavelength=2.3; 
const float Scale=1.15; 
const float Amplitude=.045; 
const float Fade=.0035; 
const float Speed=1.2; 
const float Stream=1.; 
#endif

#ifdef version2
const int Iterations=10;  
const float Wavelength=1.1; 
const float Scale=1.25; 
const float Amplitude=.1; 
const float Fade=.0035; 
const float Speed=1.; 
const float Stream=.7; 
#endif

#ifdef version3
const int Iterations=5;  
const float Wavelength=1.4; 
const float Scale=1.4; 
const float Amplitude=.12; 
const float Fade=.007; 
const float Speed=1.; 
const float Stream=.9; 
#endif

const vec3 fore=vec3(170,135,95)/255.;
const vec3 back=vec3(90.,85.,80)/255.;
const float detail=.04;

const vec3 lightdir=-vec3(-1.0,0.5,-0.5);

float colindex;

mat2 rot2D(float angle)
{
    float a=radians(angle);
    return mat2(cos(a),sin(a),-sin(a),cos(a));

}

float smin( float a, float b, float k)
{
float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
return mix( b, a, h ) - k*h*(1.0-h);
}

float de (in vec3 p);

vec3 normal(vec3 p) {
    vec3 e = vec3(0.0,detail,0.0);
    
    return normalize(vec3(
            de(p+e.yxx)-de(p-e.yxx),
            de(p+e.xyx)-de(p-e.xyx),
            de(p+e.xxy)-de(p-e.xxy)
            )
        );    
}

float shadow(vec3 pos, vec3 sdir) {
        float eps=detail;
        float totalDist =5.0*eps;
        float s = 1.0; 
         for (int steps=0; steps<30; steps++) {
            vec3 p = pos - totalDist * sdir;
            float dist = de(p);
            if (dist < eps)  return 0.2;
            s = min(s, 15.*(dist/totalDist));
            totalDist += dist*1.5;
            if (totalDist>20.) break;
        }
        return max(0.2,s);    
}

vec3 light(in vec3 p, in vec3 dir) {
    vec3 ldir=normalize(lightdir);
    vec3 n=normal(p);
    float sh=1.;
    #ifdef enable_shadow
        sh=shadow( p, ldir);
    #endif
    float diff=max(0.,dot(ldir,-n))+.015;
    diff*=sh;
    vec3 r = reflect(ldir,n);
    float spec=max(0.,dot(dir,-r))*sh;
    return vec3(diff*.7+pow(spec,50.)*1.3);    
        }

vec3 raymarch(in vec3 from, in vec3 dir) 
{
    float totdist=0.;
    vec3 col, p;
    float d;
    for (int i=0; i<79; i++) {
        p=from+totdist*dir;
        d=de(p);
        if (d<detail || totdist>90.) break;
        totdist+=d*1.1; 
    }
    vec3 backg=back*(1.+pow(1.-dot(normalize(p),normalize(lightdir)),2.5)*.38);
    if (d<detail) {
        float cindex=colindex;
        col=fore*light(p-detail*dir, dir); 
    } else { 
        col=backg;
    }
    col = mix(col, backg, 1.0-exp(-.00005*pow(totdist,3.)));
    return col;
}

void main(void)
{
    vec2 mouse=mouse.xy/resolution.xy;
    float time=time*.5;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv=uv*2.-1.;
    uv.y*=resolution.y/resolution.x;
    uv=uv.yx;
    vec3 from=vec3(.5,0.,-18.+cos(time*.8)*4.5);
    vec3 dir=normalize(vec3(uv*.7,1.));
    mat2 camrot1=rot2D(50.+mouse.y*35.);
    mat2 camrot2=rot2D(190.+sin(time*.5)*80.);
    mat2 camrot3=rot2D((sin(time))*10.);
    from.xz=from.xz*camrot1;
    dir.xz=dir.xz*camrot1;
    from.xy=from.xy*camrot2;
    dir.xy=dir.xy*camrot2;
    dir.yz=dir.yz*camrot3;
    
    vec3 col=raymarch(from,dir)*1.05; 

    glFragColor = vec4(col,1.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
        

float de(vec3 pos)
{
    vec3 z=pos;
    float O=4.;
    float sc=1.;
    float tsc=pow(Scale,float(Iterations));
    float t=time*Speed*10./tsc+100.;
    float amp1=Amplitude;
    float amp2=amp1*1.1256;
    float amp3=amp1*1.0586;
    float amp4=amp1*0.9565;
    float l1=length(z.xy-vec2(O*1.1586,0));
    float l2=length(z.xy+vec2(O*.98586,0));
    float l3=length(z.xy+vec2(0,O*1.13685));
    float l4=length(z.xy-vec2(0,O));
    amp1=max(0.,amp1-l1*Fade*Amplitude*10.);
    amp2=max(0.,amp2-l2*Fade*Amplitude*10.);
    amp3=max(0.,amp3-l3*Fade*Amplitude*10.);
    amp4=max(0.,amp4-l4*Fade*Amplitude*10.);
    l1*=Wavelength; l2*=Wavelength; l3*=Wavelength; l4*=Wavelength;
    for (int n=0; n<Iterations ; n++) {
        z+=sin(length(z.xy)*sc*Wavelength-t)*amp1/sc*2.;
        z+=sin(l1*sc-t)*amp1/sc;
        z+=sin(l2*sc-t)*amp2/sc;
        z+=sin(l3*sc-t)*amp3/sc;
        z+=sin(l4*sc-t)*amp4/sc;
        t=t*Scale*Scale;
        sc*=Scale;
    }
    float wd=-z.z;
    float b2=length(z.xy/2.+sin(pos.z-t/2.)/20.)-Stream;
    float b1=sdTorus(vec3(z.x,z.z/1.5-.7,z.y),vec2(4.,1.8));
    return smin(min(b1,b2),wd,.5);
}
