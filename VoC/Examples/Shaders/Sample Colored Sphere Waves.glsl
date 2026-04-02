#version 420

// original https://www.shadertoy.com/view/sldBRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//MK2022 = Colored Sphere Waves =
//This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. 

#define MAX_STEPS 300
#define MAX_DIS 500.
#define MIN_DIS 20.

#define SURF_DIS .001
#define SURF_MUL 100.
#define SURF_EXP 2.

#define time time*.5

mat2 Rot(float a) 
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float Dist(vec3 p) 
{
    p.xy *= Rot(smoothstep(-.2,.2,sin(time/15.))*.785);
    p.xz *= Rot((smoothstep(-.8,.0,sin(time/12.))*2.-1.)*1.57+1.57);

    float f = 1./(300.+sin(time/11.)*120.-sin(time/9.)*80.+sin(time/7.)*50.);
    float dis = length(p)*f;
    
    p.xy *= Rot(p.z/MAX_DIS*(smoothstep(.2,1.,sin(time/13.)) - smoothstep(-.2,-1.,sin(time/13.)))*6.28);

    vec3 size = vec3(20.+sin(time/33.)*5.);
    p = mod(abs(-mod(p,4.*size)+2.*size),4.*size);    

    float d = length(p - sin(time*.5+dis*6.28)*size.x-size) - 
              (10.+sin(time/33.)*5.)*(sin(time*1.5+dis*6.28)*.5+.8)*
              (1.+.5*smoothstep(0.8,1.,sin(time/3.+dis/f/200.))); 

    return d;
}

vec3 RTM(vec3 ro, vec3 rd) 
{
    int steps;
    float sum = 0.;
    float s = 1.;
    float d = MIN_DIS;
    const float a = 1. / float(MAX_STEPS); 
    vec3 p = vec3(0.);
    
    for(int i = 0; i < MAX_STEPS; i++) 
    {    
        float sd = (SURF_DIS * (pow(d/MAX_DIS, SURF_EXP)*SURF_MUL+1.));
        if (s < sd || d > MAX_DIS) break;
        
        steps = i;
        p = ro + rd*d;
        s = Dist(p);
        s = max(abs(s), 2.*sd);
        d += s * 0.5;
        sum += a;
    }
    
    return vec3(smoothstep(0., 1., sum * (1.-exp(-d*d))), tanh(s/150.), float(steps) / float(MAX_STEPS));
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z)
{
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0.,1.,0.), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    vec3 ro = vec3( 0., 0., -80.);
    vec3 rd = R(uv, ro, vec3(0.), .3 + .8*smoothstep(.5,1.,sin(time/12.)));
    vec3 r = RTM(ro, rd);
    
    vec3 col = vec3(r.y*r.z+r.y+r.x*.1, r.z-r.x*.4+r.y*.4, r.x-r.y);
    col *= smoothstep(2.,-2./5., dot(uv,uv)); 
    vec3 colS = smoothstep(vec3(0.), vec3(1.), vec3(col));
    
    glFragColor = vec4(colS, 1.);
}
