#version 420

// original https://www.shadertoy.com/view/ttj3Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Gallardo - xjorma/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

//#define AA
//#define CUBE

float sinnoise(vec3 p,float t)
{
    
     for (int i=0; i<2; i++)
        p += cos( p.yzx*3. + vec3(t,1.6,1.6)) / 3.,
        p += sin( p.yzx + t + vec3(1.6,t,1.6)) / 2.,
        p *= 1.3;
    
    return sin(length(p));
}

float saturate(float c)
{
    return clamp(c,0.,1.);
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

vec2 minVecSelect(vec2 a, vec2 b)
{
    return a.x<b.x?a:b;
}

vec2 map(in vec3 p)
{
#ifndef CUBE
    float d = sdSphere(p,1.);
#else
    float d = sdBox(p,vec3(0.75));
#endif
    float n = sinnoise(p*2.,time/6.);
    float s = max(d,n/8.);
    return minVecSelect(vec2(s,n),vec2(p.y+1.1,0));
}

vec3 calcNormal(vec3 p)
{
    const float h = 0.02;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*map( p + k.xyy*h ).x + 
                      k.yyx*map( p + k.yyx*h ).x + 
                      k.yxy*map( p + k.yxy*h ).x + 
                      k.xxx*map( p + k.xxx*h ).x );
}

vec3 Render(vec3 ro,vec3 rd,vec3 cd,float dist)
{
    float t = 1.0;
    float d;
    float noise = 0.;
    for( int i=0; i<1024; i++ )
    {
        vec3    p = ro + t*rd;
        vec2    h = map(p);
        t += h.x*0.7;
        d = dot(t*rd,cd);
        noise = h.y;
        if( abs(h.x)<0.0001 || d>dist ) break;
    }

    vec3 col = vec3(0.5);

    if( d<dist )
    {
        vec3 light = vec3(0.,10.,2.);
        vec3 p = ro + t*rd;
        vec3 n = calcNormal(p);
        vec3 v = normalize(ro-p);
        vec3 l = normalize(light-p);
        vec3 h = normalize(l+v);
        
        vec3 diffcol = vec3(mix(saturate(pow(abs(sin(noise*16.))*1.5,15.)) ,1.,0.3)); 
        vec3 speccol = vec3(1.,1.,1.);
        vec3 ambcol = diffcol;
        
        col = saturate(dot(n,l)) * diffcol;
        col+= pow(saturate(dot(n,h)),20.) * speccol;
        col+= 0.2 * ambcol;
    }
    return col;
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 ro, in vec3 rd )
{
    glFragColor = vec4(Render(ro/3. + vec3(0.0,.0,4.0),rd ,rd,14.) ,1);
}

mat3 setCamera( in vec3 ro, in vec3 ta )
{
    vec3 cw = normalize(ta-ro);
    vec3 up = vec3(0, 1, 0);
    vec3 cu = normalize( cross(cw,up) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec3 tot = vec3(0.0);
        
#ifdef AA
    vec2 rook[4];
    rook[0] = vec2( 1./8., 3./8.);
    rook[1] = vec2( 3./8.,-1./8.);
    rook[2] = vec2(-1./8.,-3./8.);
    rook[3] = vec2(-3./8., 1./8.);
    for( int n=0; n<4; ++n )
    {
        // pixel coordinates
        vec2 o = rook[n];
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord+o))/resolution.y;
#else //AA
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif //AA
 
        // camera
        
        float theta    = radians(360.)*(mouse.x*resolution.xy.x/resolution.x-0.5) + time*.2;
        float phi    = radians(90.)*(mouse.y*resolution.xy.y/resolution.y-0.5)-1.;
        vec3 ro = 2.*vec3( sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta));
        //vec3 ro = vec3(0.0,.2,4.0);
        vec3 ta = vec3( 0 );
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta );
        //vec3 cd = ca[2];    
        
        vec3 rd =  ca*normalize(vec3(p,1.5));        
        
        vec3 col = Render(ro ,rd ,ca[2],12.);

        tot += col;
#ifdef AA
    }
    tot /= 4.;
#endif

    glFragColor = vec4( tot, 1.0 );
}
