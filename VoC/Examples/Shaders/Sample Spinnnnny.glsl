#version 420

// original https://www.shadertoy.com/view/43B3RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define halfsqrt3 0.86602540
#define invsqrt3 0.57735026
#define tau 6.28318530
#define pi 3.14159265358979323846264338327950

float hash1D(vec2 x)
{
    // hash by Inigo Quilez, Integer Hash - III, 2017
    uvec2 q = uvec2(x * 65536.0);
    q = 1103515245u * ((q >> 1u) ^ q.yx);
    uint n = 1103515245u * (q.x ^ (q.y >> 3u));
    return float(n) * (1.0 / float(0xffffffffu));
}

vec2 hash2D(vec2 x)
{
    // based on: Inigo Quilez, Integer Hash - III, 2017
    uvec4 q = uvec2(x * 65536.0).xyyx + uvec2(0u, 3115245u).xxyy;
    q = 1103515245u * ((q >> 1u) ^ q.yxwz);
    uvec2 n = 1103515245u * (q.xz ^ (q.yw >> 3u));
    return vec2(n) * (1.0 / float(0xffffffffu));
}

float hash(vec2 x, float time)
{
    return 0.5+0.5*sin(tau*hash1D(x)+time);
}

//value noise on a triangular lattice
float tri_noise(vec2 p, float time)
{
    vec2 q = vec2(p.x-p.y*invsqrt3, p.y*2.0*invsqrt3);
    vec2 iq = floor(q);
    vec2 fq = fract(q);
    float v = 0.0;
    
    float h = step(1.0, fq.x+fq.y); //which half of the unit cell does this triangle lie in
    vec2 c = iq+h;
    vec2 r = p-vec2(c.x+0.5*c.y, halfsqrt3*c.y);
    float s = 1.0-2.0*h;
    r *= s;
    
    //compute barycentric coordinates
    vec3 lambda = vec3(1.0-r.x-invsqrt3*r.y, r.x-invsqrt3*r.y, 2.0*invsqrt3*r.y);
    //quintic////////////////////
    vec3 lambda2 = lambda*lambda;
    vec3 a = 15.0*lambda2*lambda2.zxy*lambda.yzx;
    
    //weights set to be quintic smoothstep along edges, with extra terms to set gradients in the normal direction to 0
    //these magically add up to 1 without correction
    vec3 w = lambda*lambda2*(10.0-15.0*lambda+6.0*lambda2)+a+a.yzx;
        
    v += w.x*hash(abs(c), time);
    v += w.y*hash(abs(iq+vec2(1.0-h,h)), time);
    v += w.z*hash(abs(iq+vec2(h,1.0-h)), time);
    
    return v;
}

float fbm(vec2 p, int octaves, float decay, float time)
{
    vec2 fwp = fwidth(p);
    float w = dot(step(fwp.xy, fwp.yx), fwp);
    vec2 v = vec2(0.0);
    float weight = 1.0;
    for(int i = 0; i < octaves; i++)
    {
        //time = mod(time, tau);
        v += weight*vec2(tri_noise(p, time)*smoothstep(1.0,0.5,w), 1.0);
        p *= 2.0*mat2(4.0/5.0, -3.0/5.0, 3.0/5.0, 4.0/5.0);
        w *= 2.0;
        weight *= decay;        
        //time += 0.5*time;
        time *= 1.6;
    }
    return v.x/v.y;
}

float fcos(float x)
{
    float w = fwidth(x);
    return cos(x)*sin(0.5*w)/(0.5*w);
    //return cos(x)*smoothstep(2.0*pi, 0.0, w);
}

float get_val(vec2 p)
{
    float l = length(p);
    float wavf = 0.02;
    float w = fbm(5.0*p+vec2(7.0), 3, 0.6, 0.01*time);
    
    float angle = 0.12*time-1.0/wavf*0.005*fcos(100.0*l+wavf*time)-2.5*log(l+0.01)-0.5*w;
    vec2 cs = vec2(cos(angle), sin(angle));
    p = vec2(p.x*cs.x-p.y*cs.y, p.x*cs.y+p.y*cs.x);
    
    vec2 up = 5.0*p+vec2(7.0);
    float u = fbm(up, 6, 0.6, 0.01*time)-0.5;
    u = fcos(10.0*u);
    vec2 vp = 2.0*u+vec2(1.0);
    float v = fbm(vp, 3, 0.3, 10.0+0.1*time);
    
    //v = cos(10.0*v);
    v += 20.0*l*smoothstep(0.0, 0.02, l);
    return v;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec2 p = 0.1*uv;
    float l = length(p);
    float v = get_val(p);
    
    glFragColor = mix(vec4(0.3,0.55,1.0,1.0), 
                    vec4(0.8,0.22,0.3,1.0),
                    smoothstep(1.0, 1.3, v));
    
    //vec3 grad = normalize(vec3(2.0*du*(vxyz.y+vxyz.z)+2.0*normalize(uv)*dFdx(uv.x), dFdx(uv.x)));
    vec2 e = vec2(2.0*dFdx(p.x),0.0);
    vec3 grad = normalize(0.5*vec3((get_val(p+e.xy)-get_val(p-e.xy)), 0.5*(get_val(p+e.yx)-get_val(p-e.yx)), 10.0*e.x));
    //grad = normalize(vec3(dFdx(v), dFdy(v), dFdx(uv.x)));
    glFragColor.rgb += vec3(0.5)*pow(clamp(dot(grad, normalize(vec3(1.0, 1.0, 1.0))), 0.0, 1.0), 10.0);
    glFragColor.rgb += vec3(0.25,0.0,0.0)*pow(clamp(dot(grad, normalize(vec3(-1.0, 1.0, 1.0))), 0.0, 1.0), 10.0);
    glFragColor.rgb *= smoothstep(-1.0,0.0, 1.0-v+13.0*l-0.7);
    glFragColor.rgb *= smoothstep(-0.1,0.4, abs(v-1.0));
}
