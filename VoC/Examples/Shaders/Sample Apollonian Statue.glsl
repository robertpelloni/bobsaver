#version 420

// original https://www.shadertoy.com/view/ltjBRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define ROT (time*0.3)
#define ITERATION 4
//#define ITERATION 8
mat2 rot(float t)
{
    float c=cos(t);
    float s=sin(t);
    return mat2(c,-s,s,c);
}

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
        float k = 2./ r2;
        p *= k;
        scale *= k;
    }
    
    return 0.25*abs(p.y)/scale;
}

float box(vec3 p, vec3 b)
{
      vec3 d = abs(p) - b;
      return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 path(float p)
{
    return vec3(sin(p*0.16)*cos(p*0.1)*11., 0.,0.);
}

float map(vec3 p)
{
    p.xz*=rot(ROT);
    vec3 q=p;

    float d0=apollonian(p*0.5)*2.;;
    
   
    float d1=abs(p.y+0.2);
    float d3 = box(q+vec3(0.,-2.,0.), 1.12*vec3(2.,2.,1.0));
    float d = max(d0, d3);
    d=min(d,d1);
    return d;
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
    float res_t = 0.0;
    float res_d = 1000.0;
    float c, res_c;
    float max_error = 1000.0;
    float d = 1.0;
    float pd = 100.0;
    float os = 0.0;
    float step = 0.0;
    float error = 1000.0;
    
    for( int i=0; i<128; i++ )
    {
        if( error < pixel_size*0.5 || t > 100.0 )
        {
        }
        else{  // avoid broken shader on windows
        
            c = map(ro + rd*t);
            d = c;

            if(d > os)
            {
                os = 0.4 * d*d/pd;
                step = d + os;
                pd = d;
            }
            else
            {
                step =-os; os = 0.0; pd = 100.0; d = 1.0;
            }

            error = d / t;

            if(error < max_error) 
            {
                max_error = error;
                res_t = t;
                res_c = c;
            }
        
            t += step;
        }

    }
    if( t>100.0 ) res_t=-1.0;
    return res_t;
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

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
  
    vec3 lookat = vec3(0.0, 2., 0.);
    vec3 ro = lookat + vec3(0., 0., -3.5);
    ro += path(ro.z);
    
    vec3 forward=normalize(lookat-ro);
    vec3 right=normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up=normalize(cross(right, forward));
    
    vec3 rd=normalize(p.x*right + p.y*up + 2.*forward);
    
    float t=intersect(ro,rd);
    vec3 col=vec3(0.);
    if(t>-0.5)
    {
        vec3 pos=ro+t*rd;
        vec3 n=get_normal(pos);
        
        vec3 ld0=normalize(vec3(0., 1.0, -4.));
        
        float ao = pow(clamp(orb.w*2.0,0.0,1.0), 1.2);
        float c0=pow(clamp(orb.w, 0.0, 1.0), 2.);
        float c1=pow(clamp(orb.x, 0.0, 1.0), 2.);
        vec3 col0=c0*vec3(0.0,1.0,1.0);
        vec3 col1=vec3(1.);
        col1 = mix(col1, vec3(0.2,0.0,0.0), clamp(5.*orb.y,0.,1.));

        float amb=0.5+0.5*n.y;
        float diff=max(0.0, dot(n,ld0));
        float bac=max(0.0,dot(n,-ld0));
        float spec=max(0.0, pow(clamp(dot(ld0, reflect(rd, n)), 0.0, 1.0), 69.0));
        float sha=softshadow( pos+0.01*n, ld0, 0.0005, 28.0 );
        vec3 lin=vec3(0.0);
        
        lin+=vec3(0.3)*amb*ao;
        lin+=vec3(7.,4.,3.)*diff*1.0*ao*sha;
        lin+=vec3(1.0,0.8,0.3)*bac*1.0*ao;
        lin+=vec3(spec*7.2)*sha;
        
           col=(lin*col1-col0)*.2;
        col=mix(col,vec3(0.), 1.0-exp(-0.001*t*t)); 
        col *= min(2000.0*exp(-0.74*t),1.0);

     }
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col=pow(col,vec3(1.3,1.,1.));
    col*=pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1);
    glFragColor.xyz=col;
}
