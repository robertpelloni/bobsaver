#version 420

// original https://www.shadertoy.com/view/WlBSRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI    3.14159265359
#define PI2    PI * 2.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float smin(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec2 polarFold(vec2 p,float n)
{
    float h=floor(log2(n));
    float a =PI2*exp2(h)/n;
    for(int i=0;i<int(h)+2;i++)
    {
        vec2 v = vec2(-cos(a),sin(a));  
        p-=2.0*min(0.0,dot(p,v))*v;
        a*=0.5;
    }
    return p;
}

vec2 polarSmoothFold(vec2 p,float n)
{
    float h=floor(log2(n));
    float a =PI2*exp2(h)/n;
    for(int i=0; i<int(h)+2; i++)
    {
        vec2 v = vec2(-cos(a),sin(a));  
         p-=2.0*smin(0.0,dot(p,v),0.05)*v;
        a*=0.5;
    }
    return p;
}

float map(vec3 p)
{
    p.xy *= rot(time*0.5);
    p.yz *= rot(time*0.3);

    p.xy=polarSmoothFold(p.xy,16.);
    p.y -= 1.2;
    return length(p)-0.3;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec2 q = polarFold(uv,6.);
    q.y-=time*0.8;
    q.y=mod(q.y,0.4)-0.05;
    vec3 col = vec3(0.2,0.5,0.1);
    col = mix(col, vec3(0,0.15,0),step(0.0, q.x * q.y)); 
    col = mix(col, vec3(1,0.5,0)*0.7*dot(uv,uv), smoothstep(0.02, 0.0, abs(q.y)));
    col = mix(col, vec3(0,0.6,1)*0.8*length(uv), smoothstep(0.02, 0.0, abs(q.x)));
    
     vec3 ro = vec3(0,0,3);
    vec3 rd = normalize(vec3(uv,-2));
    float d, t = 0.0;
    for(float i = 1.0;i > 0.0;i -= 1.0/30.0)
    {
         t += d = map(ro+t*rd);
        if(d < 0.001)
        {
            col += i*i;
            break;
        }
    }
    glFragColor = vec4(col,1.0);
}
