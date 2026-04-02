#version 420

// original https://www.shadertoy.com/view/wdS3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Gallardo - xjorma/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

//#define AA

float hyperbolaV(float v)
{
    return -2./v;
}

float hyperbolaD(float v)
{
    return 2./(v*v);    
}

float hyperbolaDist(vec2 pos)   // Using Newton approximation
{
    float    curX = pos.x;
    for(int i=0; i<10 ; ++i)
    {
        vec2    p = vec2(curX,hyperbolaV(curX));
        vec2    d = normalize(vec2(curX,hyperbolaD(curX)));
        float    proj = dot(d,(pos-p))*d.x;
        curX += proj;
        if(abs(proj) < 0.002) break;
    }
    vec2    p = vec2(curX,hyperbolaV(curX));
    float    s = sign(pos.y - p.y);   
    return  s*length(pos - p);
}

float map(in vec3 pos)
{
    float hd = length(pos.xz);
    
    float wave = sin(hd*10.+time*7.+atan(pos.z,pos.x)*6.)*0.06;

    float dist = hyperbolaDist(vec2(hd,pos.y));

    return min(dist+wave,10.);
}

vec3 calcNormal(vec3 pos)
{
    vec2    eps    = vec2(0.01,0);
    float    d    = map(pos);
    return    normalize(vec3(map(pos+eps.xyy)-d,map(pos+eps.yxy)-d,map(pos+eps.yyx)-d));
}

vec3 applyFog(vec3 rgb,float distance, vec3 fogColor)
{
    float fogAmount = 1.0 - exp( -distance*0.2 );
    return mix( rgb, fogColor, fogAmount );
}

mat3 setCamera( in vec3 ro, in vec3 ta )
{
    vec3 cw = normalize(ta-ro);
    vec3 up = vec3(0, 1, 0);
    vec3 cu = normalize( cross(cw,up) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 Render(vec3 ro,vec3 rd,vec3 cd,float dist)
{
    float t = 1.0;
    float d;
    for( int i=0; i<64; i++ )
    {
        vec3    p = ro + t*rd;
        float    h = map(p);
        t += h*0.7;
        d = dot(t*rd,cd);
        if( abs(h)<0.001 || d>dist ) break;
    }

    vec3 col = vec3(0.0);

    if( d<dist )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
        vec3 reflected=reflect(rd,nor);
        vec3 env = vec3(0.0);//texture(iChannel0,reflected).xyz;
        col = vec3(nor.y)*vec3(1,0.1,0.1)+env*0.1;
        col = applyFog(col,d,vec3(0));
    }
    return col;
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 ro, in vec3 rd )
{
    glFragColor = vec4(Render(ro/3. + vec3(0.0,.0,4.0),rd ,rd,14.) ,1);
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
        vec3 ro = 4.*vec3( sin(0.01*resolution.x), 0.2 , cos(0.01*resolution.x) );
        //vec3 ro = vec3(0.0,.2,4.0);
        vec3 ta = vec3( 0 );
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta );
        //vec3 cd = ca[2];    
        
        vec3 rd =  ca*normalize(vec3(p,1.0));        
        
        vec3 col = Render(ro ,rd ,ca[2],12.);

        tot += col;
#ifdef AA
    }
    tot /= 4.;
#endif

    glFragColor = vec4( tot, 1.0 );
}
