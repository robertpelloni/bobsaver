#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Alien Tech by Kali

#define SHOWLIGHT //comment this line if you find the moving ligth annoying like Dave :D

const vec2 c=vec2(2.,4.5); // to tweak the fractal

float ti;
vec3 ldir;
float ot;
float blur;

float formula(vec2 p) {
    vec2 t=vec2(sin(ti*.3)*.1+ti*.05,ti*.1);
    p=abs(.5-fract(p*.4+t))*1.3;
    ot=1000.;
    float l, expsmo;
    float aav=0.;
    l=0.; expsmo=0.;
    for (int i=0; i<12; i++) {
        p=abs(p+c)-abs(p-c)-p;
        p/=clamp(dot(p,p),.0007,1.);
        p=p*-1.5+c;
        if (mod(float(i),2.)<1.) {
            float pl=l;
            l=length(p);
            expsmo+=exp(-1./abs(l-pl));
            ot=min(ot,l);
        }
    }
    return expsmo;
}

vec3 light(vec2 p, vec3 col) {
    vec2 d=vec2(0.,.002);
    float d1=formula(p-d.xy)-formula(p+d.xy);
    float d2=formula(p-d.yx)-formula(p+d.yx);    
      vec3 n1=vec3(0.,d.y*2.,-d1*.05);
      vec3 n2=vec3(d.y*2.,0.,-d2*.05);
      vec3 n=normalize(cross(n1,n2));
      float diff=pow(max(0.,dot(ldir,n)),2.)+.2;
    vec3 r=reflect(vec3(0.,0.,1.),ldir);
    float spec=pow(max(0.,dot(r,n)),20.);
      return diff*col+spec*.7;
}

void main( void )
{
    ti=time;
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 aspect=vec2(resolution.x/resolution.y,1.);
    uv*=aspect;
    vec2 pixsize=.5/resolution.xy*aspect;
    float sph=length(uv); sph=sqrt(1.-sph*sph)*1.5;
    uv=normalize(vec3(uv,sph)).xy*1.3;
    pixsize=normalize(vec3(pixsize,sph)).xy;
    #ifdef SHOWLIGHT
    vec3 lightpos=vec3(sin(ti),cos(ti*.5),-.7);
    #else
    vec3 lightpos=vec3(0.,0.,-1.);
    #endif
    lightpos.xy*=aspect*.25;
    vec3 col=vec3(0.);
    float lig=0.;
    float titila=0.0;
    for (float aa=0.; aa<9.; aa++) {
        vec2 aacoord=floor(vec2(aa/3.,mod(aa,3.)));
        vec2 p=uv+aacoord*pixsize;
        ldir=normalize(vec3(p,.0)+lightpos);
        float k=clamp(formula(p)*.25,.8,1.4);
        col+=light(p,vec3(k,k*k,k*k*k))*2.;
        lig+=max(0.,2.-ot)/2.;
    }
    col*=.1;
    vec2 luv=uv+lightpos.xy;
    col*=.05+pow(max(0.,1.-length(luv)*.5),8.)*(1.-titila*.3);
    float star=abs(1.5708-mod(atan(luv.x,luv.y)*3.-ti*10.,3.1416))*.02-.05;
    #ifdef SHOWLIGHT
    col+=pow(max(0.,.3-length(luv*1.5)-star)/.3,5.)*(1.-titila*.5);
    #endif
    col+=pow(lig*.12,15.)*vec3(1.,.9,.3)*.8;
    glFragColor = vec4(col, 1.0 );
}
