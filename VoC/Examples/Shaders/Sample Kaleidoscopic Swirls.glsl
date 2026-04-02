#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dtSzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time .5*time
float hash(in vec3 p)
{
    ivec3 q = ivec3(p*5000.);
    int h = 15*q.x ^ q.y ^ q.z;
    return fract(713.*sin(float(h)));
}

float noise(in vec3 p)
{
    vec3 F = floor(p);
    vec2 o = vec2(0,1);
    vec3 f = smoothstep(0.,1.,fract(p));
    float r1 = mix(hash(F), hash(F+o.yxx), f.x);
    r1 = mix(r1,mix(hash(F+o.xyx),hash(F+o.yyx), f.x),f.y);
    float r2 = mix(hash(F+o.xxy), hash(F+o.yxy), f.x);
    r2 = mix(r2,mix(hash(F+o.xyy),hash(F+o.yyy), f.x),f.y);
    return mix(r1,r2,f.z);
}

float fbm(in vec3 p)
{
    float s = 1.;
    float a = 1.;
    float g = 2.;
    float A = 0.;
    float r = 0.;
    for(int i = 0; i<3; i++){
        r += a*noise(1.2*float(i)+p*s);
        A += a;
        a /= g;
        s *= g;
    }
    return r/A;
}

vec3 fbm3(in vec3 p)
{
    return vec3(fbm(p-10.3),fbm(p),fbm(p+10.3));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    
    vec3 col = vec3(0);
    float t = time*.1;
    
    t *= (.5+.5*smoothstep(.0,1.,length(uv)));
    
    mat2 rot = mat2(cos(t),sin(t),-sin(t),cos(t));
    
    uv *=rot;
    
    vec2 rad = vec2(atan((uv.y/uv.x)), length(uv));
    
    int rf = int(abs(floor(6.*rad.x/3.16)));
    rad.x = fract(6.*rad.x/3.16);
    if(rf%2==0) rad.x = 1.-rad.x; 
    rad.x *= 3.16/6.;
    
    vec3 p =  vec3(rad.x,16.*rad.y-1.5*time,.5*time);
    
    t = -time*.001;
    mat2 rot2 = mat2(cos(t),sin(t),-sin(t),cos(t));
    
    p.xy *= rot2;
    
    vec3 q = fbm3(vec3(p.xy,p.z));
    vec3 r = .5*fbm3(2.*(p+q));
    vec3 s = .2*fbm3(8.*(p+q+r));
    
    col += pow(fbm3(p+s)*fbm(r+.3*s)*3.5,vec3(.8,1.5,1.2));
    
    col *= fbm(p)*1.5;
    
    //col *= pow(fbm(p+s)*1.5,2.2);
    
    col *= 1.+smoothstep(.05,.0,rad.y);
    
    float vig = smoothstep(1.,.2,rad.y);
    col = pow(col, vec3(vig));
    col *= vig;
    
    glFragColor = vec4(col,1.0);
}
