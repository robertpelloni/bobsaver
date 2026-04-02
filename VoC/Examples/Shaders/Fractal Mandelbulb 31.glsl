#version 420

// original https://www.shadertoy.com/view/tdy3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 20.0
float g;
float bulb(vec3 p)
{
    
    vec3 z = p;
    
    {
        const float exBR = 1.5;
        float r = length(p)-exBR;
        if(r>1.0){return r;}
    }
    
    float dr =1., r=0., pw = 8., fr=.0, theta, phi, zr;
    for(int i=0;i<10;i++)
    {
        
        r=length(z);
        if(r>2.)
        {
            fr = min(0.5*log(r)*r/dr, length(p)-.72);
            break;
        }
        theta=acos(z.z/r)+time/10.;
        phi = atan(z.y,z.x);
        dr = pow(r,7.)*7.*dr+1.;
        
        zr = pow(r,pw);
        theta = theta*pw;
        phi = phi*pw;
        
        z=zr*vec3(sin(theta)*cos(phi),
                  sin(phi)*sin(theta),
                  cos(theta))+p;
    }
    
    return fr;
    
}

float map(vec3 p)
{
    float s = bulb(p);
    
    g+=0.1/(0.1+s*s);
    
    return s;
}

float ray(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0;i<100;i++)
    {
        
        vec3 p = ro+rd*t;
        float s = map(p);

        if(s<0.00001)break;
        t+=s;
        if(t>MAX_DIST)break;
        
    }
    if(t>MAX_DIST)t=-1.;
    
    return t;
}

vec3 normal(vec3 p)
{
    vec2 e= vec2(0.005,0.);
    return normalize(vec3(
        map(p+e.xyy)-map(p-e.xyy),
        map(p+e.yxy)-map(p-e.yxy),
        map(p+e.yyx)-map(p-e.yyx)
        ));
}

vec3 color(vec3 ro, vec3 rd, float r)
{
    vec3 c = vec3(0.);
    vec3 cs = 0.5 + 0.5*cos(time+rd.xyx+vec3(0,2,4));
    
    if(r>0.)
    {
        vec3 p = ro+rd*r;
        vec3 n = normal(p);
        vec3 sun = normalize(vec3(0.2,0.5,0.3));
        float dif = clamp(dot(sun,n),0.0,1.0);
        float sky = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.,1.);
        
        c=vec3(r)*-.1;
        c+=cs*r*dif;
        c+=r*sky*vec3(0.9,0.5,0.5);
        
    }
    
    
    return c+(g/75.*cs);
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;

    vec2 uv = (2.*f-resolution.xy)/resolution.y;

    
    float d = 1.2, t=3.1415927/2.;
    vec3 ro = vec3(cos(t)*d,0,sin(t)*d);
    
    vec3 ta = vec3(0);
    
    vec3 cf = normalize(ta-ro);
    vec3 cu = normalize(cross(cf,vec3(0,1,0)));
    vec3 cr = normalize(cross(cf,cu));
    
    float dst =( min((1.+cos(time/5.))/2.+.1,1.)*.5)/2.+.3;
    vec3 rd = normalize(uv.x*cu+uv.y*cr+dst*cf);
    
    float r = ray(ro,rd);

    glFragColor = vec4(color(ro,rd,r),1.0);
}
