#version 420

// original https://www.shadertoy.com/view/Ddt3z2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Experimenting with raymarching AO tonight

*/
#define EPS .001
#define MAX 300.

mat2 rotate(float r)
{
    return mat2(cos(r),-sin(r),sin(r),cos(r));
}
float dist(vec3 p)
{
    float d = 1e4;
    
    for(float i  = 1.0;i<4.0;i++)
    {
        float r = exp(i*0.5);
        p.xz *= mat2(-.6,-.8,.8,-.6);
        p.zy *= mat2(.6,-.8,.8,.6);
        vec3 m = mod(p+time*vec3(.1,0,0),r*2.)-r;
        d = min(d,length(max(abs(m)-r*.3,0.0)));
    }
    return d;
}
vec3 normal(vec3 p)
{
    vec2 e = vec2(2,-2)*EPS;
    return normalize(dist(p+e.xxy)*e.xxy+dist(p+e.xyx)*e.xyx+
    dist(p+e.yxx)*e.yxx+dist(p+e.y)*e.y);
}
float ao(vec3 p, vec3 n)
{
    float w = 0.0;
    float s = 1.0;
    for(float d = EPS*40.; d<2.; d*=2.)
    {
        s *= clamp(dist(p+n*d)/d*0.5+0.5, 0.0, 1.0);
        w++;
    }
    
    return pow(s,2.0/w);
}
vec3 color(vec3 p)
{
    vec3 n = normal(p);
    return vec3(ao(p,n));
}
vec4 march(vec3 p,vec3 r)
{
    vec4 m = vec4(p+r,1);
    for(int i = 0;i<200;i++)
    {
        float s = dist(m.xyz);
        m += vec4(r,1)*s;
        
        if (m.w>MAX) return m;
    }
    return m;
}
void main(void)
{
    vec3 r = normalize(vec3(gl_FragCoord.xy-.5*resolution.xy,resolution.y));
    r.yz *= rotate(0.3);
    r.xz *= rotate(time*0.1);
    
    vec4 m = march(vec3(0,0,0),r);
    vec3 c = color(m.xyz);
    c *= smoothstep(MAX,0.,m.w);
    
    glFragColor = vec4(c,1);
}
