#version 420

// original https://www.shadertoy.com/view/4tsGzB

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on Polyhedron again by Knighty :
// https://www.shadertoy.com/view/XlX3zB

#define PI    3.14159265359
#define PI2    ( PI * 2.0 )

float Type,cospin,scospin;
vec3 nc,ot;

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }

vec3 dmul( vec3 a, vec3 b )  {
    float r = length(a);
    
    b.xy=cmul(normalize(a.xy), b.xy);
    b.yz=cmul(normalize(a.yz), b.yz);
    b.xz=cmul(normalize(a.xz), b.xz);
    
    return r*b;
}

vec3 fold(vec3 pos) {
    for(int i=0;i<6 /*Type*/;i++){
        pos.xy=abs(pos.xy);//fold about xz and yz planes
        pos-=2.*min(0.,dot(pos,nc))*nc;//fold about nc plane
    }
    return pos;
}

//-------------------------------------------------
//From https://www.shadertoy.com/view/XtXGRS#
vec2 rotate(in vec2 p, in float t)
{
    return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

float map( vec3 p)
{
    float dr = 1.0;
    ot = vec3(1000.0);
    float r2;

    for( int i=0; i<4;i++ )
    {            
           r2 = dot(p,p);      
           if(r2>16.)continue;
                    
           p=1.5*fold(p);dr*=1.5;p=p.zxy-.5;
        dr=2.*sqrt(r2)*dr+1.;
        p=dmul(p,p)-.3;
        
        ot = min( ot, abs(p) );
                   
    }
    ot=ot/(.3+r2);
    return .3*length(p)*log(length(p))/dr;    
           
}

vec3 calcNormal(in vec3 p)
{
    const vec2 e = vec2(0.0001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)));
}

float march(in vec3 ro, in vec3 rd)
{
    const float maxd = 5.0;
    const float precis = 0.001;
    float h = precis * 2.0;
    float t = 0.0;
    float res = -1.0;
    for(int i = 0; i < 128; i++)
    {
        if(h < precis*t || t > maxd) break;
        h = map(ro + rd * t);
        t += h;
    }
    if(t < maxd) res = t;
    return res;
}

vec3 transform(in vec3 p)
{
    p.yz = rotate(p.yz, time * 0.2 + (resolution.y)*PI2/360.);
    p.zx = rotate(p.zx, time * 0.125 + (resolution.x)*PI2/360.);
    return p;
}

void main(void)
{
    Type=(fract(0.025*time)*3.5)+2.;//4.5;
    cospin=cos(PI/(Type));
    scospin=sqrt(0.75-cospin*cospin);
    nc=vec3(-0.5,-cospin,scospin);

    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = vec3(.3);
       vec3 rd = normalize(vec3(p, -1.8));
    vec3 ro = vec3(0.0, 0.0, 3.5);
    vec3 li = normalize(vec3(0.5, 0.8, 3.0));
    ro = transform(ro);
    rd = transform(rd);
    li = transform(li);
    float t = march(ro, rd);
    if(t > -0.001)
    {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);
        float dif = clamp(dot(nor, li), 0.0, 1.0);
        vec3 col1 =.5*(ot+ot.grb);
        col1.r+=.5*col1.g-.3*col1.b;
        nor = reflect(rd, nor);
        col1 += pow(max(dot(li, nor), 0.0), 25.0)*vec3(1.);
        col = .3+.6*mix( col, col1, t );
        col = col * dif;
        col = pow(col, vec3(0.5));
    }
    
       glFragColor = vec4(col, 1.0);
}
