#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S.Guillitte
//Based on Voronoise from iq :https://www.shadertoy.com/view/Xd23Dh

int windows = 0;
vec2 m = vec2(.7,.8);

float hash( in vec2 p ) 
{
    return fract(sin(p.x*15.32+p.y*5.78) * 43758.236237153);
}

vec2 hash2(vec2 p)
{
    return vec2(hash(p*.754),hash(1.5743*p.yx+4.5891))-.5;
}

vec2 hash2b( vec2 p )
{
    vec2 q = vec2( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)) );
    return fract(sin(q)*43758.5453);
}

float vnoise(vec2 x)//Value noise
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return  2.*mix(mix( hash(p),hash(p + vec2(1.,0.)),f.x),
                  mix( hash(p+vec2(0.,1.)), hash(p+1.),f.x),f.y)-1.;
            
}

float gnoise( in vec2 p )// gradient noise from iq
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash2( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash2( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash2( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash2( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y)*2.;
}

mat2 m2= mat2(.8,.6,-.6,.8);

float dvnoise(vec2 p)//Value noise + value noise with rotation
{
    return .5*(vnoise(p)+vnoise(m2*p));    
}

//Perlin like version of iqnoise adapted from voronoise : 3x3 kernel

float iqnoisep( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-1; j<=1; j++ )//kernel limitations to increase performances :
    for( int i=-1; i<=1; i++ )//3x3 instead of 5x5
    {
        
        vec2 g = vec2( float(i),float(j) )+.5;
        float o = hash( p + g );
        vec2 r = g - f ;
        float d = dot(r,r)*(.4+m.x*.4);
        d=smoothstep(0.0,1.,d);//d=smoothstep(0.0,1.,sqrt(d));
        //d = d*d*d*(d*(d*6. - 15.) + 10.);
        float ww = 1.0-d;
        va += o*ww;
        wt += ww;
    }
    
    return 2.*va/wt-1.;
}

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1531,311.7273)), 
                   dot(p,vec2(269.5437,183.3581)), 
                   dot(p,vec2(419.2673,371.9741)) );
    return fract(sin(q)*43758.5453);
}
vec3 hash3b( vec2 p )
{
    float q = hash(p);
    return vec3(q,1.-q,q*(2.-q));
}

//iq noise adapted from voronoise 3x3 kernel : valid for u+v<1.5

float iqnoise3( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    vec2 sp = floor(f*1.1666);//kernel shift if f is large    
    float k = 1.0+63.0*pow(1.0-v,4.0);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2( float(i),float(j) )+sp;
        vec3 o = hash3( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = sqrt(dot(r,r)*.5);
        d = d*d*d*(d*(d*6. - 15.) + 10.);//additional hermit 5 smoothing
        float ww = pow( 1.0-smoothstep(0.,1.,d), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return 2.*va/wt-1.;
}

//a variant of the previous noise using exp in weights

float iqnoise3b( in vec2 x, float u, float v )//iq noise adapted from voronoise 3x3 kernel : valid for u + v <1.5
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    vec2 sp = floor(f*1.1666);        
    float k = 1.0+15.0*pow(1.0-v,4.0);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2( float(i),float(j) )+sp;
        vec3 o = hash3( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float ww = exp(-4.*k*d);//pow( 1.0-smoothstep(0.0,1.,sqrt(d)), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return 2.*va/wt-1.;
}

//iq noise from voronoise 4x4 kernel : valid for all u and v 
float iqnoise4( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
        
    float k = 1.0+63.0*pow(1.0-v,4.0);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=1; j++ )
    for( int i=-2; i<=1; i++ )
    {
        vec2 g = vec2( float(i),float(j) )+.5;
        vec3 o = hash( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = dot(r,r)*.5;
        float ww = pow( 1.0-smoothstep(0.0,1.,sqrt(d)), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return 2.*va/wt-1.;
}

float hash( in vec3 p ) 
{
    return fract(sin(p.x*15.32758341+p.y*39.786792357+p.z*59.4583127+7.5312) * 43758.236237153)-.5;
}

float voronoise(in vec3 p)
{    
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float va = 0.0;
    float wt = 0.0;
    for (int i=-1; i<=2; i++) 
    for (int j=-1; j<=2; j++) 
    for (int k=-1; k<=2; k++)
    {
        vec3 o = vec3(i, j, k)-.5;               
        vec3 pp = fp +o -hash(ip - o);
        float d = dot(pp, pp)*.7;
        d=clamp(d,0.,1.);d=sqrt(d);
        d = d*d*(3.0-2.0*d);       
        d = d*d*d*(d*(d*6. - 15.) + 10.);
        float w = 1.-d;
        va += w*d;
        wt += w;
    }    
    return 2.*va/wt-1.;
}

// a kind of pure voronoi version of iqnoise
float voronoise(in vec2 p)
{    
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float va = 0.0;
    float wt = 0.0;
    for (int i=-1; i<=1; i++) 
    for (int j=-1; j<=1; j++) 
    {        
        vec2 o = vec2(i, j);               
        vec2 pp = fp +o -hash2b(ip - o)*m.y;
        float d = dot(pp, pp)*.7;       
        d = smoothstep(0.0,1.,sqrt(d));       
        d = d*d*d*(d*(d*6. - 15.) + 10.);
        float w =  1.0-d;
        va += w*d;
        wt += w;
    }    
    return 2.*va/wt-1.;
}

//a variant of the previous noise using exp in weights

float voronoise1(in vec2 p)
{    
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float va = 0.0;
    float wt = 0.0;
    for (int i=-1; i<=1; i++) 
    for (int j=-1; j<=1; j++) 
    {        
        vec2 o = vec2(i, j);               
        vec2 pp = fp +o -hash2(ip - o)*m.y-0.5;
        float d = sqrt(dot(pp, pp)*.6);
        d=clamp(d,0.,1.);
        d = d*d*(3.0-2.0*d);//d = d*d*d*(d*(d*6. - 15.) + 10.);               
        float w =  exp(-d*4.);
        va += w*d;
        wt += w;
    }    
    return va/wt*2.-1.;
}

//standard voronoi 3x3 kernel giving f1,f2 and f3 if f3<1

float voronoi(in vec2 p)
{    
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    vec3 f = vec3(5.);
    float va = 0.0;
    float wt = 0.0;
    for (int i=-1; i<=1; i++) 
    for (int j=-1; j<=1; j++) 
    {        
        vec2 o = vec2(i, j);               
        vec2 pp = fp +o  -hash2b(ip - o);
        float d = dot(pp, pp);
        if(d<f.x){f=f.zxy;f.x=d;}
        else if(d<f.y){f=f.xzy;f.y=d;}
        else if(d<f.z){f.z=d;}
    }    
    return (f.x+m.x*f.y-.5*m.y*min(f.z,1.))/2.;
}

float noise( vec2 p){
    
    
    if(windows ==0)return voronoi(p);
    if(windows ==1)return iqnoise3(p,m.x,m.y);
    if(windows ==2)return iqnoisep(p);//iqnoise4(p,m.x,m.y);
    //return 2.*gnoise(p*.5);
    return voronoise(p*.5)*.8;
}

float fbmabs( vec2 p ) {
    
    float f=1.;
   
    float r = 0.0;    
    for(int i = 0;i<8;i++){    
        r += abs(noise( p*f ))/f;       
        f *=2.;
        p-=vec2(-.01,.07)*r;
    }
    return r;
}

float fbm( vec2 p ) {
    
    float f=1.;
   
    float r = 0.0;    
    for(int i = 0;i<8;i++){    
        r += noise( p*f )/f;       
        f *=2.;
    }
    return r;
}

float map(vec2 p){

    //return noise(p*10.);
    //return 2.*abs( noise(p*10.));
    //return fbm(p)+1.;
    return 2.*fbmabs(p);
}

vec3 nor(in vec2 p)
{
    const vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(
        map(p + e.xy) - map(p - e.xy),
        map(p + e.yx) - map(p - e.yx),
        -.2));
}

    
void main(void){
    
    vec2 p = 2.*gl_FragCoord.xy /resolution.xy-1.;
    
    if(p.y>0.){
        if(p.x>0.)windows =1;
        else    windows =0;}
    else{
        if(p.x>0.)windows =3;
        else windows =2;}
    //windows =2;
    
    p += .5*time;
    
    //if(mouse.z>0.)m = mouse.xy/resolution.xy;
    
    
    float r;
    r = (noise(p*10.));
    vec3 light = normalize(vec3(4., 2., -1.));

    r = max(dot(nor(p), light),0.1);
    float k=map(p);
    glFragColor = clamp(vec4(r, r, r, 1.0),0.,1.);
    glFragColor = clamp(vec4(r*k*k, r*k, r, 1.0),0.,1.);
}
