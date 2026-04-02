#version 420

// original https://www.shadertoy.com/view/4tB3RR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S.Guillitte
//Based on Voronoise by iq :https://www.shadertoy.com/view/Xd23Dh
//and Gabor 4: normalized  by FabriceNeyret2 : https://www.shadertoy.com/view/XlsGDs

#define PI 3.14159265358979

int windows = 0;//0=noise,1=abs(noise),2=fbm,3=fbmabs

float hash( in vec3 p ) 
{
    return fract(sin(p.x*15.32758341+p.y*39.786792357+p.z*59.4583127+7.5312) * 43758.236237153)-.5;
}

vec3 hash3( in vec3 p )
{
    return vec3(hash(p),hash(p+1.5),hash(p+2.5));
}

//mat2 m2= mat2(.8,.6,-.6,.8);

// Gabor/Voronoi mix 3x3 kernel (some artifacts for v=1.)
float gavoronoi3(in vec3 p)
{    
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float f = 4.*PI;//frequency
    float v = .8;//cell variability <1.
    float dv = .9;//direction variability <1.
    vec3 dir = vec3(.1);
    float va = 0.0;
       float wt = 0.0;
    for (int i=-1; i<=1; i++) 
    for (int j=-1; j<=1; j++) 
    for (int k=-1; k<=1; k++)    
    {        
        vec3 o = vec3(i, j, k)-.5;
        vec3 h = hash3((ip - o));
        vec3 pp = fp +o  -h;
        float d = dot(pp, pp);
        float w = exp(-d*4.);
        wt +=w;
        h = dv*h+dir;//h=normalize(h+dir);
        va += cos(dot(pp,h)*f/v)*w;
    }    
    return va/wt;
}

// Gabor/Voronoi mix 4x4 kernel (clean but slower)
float gavoronoi4(in vec3 p)
{    
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    vec3 dir = vec3(1.);
    float f = 2.*PI;                                                                                                                                                                        ;//frequency
    float v = .8;//cell variability <1.
    float dv = .7;//direction variability <1.
    float va = 0.0;
       float wt = 0.0;
    for (int i=-2; i<=1; i++) 
    for (int j=-2; j<=1; j++)
    for (int k=-2; k<=1; k++)     
    {        
        vec3 o = vec3(i, j, k);
        vec3 h = hash3(ip - o);
        vec3 pp = fp +o  -v*h;
        float d = dot(pp, pp);
        float w = exp(-d*4.);
        wt +=w;
          h= dv*h+dir;//h=normalize(h+dir);
        va +=cos(dot(pp,h)*f)*w;
    }    
    return va/wt;
}

// Gabor/Voronoi mix 5x5 kernel (even slower but suitable for large wavelets)
float gavoronoi5(in vec3 p) 
{    
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float f = 2.*PI;//frequency
    float v = 1.;//cell variability <1.
    float dv = .8;//direction variability <1.
    vec3 dir = vec3(.7);
    float va = 0.0;
       float wt = 0.0;
    for (int i=-2; i<=2; i++) 
    for (int j=-2; j<=2; j++)
    for (int k=-2; k<=2; k++)     
    {        
        vec3 o = vec3(i, j, k)-.5;
        vec3 h = hash3(ip - o);
        vec3 pp = fp +o  -h;
        float d = dot(pp, pp);
        float w = exp(-d*1.);
        wt +=w;
        h = dv*h+dir;//h=normalize(h+dir);
        va += cos(dot(pp,h)*f/v)*w;
    }    
    return va/wt;
}

  

//concentric waves variant
float gavoronoi3b(in vec3 p)
{    
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float f = 4.*PI;                                                                                                                                                                        ;//frequency
    float v = .8;//cell variability <1.
    float va = 0.0;
    float wt = 0.0;
    for (int i=-1; i<=1; i++) 
    for (int j=-1; j<=1; j++)
    for (int k=-1; k<=1; k++)     
    {        
        vec3 o = vec3(i, j, k)-.5;               
        vec3 pp = fp +o  - v*hash3(ip - o);
        float d = dot(pp, pp);
        float w = exp(-d*4.);
        wt +=w;
        va +=sin(sqrt(d)*f)*w;
    }    
    return va/wt;
}

float noise( vec3 p)
{   
    if(fract(time*.1)<.33)return gavoronoi3(p);
    if(fract(time*.1)<.66)return gavoronoi4(p);
    return gavoronoi3b(p);
}

float fbmabs( vec3 p ) {
    
    float f=1.;
   
    float r = 0.0;    
    for(int i = 0;i<4;i++){    
        r += abs(noise( p*f ))/f;       
        f *=2.2;
    }
    return r;
}

float fbm( vec3 p ) {
    
    float f=1.;
   
    float r = 0.0;    
    for(int i = 0;i<4;i++){    
        r += noise( p*f )/f;       
        f *=2.;
    }
    return r;
}

float map(vec3 p){

    if(windows==0)return noise(p*4.);
    if(windows==1)return 2.*abs( noise(p*10.));
    if(windows==2)return fbm(p);
    return 1.2*fbmabs(p);
}

mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}

vec2 iSphere( in vec3 ro, in vec3 rd, in vec4 sph )//from iq
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h, -b+h );
}

void main(void) {
    float time = time;
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
    vec2 m = vec2(0.);
//    if( mouse.z>0.0 )m = mouse.xy/resolution.xy*3.14;
    m-=.5;

    // camera

    vec3 ro = vec3(4.);
    ro.yz*=rot(m.y);
    ro.xz*=rot(m.x+ 0.1*time);
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );

    
    vec2 tmm = iSphere( ro, rd, vec4(0.,0.,0.,2.) );

    float c;
    
       if (tmm.x<0.)c =  map(rd)/2.;
    else c= map(ro+rd*tmm.x)/2.;
    vec3 col = vec3( c,c*c,c*c*c);
   
    
    // shade
    
    col =  1.5 *(log(1.+col));
    col = clamp(col,0.,1.);
    glFragColor = vec4( col, 1.0 );
}
    
