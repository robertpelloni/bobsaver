#version 420

// original https://www.shadertoy.com/view/MlSBzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by evilryu
// Somewhat modified by Matthew Arcus, 2017.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define ITERATION 8
#define PI 3.141592654
vec4 orb;
float apollonian(vec3 p)
{
       float scale = 1.0;
    orb = vec4(1000.0); 
    
    for( int i=0; i < ITERATION;i++ )
    {
        p = -1.0 + 2.0*fract(0.5*p+0.5);
        float r2 = dot(p,p);
        orb = min( orb, vec4(abs(p),r2) );
        //float k = 1.2/ r2;
        float k = (1.0 + 0.2*cos(0.123*time))/r2;
        p *= k;
        scale *= k;
    }
    
        // Uncomment this for another fun variation
        //return 0.25*abs(p.y)/scale;
        return 0.25*min(abs(p.z)+abs(p.x), min(abs(p.x)+abs(p.y),abs(p.y)+abs(p.z)))/scale;
}

float box(vec3 p, vec3 b)
{
      vec3 d = abs(p) - b;
      return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float map(vec3 p)
{
  float scale = 5.0;
    vec3 q=p;
    p /= scale;
    float s = dot(p,p);
    p /= s;
    p += vec3(1.0);
    p.y += 0.1*time;
    
    float d0=apollonian(p)*scale;
    //float d1=abs(p.y-0.02);
    float d3 = box(q+vec3(0.,-2.,0.), 2.9*vec3(3.,2.,2.3));
    float d = max(d0, d3);
    //d=min(d,d1);
    return d*s;
}

vec3 get_normal(vec3 p) {
    const vec2 e = vec2(0.002, 0);
    return normalize(vec3(map(p + e.xyy)-map(p - e.xyy), 
                          map(p + e.yxy)-map(p - e.yxy),    
                          map(p + e.yyx)-map(p - e.yyx)));
}

float intersect( in vec3 ro, in vec3 rd )
{
    float pixel_size = 1.0/(resolution.y * 2.0);

    float t = 1.0;
    for( int i=0; i<128; i++ )
    {
        float c = map(ro + rd*t);
        if( c<0.5*pixel_size*t ) break;
        t += c;
        if( t>100.0 ) return -1.0;
    }
    return t;
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    float h = 1.0;
    for( int i=0; i<128; i++ )
    {
        h = map(ro + rd*t);
        res = min( res, k*h/t );
        if( res<0.0001 ) break;
        t += clamp( h, 0.01, 0.05 );
    }
    return clamp(res,0.0,1.0);
}

vec3 tonemap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec2 rotate(in vec2 p, in float t) {
  return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 transform(in vec3 p) {
  //if (mouse*resolution.xy.x > 0.0) {
  //  float theta = -(2.0*mouse*resolution.xy.y-resolution.y)/resolution.y*PI;
  //  float phi = -(2.0*mouse*resolution.xy.x-resolution.x)/resolution.y*PI;
  //  p.yz = rotate(p.yz,phi);
  //  p.zx = rotate(p.zx,phi);
  //}
  //p.yz = rotate(p.yz,0.1*time * 0.125);
  p.zx = rotate(p.zx,0.1*time);
  return p;
}

void main(void)
{
    vec3 ld0=normalize(vec3(-12., 2.0, -7.));
        
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
  
    //vec3 lookat = vec3(0.0, 1.5, 0.);
    vec3 lookat = vec3(0);
    vec3 ro = 1.4*vec3(-1., 1.5,-4.5);
    //if (mouse*resolution.xy.y > 0.0) {
    //  ro *= 2.0*mouse*resolution.xy.y/resolution.y;
    //}
    vec3 forward=normalize(lookat-ro);
    vec3 right=normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up=normalize(cross(right, forward));
    
    vec3 rd=normalize(p.x*right + p.y*up + 2.*forward);
    
    ro = transform(ro);
    rd = transform(rd);
    ld0 = transform(ld0);

    float t=intersect(ro,rd);
    vec3 col=vec3(0.);
    if(t>-0.5)
    {
        vec3 pos=ro+t*rd;
        vec3 n=get_normal(pos);
        
        float ao = pow(clamp(orb.w*2.0,0.0,1.0), 1.2);
        float c0=pow(clamp(orb.w, 0.0, 1.0), 2.);
        float c1=pow(clamp(orb.x, 0.0, 1.0), 2.);
        vec3 col0=c0*vec3(0.0,1.0,1.0);
        vec3 col1=vec3(1.);
        col1 = mix(col1, vec3(0.4,0.0,0.0), clamp(3.5*orb.y,0.,1.));

        float amb=0.5+0.5*n.y;
        float diff=max(0.0, dot(n,ld0));
        float bac=max(0.0,dot(n,-ld0));
        float bac2=max(0.0, dot(n, -vec3(0.,1.,0.)));
        float spec=max(0.0, pow(clamp(dot(ld0, reflect(rd, n)), 0.0, 1.0), 64.0));
        float sha=1.0; //softshadow( pos+0.01*n, ld0, 0.005, 32.0 );
        vec3 lin=vec3(0.0);
        
        lin+=vec3(0.5)*amb*ao;
        lin+=vec3(5.,5.,3.)*diff*1.0*ao*sha;
        lin+=vec3(1.0,0.8,0.3)*bac*1.0*ao;
        lin+=vec3(1.,0.8,0.3)*bac2*ao;
        lin+=vec3(spec*6.2)*sha;
        
           col=(lin*col1-col0)*.2;
        col=mix(col,vec3(0.), 1.0-exp(-0.001*t*t)); 
        col *= min(2000.0*exp(-0.74*t),1.0);

     }
    col=tonemap(col);
    //col=pow(col,vec3(1.3,1.,1.));
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col*=pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1);
    glFragColor.xyz=col;
}
