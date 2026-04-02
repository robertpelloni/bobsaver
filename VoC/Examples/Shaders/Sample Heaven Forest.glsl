#version 420

// original https://www.shadertoy.com/view/ldK3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Lovera - Unix/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Shader used in SecretSociety Demo
// Originally from Xyptonjtroz by Dave Hoskins + nimitz (twitter: @stormoid)

#define ITR 100
#define FAR 80.
#define time time
#define MOD3 vec3(.16532,.17369,.15787)
#define SUN_COLOUR  vec3(1., .65, .35)
#define FOUR-D_NOISE    // ...Or this

 
float height(in vec2 p)
{
    float h = sin(p.x*.1+p.y*.2)+sin(p.y*.1-p.x*.2)*.5;
    h += sin(p.x*.04+p.y*.01+3.0)*4.;
    h -= sin(h*10.0)*.1;
    return h;
}

float camHeight(in vec2 p)
{
    float h = sin(p.x*.1+p.y*.2)+sin(p.y*.1-p.x*.2)*.5;
    h += sin(p.x*.04+p.y*.01+3.0)*4.;
    return h;
}

float box(vec3 p,vec3 s) {
    p = abs(p)-s;
    return max(max(p.x,p.y),p.z);
}

float smin( float a, float b)
{
    const float k = 2.7;
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

#define MOD2 vec2(.16632,.17369)
#define MOD3 vec3(.16532,.17369,.15787)

float tri(in float x){return abs(fract(x)-.5);}

float hash12(vec2 p)
{
    p  = fract(p * MOD2);
    p += dot(p.xy, p.yx+19.19);
    return fract(p.x * p.y);
}
float vine(vec3 p, in float c, in float h)
{
    p.y += sin(p.z*.1625+1.3)*8.5-.5;
    p.x += cos(p.z*.1575)*1.;
    vec2 q = vec2(mod(p.x, c)-c/2., p.y);
    return length(q) - h*1.4 -sin(p.z*3.+sin(p.x*7.)*0.5)*0.1;
}

vec4 quad(in vec4 p){return abs(fract(p.yzwx+p.wzxy)-.5);}

float Noise3d(in vec3 q)
{
    
    float z=1.4;
    vec4 p = vec4(q, time*.5);
    float rz = 0.;
    vec4 bp = p;
    for (float i=0.; i<= 2.; i++ )
    {
      vec4 dg = quad(bp);
        p += (dg);

        z *= 1.5;
        p *= 1.3;
        
        rz+= (tri(p.z+tri(p.w+tri(p.y+tri(p.x)))))/z;
        
        bp = bp.yxzw*2.0+.14;
    }
    return rz;
}

vec2 hash22(vec2 p)
{
    p  = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy +  vec2(21.5351, 14.3137));
    return fract(vec2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
}

float map(vec3 p)
{
    p.y += height(p.zx);    
    vec2 hs = hash22(floor(p.zx*20.));
    p.xz *=.42;
    p.zx = mod(p.zx,4.)-2.;        
    float d = (p.y)+0.5;    
    p.y -= hs.x*2.4+1.15;
    d = smin(d, vine(p.zyx+vec3(3.2+sin(time)*0.5,2.1,20.1+cos(time)*1.0),1.,0.5) );
    d= smin(d,box(p, vec3(0.1,8.4,.1)));

    return d*1.1;
}

float fogmap(in vec3 p, in float d)
{
    p.xz -= time*7.;
    p.y -= time*.5;
    return (max(Noise3d(p*.008+.1)-.1,0.0)*Noise3d(p*.1))*.3;
}

float march(in vec3 ro, in vec3 rd, out float drift, in vec2 scUV)
{
    float precis = 0.0001;
    float h=precis*2.0;
    float d = hash12(scUV);
    drift = 0.0;
    for( int i=0; i<ITR; i++ )
    {
        vec3 p = ro+rd*d;
        if(h < precis || d > FAR) break;
        h = map(p);
        drift +=  fogmap(p, d);
        d += min(h*.65 + d * .002, 8.0);
     }
    drift = min(drift*0.5, 1.0);
    return d;
}

vec3 normal( in vec3 pos, in float d )
{
    vec2 eps = vec2( d *d* .003+.01, 0.0);
    vec3 nor = vec3(
        map(pos+eps.xyy) - map(pos-eps.xyy),
        map(pos+eps.yxy) - map(pos-eps.yxy),
        map(pos+eps.yyx) - map(pos-eps.yyx) );
    return normalize(nor);
}

float bnoise(in vec3 p)
{
    p.xz*=.4;
    float n = Noise3d(p*3.)*0.8;
    n += Noise3d(p*1.5)*0.2;
    return n*n*.2;
}

vec3 bump(in vec3 p, in vec3 n, in float ds)
{
    p.xz *= .4;
    //p *= 1.0;
    vec2 e = vec2(.01,0.);
    float n0 = bnoise(p);
    vec3 d = vec3(bnoise(p+e.xyy)-n0, bnoise(p+e.yxy)-n0, bnoise(p+e.yyx)-n0)/e.x;
    n = normalize(n-d*10./(ds));
    return n;
}

float shadow(in vec3 ro, in vec3 rd, in float mint)
{
    float res = 1.0;
    
    float t = mint;
    for( int i=0; i<12; i++ )
    {
        float h = map(ro + rd*t);
        res = min( res, 4.*h/t );
        t += clamp( h, 0.1, 1.5 );
    }
    return clamp( res, 0., 1.0 );
}

vec3 Clouds(vec3 sky, vec3 rd)
{
    
    rd.y = max(rd.y, 0.0);
    float ele = rd.y;
    float v = (200.0)/rd.y;

    rd.y = v;
    rd.xz = rd.xz * v - time*8.0;
    rd.xz *= .00004;
    
    float f = Noise3d(rd.xzz*3.) * Noise3d(rd.zxx*1.3)*2.5;
    f = f*pow(ele, .5)*2.;
      f = clamp(f-.15, 0.01, 1.0);

    return  mix(sky, vec3(1),f );
}

vec3 Sky(vec3 rd, vec3 ligt)
{
    rd.y = max(rd.y, 0.0);    
    vec3 sky = mix(vec3(.1, .15, .25), vec3(.8), pow(.8-rd.y, 3.0));
    return  mix(sky, SUN_COLOUR, min(pow(max(dot(rd,ligt), 0.0), 4.5)*1.2, 1.0));
}

void main(void)
{    
    
    float fg;
    
    vec2 p = gl_FragCoord.xy/resolution.xy-0.5;
    vec2 q = gl_FragCoord.xy/resolution.xy;

    p.x*=resolution.x/resolution.y;
    vec2 mo = mouse*resolution.xy.xy / resolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(-1.9,0.07):mo;
    mo.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0.+smoothstep(0.,1.,tri(time*1.5)*.3)*1.1, smoothstep(0.,1.,tri(time*3.)*3.)*0.00, -time*3.5-130.0);
    ro.y -= camHeight(ro.zx)-.5;
    
    vec3 eyedir = normalize(vec3(cos(mo.x),mo.y*2.-.05,0.));
    vec3 rightdir = normalize(vec3(cos(mo.x+1.5708),0.,sin(mo.x+1.5708)));
    vec3 updir = normalize(cross(rightdir,eyedir));
    vec3 rd=normalize((p.x*rightdir+p.y*updir)*1.+eyedir);

    vec3 ligt = normalize( vec3(-1.5 +(time*10.0), (time/10.0), -.5) );
    float rz = march(ro,rd, fg, gl_FragCoord.xy);
    vec3 sky = Sky(rd, ligt);
    
    vec3 col = sky;
   
    if ( rz < FAR )
    {
        vec3 pos = ro+rz*rd;
        vec3 nor= normal( pos, rz);
        float d = distance(pos,ro);
        nor = bump(pos,nor,d);
        float shd = (shadow(pos,ligt,.01));
        
        float dif = clamp( dot( nor, ligt ), 0.0, 1.0 );
        vec3 ref = reflect(rd,nor);
        float spe = pow(clamp( dot( ref, ligt ), 0.0, 1.0 ),5.)*2.;
        col = vec3(.1);
        col = col*dif*shd + spe*shd*SUN_COLOUR +abs(nor.y)*vec3(.1, .1, .2);
        col = mix(col, sky, smoothstep(FAR-25.,FAR,rz));
    }
    else
    {
        col = Clouds(col, rd);
    }

    // Fog mix...
    col = mix(col, vec3(0.96, .8, .66), fg);
  
    // Post...
    col = min(pow(col*1.,vec3(0.7)), 1.0);
    col = smoothstep(0., 1., col);
    
    // Borders...
    float f = smoothstep(0.0, 3.0, time)*.5;
    col *= f+f*pow(70. *q.x*q.y*(1.0-q.x)*(1.0-q.y), .2);
        
    glFragColor = vec4( col, 1.0 );
}
 
