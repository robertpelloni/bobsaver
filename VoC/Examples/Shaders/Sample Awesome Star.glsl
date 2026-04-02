#version 420

// original https://www.shadertoy.com/view/4lfSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// procedural noise from https://www.shadertoy.com/view/4sfGzS
//
/*float hash( float n ) { return fract(sin(n)*753.5453123); }
float noise( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}*/

// animated noise
vec4 NC0=vec4(0.0,157.0,113.0,270.0);
vec4 NC1=vec4(1.0,158.0,114.0,271.0);

//vec4 hash4(vec4 x){ return fract(fract(x*0.31830988618379067153776752674503)*fract(x*0.15915494309189533576888376337251)*265871.1723); }
vec4 hash4( vec4 n ) { return fract(sin(n)*753.5453123); }
float noise3( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + dot(p.yz,vec2(157.0,113.0));
    vec4 s1=mix(hash4(vec4(n)+NC0),hash4(vec4(n)+NC1),vec4(f.x));
    return mix(mix(s1.x,s1.y,f.y),mix(s1.z,s1.w,f.y),f.z);
}

float noise4( vec4 x )
{
    vec4 p = floor(x);
    vec4 f = fract(x);
    p.w=mod(p.w,100.0);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + dot(p.yzw,vec3(157.0,113.0,642.0));
    vec4 vs1=mix(hash4(vec4(n)+NC0),hash4(vec4(n)+NC1),vec4(f.x));
    float s1=mix(mix(vs1.x,vs1.y,f.y),mix(vs1.z,vs1.w,f.y),f.z);
    n = n-642.0*p.w + 642.0*mod(p.w+1.0,100.0);
    vs1=mix(hash4(vec4(n)+NC0),hash4(vec4(n)+NC1),vec4(f.x));
    float s2=mix(mix(vs1.x,vs1.y,f.y),mix(vs1.z,vs1.w,f.y),f.z);
    return mix(s1,s2,f.w);
}

float noise4r( vec4 x )
{
    vec4 ws=vec4(0.25,2.25,10.25,1.25);
    return (noise4(x)+noise4(x+=ws)+noise4(x+=ws)+noise4(x+=ws))*0.25;
}

float noiseSpere(vec3 ray,vec3 pos,float r,vec3 rotate,vec3 subnoise,float anim)
{
      float b = dot(ray,pos);
      float c = dot(pos,pos) - b*b;
    
    vec2 sins=sin(rotate.xy);
    vec2 coss=cos(rotate.xy);
    vec3 r1=vec3(0.0);
    
    float s=0.0;
    float d=0.03125;
    float d2=rotate.z/(d*d);
    
    for (int i=0;i<3;i++) {
        float rq=r*r;
        if(c <rq)
        {
            float l1=sqrt(r-c);
            r1= ray*(b-l1)-pos;
            r1.yz=vec2(r1.y*coss.y+r1.z*sins.y,r1.z*coss.y-r1.y*sins.y);
            r1.xz=vec2(r1.x*coss.x+r1.z*sins.x,r1.z*coss.x-r1.x*sins.x);
            s+=abs(noise4r(vec4(r1*d2+subnoise,anim))*d);
        }
        d*=4.0;
        d2*=0.0625;
        r=r-r*0.02;
    }
    return s;
}

float ring(vec3 ray,vec3 pos,float r,float size)
{
      float b = dot(ray,pos);
      float c = dot(pos,pos) - b*b;
   
    float s=max(0.0,(1.0-size*abs(r-sqrt(c))));
    
    return s;
}

float ringRayNoise(vec3 ray,vec3 pos,float r,float size,vec2 rotate,float anim)
{
      float b = dot(ray,pos);
    vec3 pr=ray*b-pos;
    
    vec2 sins=sin(rotate.xy);
    vec2 coss=cos(rotate.xy);
    
    float c=length(pr);

    pr.yz=vec2(pr.y*coss.y+pr.z*sins.y,pr.z*coss.y-pr.y*sins.y);
    pr.xz=vec2(pr.x*coss.x+pr.z*sins.x,pr.z*coss.x-pr.x*sins.x);
    
    pr=normalize(pr)*(1.0+c*0.6);
    
    float s=max(0.0,(1.0-size*abs(r-c)));
    
    float nd=noise4r(vec4(pr*1.0,anim))*2.0;
    nd=pow(nd,2.0);
    float n=noise4r(vec4(pr*10.0,anim));
    pr=normalize(pr)*(1.0+c*0.1);
    float ns=noise4r(vec4(pr*50.0,anim))*2.0;
    n=n*n*nd*ns;
    
    return pow(s,4.0)+s*s*n;
}

float noiseSpace(vec3 ray,vec3 pos,float r,vec3 rotate,vec3 subnoise,float anim)
{
      float b = dot(ray,pos);
      float c = dot(pos,pos) - b*b;
    
    vec2 sins=sin(rotate.xy);
    vec2 coss=cos(rotate.xy);
    vec3 r1=vec3(0.0);
    
    float s=0.0;
    float d=0.0625*1.5;
    float d2=rotate.z/d;
    
    for (int i=0;i<3;i++) {
        float rq=r*r;
        float l1=sqrt(abs(r-c));
        r1= ray*(b-l1)-pos;
        r1.yz=vec2(r1.y*coss.y+r1.z*sins.y,r1.z*coss.y-r1.y*sins.y);
        r1.xz=vec2(r1.x*coss.x+r1.z*sins.x,r1.z*coss.x-r1.x*sins.x);
        s+=abs(noise4r(vec4(r1*d2+subnoise,anim))*d);
        d*=2.0;
        d2*=0.5;
        r=r-r*0.02;
    }
    return s;
}

float sphereZero(vec3 ray,vec3 pos,float r)
{
      float b = dot(ray,pos);
      float c = dot(pos,pos) - b*b;
    float s=1.0;
    if (c<r*r) s=0.0;
    return s;
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;

    float mx = 0.5;
    float my = 0.0;

    float time=time*1.0;
    
    vec3 ray = normalize(vec3(p,2.0));
    vec3 pos = vec3(0.0,0.0,3.0);
    
    float s1=noiseSpere(ray,pos,1.0,vec3(mx,my,0.5),vec3(0.0),time);
    s1=pow(min(1.0,s1*2.4),2.0);
    float s2=noiseSpere(ray,pos,1.0,vec3(mx,my,4.0),vec3(83.23,34.34,67.453),time);
    s2=min(1.0,s2*2.2);
    glFragColor = vec4( mix(vec3(1.0,1.0,0.0),vec3(1.0),pow(s1,60.0))*s1, 1.0 );
    glFragColor += vec4( mix(mix(vec3(1.0,0.0,0.0),vec3(1.0,0.0,1.0),pow(s2,2.0)),vec3(1.0),pow(s2,10.0))*s2, 1.0 );
    
    glFragColor.xyz -= vec3(ring(ray,pos,1.03,11.0))*2.0;
    glFragColor = max( vec4(0.0), glFragColor );
    
    float s3=ringRayNoise(ray,pos,0.96,2.0,vec2(mx,my),time);
    glFragColor.xyz += mix(vec3(1.0,0.6,0.1),vec3(1.0,0.95,1.0),pow(s3,3.0))*s3;
    
    float s4=noiseSpace(ray,pos,100.0,vec3(mx,my,0.5),vec3(0.0),time*0.01);
    //float s5=noiseSpace(ray,pos,100.0,vec3(mx,my,0.5),vec3(83.23,34.34,67.453),time*0.01);
    s4=pow(s4*2.0,6.0);
    //s5=pow(s5*2.0,6.0);
    //glFragColor.xyz += (vec3(0.0,0.0,1.0)*s4*0.6+vec3(0.9,0.0,1.0)*s5*0.3)*sphereZero(ray,pos,0.9);
    glFragColor.xyz += (mix(mix(vec3(1.0,0.0,0.0),vec3(0.0,0.0,1.0),s4*3.0),vec3(1.0),pow(s4*2.0,4.0))*s4*0.6)*sphereZero(ray,pos,0.9);
    
    //glFragColor = max( vec4(0.0), glFragColor );
    //s+=noiseSpere(ray,vec3(0.0,0.0,3.0),0.96,vec2(mx+1.4,my),vec3(83.23,34.34,67.453));
    //s+=noiseSpere(ray,vec3(0.0,0.0,3.0),0.90,vec2(mx,my),vec3(123.223311,956.34,7.45333))*0.6;
    
    glFragColor = max( vec4(0.0), glFragColor );
    glFragColor = min( vec4(1.0), glFragColor );
}
